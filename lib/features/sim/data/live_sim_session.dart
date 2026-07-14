/// The live sim pipeline behind the [SimSession] interface: mic capture
/// to the broker, streamed persona TTS with buffered playback, and the
/// transcript / coaching / envelope streams the scripted session
/// already feeds the screens. Swapping this in for ScriptedSimSession is
/// a factory change, never a screen rewrite (Session 11 contract).
///
/// Barge-in ready (broker PROTOCOL.md): the mic streams for the whole
/// call, including while the persona speaks, so STT never stops and an
/// interruption is possible at any moment. Playback is interruptible
/// (stop, send `cancel`, rest the avatar); the local trigger that fires
/// it sits behind the broker's `interruptTriggerEnabled` flag
/// (conservative launch: off), while an unprompted server `interrupted`
/// is always honored. Nothing here is turn-locked.
///
/// Avatar wiring stays lifecycle-clean: this session owns the
/// VisemeScheduler (pure Dart) and only EMITS mouth-group values on
/// [visemeGroups]; the Rive controller is owned by the presentation
/// widget that subscribes. So the session has no Flutter/Rive imports
/// and unit-tests without them.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../../core/services/viseme_scheduler.dart' as vs;
import '../../scoring/domain/session_doc.dart';
import '../domain/sim_session.dart';
import 'broker_connection.dart';
import 'broker_protocol.dart';
import 'mic_source.dart';
import 'tts_player.dart';

/// Streams mapped mouth-group values (0..7, see MouthGroup) for a
/// presentation widget to feed its own Rive controller. Kept off the
/// base [SimSession] so the scripted path stays unaffected.
abstract interface class VisemeStreaming {
  Stream<int> get visemeGroups;
}

/// A session that can end on the SERVER's initiative (time cap), not
/// only via a client [SimSession.end] call. [ended] resolves with the
/// scored result whichever way the call ends.
abstract interface class ServerEndableSession {
  Future<SimResult> get ended;
}

/// Thrown from [LiveSimSession.start] when the call cannot begin
/// (mic denied, socket refused, hello rejected). The controller treats
/// it as a start failure; the refund + honest-copy polish is Session 16.
class SimStartException implements Exception {
  const SimStartException(this.reason, [this.message]);

  /// Abort-vocabulary reason: 'mic_failure' | 'launch_failure'.
  final String reason;
  final String? message;

  @override
  String toString() => 'SimStartException($reason): ${message ?? ''}';
}

/// Local client VAD tuning. Deliberately conservative so only a clear
/// sustained utterance fires a barge-in, never a backchannel ("mm-hm").
/// Mirrors the broker's INTERRUPT_MIN_MS. Dormant unless the broker's
/// interrupt trigger flag is on.
const double _kVadLevelThreshold = 0.38;
const int _kVadSustainMs = 700;

const Duration _kEnvelopeTick = Duration(milliseconds: 120);
const Duration _kReadyTimeout = Duration(seconds: 15);

const Map<String, String> _kCategoryLabels = {
  'objections': 'Objections',
  'discovery': 'Discovery',
  'closing': 'Closing',
  'rapport': 'Rapport',
  'tonality': 'Tonality',
};

class LiveSimSession
    implements SimSession, VisemeStreaming, ServerEndableSession {
  LiveSimSession({
    required this.requestId,
    required this.scenarioId,
    required this.simType,
    required Future<String?> Function() fetchIdToken,
    required BrokerConnection Function() openConnection,
    required MicSource micSource,
    required TtsPlayer ttsPlayer,
    int Function()? tzOffsetMinutes,
  })  : _idTokenProvider = fetchIdToken,
        _connect = openConnection,
        _mic = micSource,
        _player = ttsPlayer,
        _tzOffsetMinutes = tzOffsetMinutes ??
            (() => DateTime.now().timeZoneOffset.inMinutes) {
    _scheduler = vs.VisemeScheduler(onMouthGroup: _emitViseme);
    _player.onPlaying = _onUtterancePlaying;
    _player.onComplete = _onUtteranceComplete;
    _player.onIdle = _onPlaybackIdle;
    // Floor error handlers: a session that is disposed or aborted before
    // a score completes these with an error, and not every caller awaits
    // them (the controller does, with onError). This keeps such an error
    // from surfacing as an unhandled async error; real awaiters still
    // receive the value or the error.
    _readyCompleter.future.ignore();
    _resultCompleter.future.ignore();
  }

  final String requestId;
  final String scenarioId;
  final SimType simType;

  final Future<String?> Function() _idTokenProvider;
  final BrokerConnection Function() _connect;
  final MicSource _mic;
  final TtsPlayer _player;
  final int Function() _tzOffsetMinutes;

  late final vs.VisemeScheduler _scheduler;

  final _transcript = StreamController<Utterance>.broadcast();
  final _coaching = StreamController<SimCoachingEvent>.broadcast();
  final _inputLevel = StreamController<double>.broadcast();
  final _outputLevel = StreamController<double>.broadcast();
  final _visemeGroups = StreamController<int>.broadcast();

  final _readyCompleter = Completer<void>();
  final _resultCompleter = Completer<SimResult>();

  BrokerConnection? _conn;
  StreamSubscription<Object>? _framesSub;
  StreamSubscription<Uint8List>? _micSub;
  Timer? _envelope;

  bool _started = false;
  bool _disposed = false;
  bool _ending = false;
  bool _muted = false;
  bool _personaPlaying = false;
  int _tick = 0;

  /// From `ready`: whether the local VAD trigger is allowed to fire.
  bool _interruptTriggerEnabled = false;

  /// VAD state.
  double _voiceMs = 0;
  bool _bargedThisReply = false;

  @override
  Stream<Utterance> get transcript => _transcript.stream;

  @override
  Stream<SimCoachingEvent> get coaching => _coaching.stream;

  @override
  Stream<double> get inputLevel => _inputLevel.stream;

  @override
  Stream<double> get outputLevel => _outputLevel.stream;

  @override
  Stream<int> get visemeGroups => _visemeGroups.stream;

  @override
  Future<SimResult> get ended => _resultCompleter.future;

  // ------------------------------- start ------------------------------------

  @override
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;

    // Fail fast on mic permission before spending anything on the wire.
    bool granted;
    try {
      granted = await _mic.hasPermission();
    } on Object catch (e) {
      throw SimStartException('mic_failure', 'permission check failed: $e');
    }
    if (!granted) {
      throw const SimStartException('mic_failure', 'microphone denied');
    }

    final conn = _connect();
    _conn = conn;
    try {
      await conn.ready;
    } on Object catch (e) {
      await _teardownTransport();
      throw SimStartException('launch_failure', 'socket did not open: $e');
    }
    if (_disposed) return;

    _framesSub = conn.frames.listen(
      _onFrame,
      onDone: _onSocketDone,
      onError: (Object e, StackTrace _) => _onSocketError(e),
    );

    final idToken = await _idTokenProvider();
    if (idToken == null || idToken.isEmpty) {
      await _teardownTransport();
      throw const SimStartException('launch_failure', 'no auth token');
    }

    conn.sendText(encodeHello(
      idToken: idToken,
      requestId: requestId,
      scenarioId: scenarioId,
      simType: simType.schemaValue,
      tzOffsetMinutes: _tzOffsetMinutes(),
    ));

    try {
      await _readyCompleter.future.timeout(_kReadyTimeout);
    } on Object catch (e) {
      await _teardownTransport();
      throw SimStartException('launch_failure', 'never became ready: $e');
    }
    if (_disposed) return;

    // Mic is only opened once the session is live, so we never capture
    // before the broker is listening.
    Stream<Uint8List> micStream;
    try {
      micStream = await _mic.start();
    } on Object catch (e) {
      conn.sendText(encodeAbort('mic_failure'));
      await _teardownTransport();
      throw SimStartException('mic_failure', 'capture failed: $e');
    }
    _micSub = micStream.listen(
      _onMicChunk,
      onError: (Object e, StackTrace _) => _onMicError(e),
    );

    _envelope = Timer.periodic(_kEnvelopeTick, (_) {
      _tick++;
      _outputLevel.add(_personaPlaying ? _envelopeLevel() : 0.0);
    });
  }

  double _envelopeLevel() => 0.675 + 0.325 * math.sin(_tick * 1.1);

  // ----------------------------- mic path -----------------------------------

  void _onMicChunk(Uint8List chunk) {
    if (_disposed || _ending) return;
    if (_muted) {
      _inputLevel.add(0);
      return;
    }
    // Stream to the broker unconditionally, including while the persona
    // speaks: that continuous STT is what makes barge-in possible.
    _conn?.sendBinary(chunk);

    final level = pcm16Rms(chunk);
    _inputLevel.add(level);
    _updateVad(chunk, level);
  }

  void _onMicError(Object error) {
    if (_disposed || _ending) return;
    _conn?.sendText(encodeAbort('mic_failure'));
    _failSession(SimStartException('mic_failure', 'mic stream error: $error'));
  }

  /// The flag-gated local barge-in trigger. Only a sustained utterance
  /// over persona speech fires it; it stays dormant while the broker's
  /// trigger flag is off (the launch default).
  void _updateVad(Uint8List chunk, double level) {
    if (!_interruptTriggerEnabled) return;
    final playing = _player.playing;
    if (playing == null) {
      _voiceMs = 0;
      return;
    }
    final chunkMs = (chunk.lengthInBytes / 2) / kBrokerMicSampleRateHz * 1000;
    if (level >= _kVadLevelThreshold) {
      _voiceMs += chunkMs;
    } else {
      _voiceMs = 0;
    }
    if (_voiceMs >= _kVadSustainMs && !_bargedThisReply) {
      _bargedThisReply = true;
      _bargeIn('client_vad');
    }
  }

  /// Client-initiated barge-in: stop playback and rest the avatar the
  /// moment we SEND the cancel, without waiting for `interrupted`.
  void _bargeIn(String reason) {
    final playing = _player.playing;
    _player.stopCurrent();
    _scheduler.endUtterance();
    _personaPlaying = false;
    _outputLevel.add(0);
    _conn?.sendText(encodeCancel(reason: reason, playing: playing));
  }

  // --------------------------- server frames --------------------------------

  void _onFrame(Object frame) {
    if (_disposed) return;
    if (frame is Uint8List) {
      final decoded = decodeTtsAudioFrame(frame);
      if (decoded != null) {
        _player.addChunk(
            decoded.utteranceId, decoded.chunkIndex, decoded.payload);
      }
      return;
    }
    final msg = parseServerMessage(frame);
    if (msg != null) _handleServerMessage(msg);
  }

  void _handleServerMessage(BrokerServerMessage msg) {
    switch (msg) {
      case ReadyMessage():
        _interruptTriggerEnabled = msg.interruptTriggerEnabled;
        if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      case PersonaStateMessage():
        // 'speaking'/'listening' run on the send clock; audible state is
        // driven from local playback. 'thinking' needs no UI here yet.
        break;
      case SttPartialMessage():
        // Optional live interim; not displayed in the current panel.
        break;
      case TranscriptMessage():
        _transcript.add(Utterance(
          speaker: msg.speaker == 'rep' ? Speaker.rep : Speaker.persona,
          text: msg.text,
          tsMs: msg.tsMs,
        ));
      case UtteranceStartMessage():
        if (msg.sentenceIndex == 0) _bargedThisReply = false;
        _player.beginUtterance(msg.utteranceId);
      case VisemeMessage():
        _scheduler.addEvents([
          for (final e in msg.events)
            vs.VisemeEvent(
              utteranceId: '${msg.utteranceId}',
              azureVisemeId: e.visemeId,
              offsetMs: e.offsetMs,
            ),
        ]);
      case UtteranceEndMessage():
        _player.endUtterance(msg.utteranceId);
      case UtteranceAbortMessage():
        _player.abortUtterance(msg.utteranceId);
        _scheduler.removeUtterance('${msg.utteranceId}');
      case HintMessage():
        _coaching.add(SimHint(
          kind: _momentType(msg.hint),
          label: _kCategoryLabels[msg.categoryKey] ?? msg.categoryKey,
          note: msg.text,
        ));
      case NextMoveMessage():
        _coaching.add(SimNextMove(title: msg.title, body: msg.body));
      case InterruptedMessage():
        _handleInterrupted(msg.fromUtteranceId);
      case EndingMessage():
        // Broker force-ends on the time cap; scoring/scored follow.
        _ending = true;
      case ScoringMessage():
        _ending = true;
      case ScoredMessage():
        if (!_resultCompleter.isCompleted) {
          _resultCompleter.complete(SimResult(sessionId: msg.sessionId));
        }
      case AbortedMessage():
        _failSession(SimStartException('launch_failure', 'aborted: ${msg.reason}'));
      case ErrorMessage():
        if (msg.fatal) {
          final error =
              SimStartException('launch_failure', 'broker error ${msg.code}');
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.completeError(error);
          }
          _failSession(error);
        }
      case PongMessage():
        break;
    }
  }

  void _handleInterrupted(int fromUtteranceId) {
    // Server trigger or confirmation of our cancel: stop, flush, rest.
    _player.interruptFrom(fromUtteranceId);
    _scheduler.endUtterance();
    _personaPlaying = false;
    _outputLevel.add(0);
  }

  MomentType _momentType(String key) => MomentType.values.firstWhere(
        (m) => m.schemaValue == key,
        orElse: () => MomentType.good,
      );

  // --------------------------- playback hooks -------------------------------

  void _onUtterancePlaying(int utteranceId, Stream<Duration> position) {
    if (_disposed) return;
    _personaPlaying = true;
    _scheduler.attachPlayback(
      utteranceId: '$utteranceId',
      position: position,
    );
  }

  void _onUtteranceComplete(int utteranceId) {
    if (_disposed) return;
    _conn?.sendText(encodePlayed(utteranceId));
    _scheduler.removeUtterance('$utteranceId');
  }

  void _onPlaybackIdle() {
    if (_disposed) return;
    _personaPlaying = false;
    _outputLevel.add(0);
    _scheduler.endUtterance();
  }

  void _emitViseme(int mouthGroup) {
    if (_disposed) return;
    _visemeGroups.add(mouthGroup);
  }

  // ------------------------------- mute -------------------------------------

  @override
  void setMuted({required bool muted}) {
    _muted = muted;
    if (muted) _inputLevel.add(0);
  }

  // -------------------------------- end -------------------------------------

  @override
  Future<SimResult> end({required String reason}) async {
    if (_disposed) {
      throw const SimStartException('launch_failure', 'session disposed');
    }
    if (!_ending) {
      _ending = true;
      // Stop transmitting the moment the rep hangs up.
      await _micSub?.cancel();
      _micSub = null;
      unawaited(_mic.stop());
      if (reason == 'user_hangup') {
        _conn?.sendText(encodeEnd());
      } else {
        _conn?.sendText(encodeAbort(reason));
      }
    }
    return _resultCompleter.future;
  }

  // ----------------------------- teardown -----------------------------------

  void _onSocketDone() {
    if (_disposed) return;
    final code = _conn?.closeCode;
    if (code == BrokerCloseCode.normal) return;
    _failSession(
      SimStartException('launch_failure', 'socket closed: $code'),
    );
  }

  void _onSocketError(Object error) {
    if (_disposed) return;
    _failSession(SimStartException('launch_failure', 'socket error: $error'));
  }

  /// An unexpected end before a score: surface it on the completers so
  /// awaiters (start, end, the controller) unblock. Session 16 turns
  /// this into the aborted-call UX and the abortSimSession refund.
  void _failSession(Object error) {
    if (!_readyCompleter.isCompleted) _readyCompleter.completeError(error);
    if (!_resultCompleter.isCompleted) _resultCompleter.completeError(error);
  }

  Future<void> _teardownTransport() async {
    await _framesSub?.cancel();
    _framesSub = null;
    await _conn?.close();
    _conn = null;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _envelope?.cancel();
    _failSession(
      const SimStartException('launch_failure', 'session disposed'),
    );
    await _micSub?.cancel();
    await _mic.stop();
    await _mic.dispose();
    await _framesSub?.cancel();
    _scheduler.dispose();
    await _player.dispose();
    await _conn?.close();
    await Future.wait([
      _transcript.close(),
      _coaching.close(),
      _inputLevel.close(),
      _outputLevel.close(),
      _visemeGroups.close(),
    ]);
  }
}
