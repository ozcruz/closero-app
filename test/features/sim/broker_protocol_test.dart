import 'dart:convert';
import 'dart:typed_data';

import 'package:closero_app/features/sim/data/broker_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _ttsFrame(int utteranceId, int chunkIndex, List<int> payload) {
  final header = ByteData(kBrokerBinaryHeaderBytes)
    ..setUint8(0, kBrokerProtocolVersion)
    ..setUint8(1, kBrokerBinaryKindTtsAudio)
    ..setUint16(2, utteranceId, Endian.little)
    ..setUint32(4, chunkIndex, Endian.little);
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(payload))
      .toBytes();
}

void main() {
  group('client message encoders', () {
    test('hello carries the version and identity fields', () {
      final json = jsonDecode(encodeHello(
        idToken: 'tok',
        requestId: 'req-1234567890abcdef',
        scenarioId: 'cold-call-saas-gatekeeper',
        simType: 'cold_call',
        tzOffsetMinutes: -300,
      )) as Map<String, dynamic>;
      expect(json['type'], 'hello');
      expect(json['v'], kBrokerProtocolVersion);
      expect(json['idToken'], 'tok');
      expect(json['scenarioId'], 'cold-call-saas-gatekeeper');
      expect(json['simType'], 'cold_call');
      expect(json['tzOffsetMinutes'], -300);
    });

    test('cancel carries the playback position, or null', () {
      final withPlaying = jsonDecode(encodeCancel(
        reason: 'client_vad',
        playing: const PlaybackPosition(utteranceId: 3, positionMs: 420),
      )) as Map<String, dynamic>;
      expect(withPlaying['reason'], 'client_vad');
      expect(withPlaying['playing'], {'utteranceId': 3, 'positionMs': 420});

      final none = jsonDecode(encodeCancel(reason: 'user_tap'))
          as Map<String, dynamic>;
      expect(none['playing'], isNull);
    });

    test('played, end, abort, ping', () {
      expect(jsonDecode(encodePlayed(7)),
          {'type': 'played', 'utteranceId': 7});
      expect(jsonDecode(encodeEnd()), {'type': 'end', 'reason': 'user_hangup'});
      expect(jsonDecode(encodeAbort('mic_failure')),
          {'type': 'abort', 'reason': 'mic_failure'});
      expect(jsonDecode(encodePing(99)), {'type': 'ping', 't': 99});
    });
  });

  group('server message decoder', () {
    test('ready flattens limits and the interrupt flag', () {
      final msg = parseServerMessage(jsonEncode({
        'type': 'ready',
        'v': 1,
        'sessionId': 'sess-1',
        'scenarioId': 'sc',
        'personaName': 'Sandra Voss',
        'voice': 'en-US-JennyNeural',
        'interruptTriggerEnabled': true,
        'contentVersions': {
          'replyLengthPolicy': 'a',
          'personaBrief': 'b',
          'hintRubric': 'c',
          'scoringRubric': 'd',
        },
        'limits': {'maxSessionMs': 1200000, 'idleTimeoutMs': 90000},
      }));
      expect(msg, isA<ReadyMessage>());
      final ready = msg! as ReadyMessage;
      expect(ready.sessionId, 'sess-1');
      expect(ready.personaName, 'Sandra Voss');
      expect(ready.interruptTriggerEnabled, isTrue);
      expect(ready.maxSessionMs, 1200000);
      expect(ready.idleTimeoutMs, 90000);
    });

    test('transcript, hint, nextMove, scored', () {
      expect(
        parseServerMessage(jsonEncode({
          'type': 'transcript',
          'index': 2,
          'speaker': 'persona',
          'text': 'Hello there.',
          'tsMs': 5400,
        })),
        isA<TranscriptMessage>()
            .having((m) => m.speaker, 'speaker', 'persona')
            .having((m) => m.tsMs, 'tsMs', 5400),
      );
      expect(
        parseServerMessage(jsonEncode({
          'type': 'hint',
          'hint': 'good',
          'categoryKey': 'rapport',
          'text': 'Used her name.',
          'utteranceIndex': 1,
        })),
        isA<HintMessage>()
            .having((m) => m.hint, 'hint', 'good')
            .having((m) => m.categoryKey, 'categoryKey', 'rapport'),
      );
      expect(
        parseServerMessage(jsonEncode({
          'type': 'nextMove',
          'title': 'Redirect',
          'body': 'Bridge back.',
        })),
        isA<NextMoveMessage>().having((m) => m.title, 'title', 'Redirect'),
      );
      final scored = parseServerMessage(jsonEncode({
        'type': 'scored',
        'sessionId': 'sess-9',
        'total': 72,
        'delta': {'value': 4, 'basis': 'rolling_10'},
      }));
      expect(
        scored,
        isA<ScoredMessage>()
            .having((m) => m.total, 'total', 72)
            .having((m) => m.deltaValue, 'deltaValue', 4)
            .having((m) => m.deltaBasis, 'basis', 'rolling_10'),
      );
    });

    test('viseme events keep id and offset', () {
      final msg = parseServerMessage(jsonEncode({
        'type': 'viseme',
        'utteranceId': 4,
        'events': [
          {'visemeId': 2, 'offsetMs': 0},
          {'visemeId': 21, 'offsetMs': 120},
        ],
      }))! as VisemeMessage;
      expect(msg.utteranceId, 4);
      expect(msg.events, hasLength(2));
      expect(msg.events[1].visemeId, 21);
      expect(msg.events[1].offsetMs, 120);
    });

    test('interrupted and error', () {
      expect(
        parseServerMessage(jsonEncode({
          'type': 'interrupted',
          'fromUtteranceId': 5,
          'reason': 'barge_in',
        })),
        isA<InterruptedMessage>()
            .having((m) => m.fromUtteranceId, 'fromUtteranceId', 5)
            .having((m) => m.reason, 'reason', 'barge_in'),
      );
      expect(
        parseServerMessage(jsonEncode({
          'type': 'error',
          'code': 'stt_unavailable',
          'message': 'down',
          'fatal': true,
        })),
        isA<ErrorMessage>().having((m) => m.fatal, 'fatal', true),
      );
    });

    test('unknown type and malformed payload return null', () {
      expect(parseServerMessage(jsonEncode({'type': 'somethingNew'})), isNull);
      expect(parseServerMessage('not json at all {'), isNull);
      // Known type, missing required field: fail soft, do not throw.
      expect(parseServerMessage(jsonEncode({'type': 'transcript'})), isNull);
    });

    test('accepts an already-decoded map', () {
      expect(
        parseServerMessage({'type': 'scoring'}),
        isA<ScoringMessage>(),
      );
    });
  });

  group('binary TTS frame', () {
    test('decodes a well-formed frame', () {
      final frame = decodeTtsAudioFrame(_ttsFrame(258, 3, [10, 20, 30]));
      expect(frame, isNotNull);
      expect(frame!.utteranceId, 258);
      expect(frame.chunkIndex, 3);
      expect(frame.payload, [10, 20, 30]);
    });

    test('rejects short, wrong-version, and wrong-kind frames', () {
      expect(decodeTtsAudioFrame(Uint8List(4)), isNull);
      final wrongVersion = _ttsFrame(1, 0, [1])..[0] = 9;
      expect(decodeTtsAudioFrame(wrongVersion), isNull);
      final wrongKind = _ttsFrame(1, 0, [1])..[1] = 2;
      expect(decodeTtsAudioFrame(wrongKind), isNull);
    });
  });
}
