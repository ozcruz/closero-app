import 'dart:async';
import 'dart:math' as math;

import '../../scoring/domain/session_doc.dart';
import '../domain/sim_script.dart';
import '../domain/sim_session.dart';

/// Canned persona turns on timers behind the real [SimSession]
/// interface. The screens bind to the interface only, so the live
/// pipeline (Session 14) swaps in without touching them.
///
/// Speaking envelopes are synthesized: while a turn is active its
/// stream emits a deterministic pulse every [_envelopeTick]; both
/// streams emit 0 when the speaker falls silent.
class ScriptedSimSession implements SimSession {
  ScriptedSimSession(this.script);

  final SimScript script;

  static const _envelopeTick = Duration(milliseconds: 120);

  final _transcript = StreamController<Utterance>.broadcast();
  final _coaching = StreamController<SimCoachingEvent>.broadcast();
  final _inputLevel = StreamController<double>.broadcast();
  final _outputLevel = StreamController<double>.broadcast();

  final List<Timer> _timers = [];
  Timer? _envelope;
  bool _started = false;
  bool _disposed = false;

  /// Envelope phase counter, advanced per tick.
  int _tick = 0;

  /// Ends of the currently active turns, in ms since start, per side.
  int _repSpeakingUntilMs = 0;
  int _personaSpeakingUntilMs = 0;
  int _elapsedMs = 0;

  @override
  Stream<Utterance> get transcript => _transcript.stream;

  @override
  Stream<SimCoachingEvent> get coaching => _coaching.stream;

  @override
  Stream<double> get inputLevel => _inputLevel.stream;

  @override
  Stream<double> get outputLevel => _outputLevel.stream;

  @override
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;

    for (final turn in script.turns) {
      _timers.add(Timer(Duration(milliseconds: turn.atMs), () {
        _transcript.add(Utterance(
          speaker: turn.speaker,
          text: turn.text,
          tsMs: turn.atMs,
        ));
        final until = turn.atMs + turn.durMs;
        if (turn.speaker == Speaker.rep) {
          _repSpeakingUntilMs = math.max(_repSpeakingUntilMs, until);
        } else {
          _personaSpeakingUntilMs =
              math.max(_personaSpeakingUntilMs, until);
        }
      }));
    }
    for (final entry in script.coaching) {
      _timers.add(Timer(Duration(milliseconds: entry.atMs), () {
        _coaching.add(entry.event);
      }));
    }

    _envelope = Timer.periodic(_envelopeTick, (_) {
      _tick++;
      _elapsedMs += _envelopeTick.inMilliseconds;
      _inputLevel.add(_levelFor(active: _elapsedMs < _repSpeakingUntilMs));
      _outputLevel
          .add(_levelFor(active: _elapsedMs < _personaSpeakingUntilMs));
    });
  }

  /// A softly varying 0.35 to 1.0 pulse while active, 0 when silent.
  double _levelFor({required bool active}) =>
      active ? 0.675 + 0.325 * math.sin(_tick * 1.1) : 0.0;

  @override
  void setMuted({required bool muted}) {
    // No real mic to gate; the canned envelope is unaffected.
  }

  @override
  Future<SimResult> end({required String reason}) async {
    await dispose();
    return SimResult(sessionId: script.resultSessionId);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    _envelope?.cancel();
    await Future.wait([
      _transcript.close(),
      _coaching.close(),
      _inputLevel.close(),
      _outputLevel.close(),
    ]);
  }
}
