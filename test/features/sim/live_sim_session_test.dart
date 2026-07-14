import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:closero_app/features/scoring/domain/session_doc.dart';
import 'package:closero_app/features/sim/data/broker_connection.dart';
import 'package:closero_app/features/sim/data/broker_protocol.dart';
import 'package:closero_app/features/sim/data/live_sim_session.dart';
import 'package:closero_app/features/sim/data/mic_source.dart';
import 'package:closero_app/features/sim/data/tts_player.dart';
import 'package:closero_app/features/sim/domain/sim_session.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConn implements BrokerConnection {
  final _frames = StreamController<Object>.broadcast();
  final List<String> sentText = [];
  final List<Uint8List> sentBinary = [];
  int? _closeCode;
  bool closed = false;

  @override
  Future<void> get ready => Future.value();
  @override
  Stream<Object> get frames => _frames.stream;
  @override
  int? get closeCode => _closeCode;
  @override
  void sendText(String text) => sentText.add(text);
  @override
  void sendBinary(Uint8List bytes) => sentBinary.add(bytes);
  @override
  Future<void> close([int? code, String? reason]) async => closed = true;

  void push(Object frame) => _frames.add(frame);
  Future<void> serverClose(int code) async {
    _closeCode = code;
    await _frames.close();
  }

  Map<String, dynamic> lastJson(String type) => (sentText
      .map((t) => jsonDecode(t) as Map<String, dynamic>)
      .lastWhere((m) => m['type'] == type));

  bool sent(String type) =>
      sentText.any((t) => (jsonDecode(t) as Map)['type'] == type);
}

class _FakeMic implements MicSource {
  final _chunks = StreamController<Uint8List>.broadcast();
  bool permission = true;
  bool started = false;
  bool stopped = false;

  @override
  Future<bool> hasPermission() async => permission;
  @override
  Future<Stream<Uint8List>> start() async {
    started = true;
    return _chunks.stream;
  }

  @override
  Future<void> stop() async => stopped = true;
  @override
  Future<void> dispose() async {}

  void emit(Uint8List chunk) => _chunks.add(chunk);
}

class _FakePlayer extends TtsPlayer {
  final List<int> begun = [];
  final List<(int, int)> chunks = [];
  final List<int> ended = [];
  final List<int> abortedIds = [];
  final List<int> interruptedFrom = [];
  int stopCurrentCount = 0;
  PlaybackPosition? playingValue;

  @override
  void beginUtterance(int utteranceId) => begun.add(utteranceId);
  @override
  void addChunk(int utteranceId, int chunkIndex, Uint8List payload) =>
      chunks.add((utteranceId, chunkIndex));
  @override
  void endUtterance(int utteranceId) => ended.add(utteranceId);
  @override
  void abortUtterance(int utteranceId) => abortedIds.add(utteranceId);
  @override
  void stopCurrent() => stopCurrentCount++;
  @override
  void interruptFrom(int fromUtteranceId) =>
      interruptedFrom.add(fromUtteranceId);
  @override
  PlaybackPosition? get playing => playingValue;
  @override
  Future<void> dispose() async {}

  void simulatePlaying(int id, Stream<Duration> position) =>
      onPlaying?.call(id, position);
  void simulateComplete(int id) => onComplete?.call(id);
  void simulateIdle() => onIdle?.call();
}

typedef _Harness = ({
  LiveSimSession session,
  _FakeConn conn,
  _FakeMic mic,
  _FakePlayer player,
});

_Harness _build({String scenarioId = 'cold-call-saas-gatekeeper'}) {
  final conn = _FakeConn();
  final mic = _FakeMic();
  final player = _FakePlayer();
  final session = LiveSimSession(
    requestId: 'req-abcdefghij1234567890',
    scenarioId: scenarioId,
    simType: SimType.coldCall,
    fetchIdToken: () async => 'id-token',
    openConnection: () => conn,
    micSource: mic,
    ttsPlayer: player,
    tzOffsetMinutes: () => -300,
  );
  return (session: session, conn: conn, mic: mic, player: player);
}

String _readyFrame({bool interrupt = false}) => jsonEncode({
      'type': 'ready',
      'v': 1,
      'sessionId': 'sess-1',
      'scenarioId': 'cold-call-saas-gatekeeper',
      'personaName': 'Sandra Voss',
      'voice': 'en-US-JennyNeural',
      'interruptTriggerEnabled': interrupt,
      'contentVersions': {
        'replyLengthPolicy': 'a',
        'personaBrief': 'b',
        'hintRubric': 'c',
        'scoringRubric': 'd',
      },
      'limits': {'maxSessionMs': 1200000, 'idleTimeoutMs': 90000},
    });

Future<void> _startReady(_Harness h, {bool interrupt = false}) async {
  final started = h.session.start();
  await pumpEventQueue();
  h.conn.push(_readyFrame(interrupt: interrupt));
  await started;
}

Uint8List _ttsFrame(int id, int chunkIndex, List<int> payload) {
  final header = ByteData(kBrokerBinaryHeaderBytes)
    ..setUint8(0, kBrokerProtocolVersion)
    ..setUint8(1, kBrokerBinaryKindTtsAudio)
    ..setUint16(2, id, Endian.little)
    ..setUint32(4, chunkIndex, Endian.little);
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(payload))
      .toBytes();
}

Uint8List _loudChunk({int ms = 100}) {
  final samples = (ms / 1000 * kBrokerMicSampleRateHz).round();
  final data = ByteData(samples * 2);
  for (var i = 0; i < samples; i++) {
    data.setInt16(i * 2, 30000, Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  test('start sends hello then opens the mic once ready', () async {
    final h = _build();
    await _startReady(h);

    final hello = h.conn.lastJson('hello');
    expect(hello['requestId'], 'req-abcdefghij1234567890');
    expect(hello['scenarioId'], 'cold-call-saas-gatekeeper');
    expect(hello['simType'], 'cold_call');
    expect(hello['tzOffsetMinutes'], -300);
    expect(h.mic.started, isTrue);

    await h.session.dispose();
  });

  test('mic denied fails start as a mic_failure and never connects',
      () async {
    final h = _build();
    h.mic.permission = false;
    await expectLater(
      h.session.start(),
      throwsA(isA<SimStartException>()
          .having((e) => e.reason, 'reason', 'mic_failure')),
    );
    expect(h.conn.sentText, isEmpty);
    await h.session.dispose();
  });

  test('transcript and coaching frames map to the screen streams',
      () async {
    final h = _build();
    final utterances = <Utterance>[];
    final events = <SimCoachingEvent>[];
    h.session.transcript.listen(utterances.add);
    h.session.coaching.listen(events.add);
    await _startReady(h);

    h.conn.push(jsonEncode({
      'type': 'transcript',
      'index': 0,
      'speaker': 'persona',
      'text': 'How can I direct your call?',
      'tsMs': 2000,
    }));
    h.conn.push(jsonEncode({
      'type': 'hint',
      'hint': 'good',
      'categoryKey': 'rapport',
      'text': 'Used her name.',
      'utteranceIndex': 0,
    }));
    h.conn.push(jsonEncode({
      'type': 'nextMove',
      'title': 'Redirect',
      'body': 'Bridge back to David.',
    }));
    await pumpEventQueue();

    expect(utterances, hasLength(1));
    expect(utterances.single.speaker, Speaker.persona);
    expect(utterances.single.tsMs, 2000);
    expect(events, hasLength(2));
    final hint = events.first as SimHint;
    expect(hint.kind, MomentType.good);
    expect(hint.label, 'Rapport');
    expect(hint.note, 'Used her name.');
    expect(events.last, isA<SimNextMove>());

    await h.session.dispose();
  });

  test('utterance lifecycle: buffer, viseme against playback, played ack',
      () async {
    final h = _build();
    final visemeGroups = <int>[];
    h.session.visemeGroups.listen(visemeGroups.add);
    await _startReady(h);

    h.conn.push(jsonEncode({
      'type': 'utteranceStart',
      'utteranceId': 1,
      'sentenceIndex': 0,
      'text': 'Hello.',
      'format': 'audio/mpeg',
    }));
    h.conn.push(_ttsFrame(1, 0, [1, 2, 3]));
    h.conn.push(jsonEncode({
      'type': 'viseme',
      'utteranceId': 1,
      'events': [
        {'visemeId': 2, 'offsetMs': 0},
      ],
    }));
    h.conn.push(jsonEncode({
      'type': 'utteranceEnd',
      'utteranceId': 1,
      'chunkCount': 1,
      'byteLength': 3,
      'approxDurationMs': 800,
    }));
    await pumpEventQueue();

    expect(h.player.begun, [1]);
    expect(h.player.chunks, [(1, 0)]);
    expect(h.player.ended, [1]);

    // The player reports the utterance is now audible; visemes fire
    // against its playback clock, not on arrival.
    final position = StreamController<Duration>.broadcast();
    h.player.simulatePlaying(1, position.stream);
    position.add(const Duration(milliseconds: 100));
    await pumpEventQueue();
    expect(visemeGroups, contains(1)); // azure viseme 2 -> AA (1)

    h.player.simulateComplete(1);
    await pumpEventQueue();
    expect(h.conn.sent('played'), isTrue);
    expect(h.conn.lastJson('played')['utteranceId'], 1);

    await position.close();
    await h.session.dispose();
  });

  test('server interrupted flushes playback from the given id', () async {
    final h = _build();
    await _startReady(h);
    h.player.playingValue =
        const PlaybackPosition(utteranceId: 2, positionMs: 300);

    h.conn.push(jsonEncode({
      'type': 'interrupted',
      'fromUtteranceId': 2,
      'reason': 'barge_in',
    }));
    await pumpEventQueue();

    expect(h.player.interruptedFrom, [2]);
    await h.session.dispose();
  });

  test('local VAD fires a client_vad cancel only when the flag is on',
      () async {
    // Flag off: sustained speech over playback does NOT interrupt.
    final off = _build();
    await _startReady(off, interrupt: false);
    off.player.playingValue =
        const PlaybackPosition(utteranceId: 1, positionMs: 200);
    for (var i = 0; i < 10; i++) {
      off.mic.emit(_loudChunk());
    }
    await pumpEventQueue();
    expect(off.conn.sent('cancel'), isFalse);
    expect(off.player.stopCurrentCount, 0);
    await off.session.dispose();

    // Flag on: a sustained utterance over playback fires exactly one.
    final on = _build();
    await _startReady(on, interrupt: true);
    on.player.playingValue =
        const PlaybackPosition(utteranceId: 1, positionMs: 200);
    for (var i = 0; i < 10; i++) {
      on.mic.emit(_loudChunk());
    }
    await pumpEventQueue();
    expect(on.conn.sent('cancel'), isTrue);
    expect(on.conn.lastJson('cancel')['reason'], 'client_vad');
    expect(on.player.stopCurrentCount, 1);
    await on.session.dispose();
  });

  test('muting stops transmitting mic audio to the broker', () async {
    final h = _build();
    await _startReady(h);

    h.mic.emit(_loudChunk());
    await pumpEventQueue();
    expect(h.conn.sentBinary, hasLength(1));

    h.session.setMuted(muted: true);
    h.mic.emit(_loudChunk());
    await pumpEventQueue();
    expect(h.conn.sentBinary, hasLength(1)); // nothing new sent while muted

    await h.session.dispose();
  });

  test('end sends the hangup and resolves on the scored frame', () async {
    final h = _build();
    await _startReady(h);

    final ending = h.session.end(reason: 'user_hangup');
    await pumpEventQueue();
    expect(h.conn.sent('end'), isTrue);

    h.conn.push(jsonEncode({
      'type': 'scored',
      'sessionId': 'sess-1',
      'total': 72,
      'delta': {'value': 0, 'basis': 'last_session'},
    }));
    final result = await ending;
    expect(result.sessionId, 'sess-1');
    expect(await h.session.ended, isA<SimResult>());

    await h.session.dispose();
  });

  test('an unexpected close ends the session without a score', () async {
    final h = _build();
    await _startReady(h);

    final ended = h.session.ended;
    await h.conn.serverClose(BrokerCloseCode.superseded);
    await expectLater(ended, throwsA(isA<SimStartException>()));

    await h.session.dispose();
  });
}
