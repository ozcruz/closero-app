/// Dart mirror of the session broker wire protocol v1
/// (closero-broker/src/protocol.ts, human-readable in docs/PROTOCOL.md).
///
/// This file is the client half of that binding contract: message
/// encoders (client to server), a sealed decoder (server to client),
/// and the 8-byte binary TTS frame header. If the broker's protocol.ts
/// changes, this changes with it in the same spirit.
///
/// Decoding is defensive: an unknown `type` or a malformed frame
/// returns null rather than throwing, matching the protocol's
/// forward-compatibility rule ("unknown JSON types must be ignored by
/// both sides") and the fail-soft rule for a live call.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Wire version, the u8 in every binary frame and the `v` in hello.
const int kBrokerProtocolVersion = 1;

/// Bytes of little-endian header on every server-to-client audio frame.
const int kBrokerBinaryHeaderBytes = 8;

/// Binary frame `kind` for a TTS audio chunk.
const int kBrokerBinaryKindTtsAudio = 1;

/// Send `hello` within this window of the socket opening or the broker
/// closes 4408.
const int kBrokerHelloTimeoutMs = 10000;

/// Mic audio contract: raw PCM16 little-endian, mono, this sample rate.
const int kBrokerMicSampleRateHz = 16000;

/// WebSocket close codes the broker uses (docs/PROTOCOL.md).
abstract final class BrokerCloseCode {
  /// Normal close after `scored` / `aborted`.
  static const int normal = 1000;

  /// Malformed hello or unknown scenarioId.
  static const int badHello = 4400;

  /// Firebase ID token invalid or expired.
  static const int unauthenticated = 4401;

  /// No startSimSession grant, or scenario tier above the entitlement.
  static const int noGrant = 4403;

  /// hello did not arrive within [kBrokerHelloTimeoutMs].
  static const int helloTimeout = 4408;

  /// A newer authenticated connection for this session took over.
  static const int superseded = 4409;

  /// Broker internal failure (an `error` message precedes it).
  static const int internal = 4500;
}

/// The client's playback state at a moment, carried on `cancel` so the
/// broker can truncate the persona transcript to what was actually
/// heard. Null when nothing is audible.
class PlaybackPosition {
  const PlaybackPosition({required this.utteranceId, required this.positionMs});

  final int utteranceId;
  final int positionMs;

  Map<String, dynamic> toJson() =>
      {'utteranceId': utteranceId, 'positionMs': positionMs};
}

// --------------------------- client -> server -------------------------------

/// First message on the socket. `simType` is the schema string
/// ('cold_call' | 'video'); `tzOffsetMinutes` is
/// DateTime.now().timeZoneOffset.inMinutes.
String encodeHello({
  required String idToken,
  required String requestId,
  required String scenarioId,
  required String simType,
  required int tzOffsetMinutes,
}) =>
    jsonEncode({
      'type': 'hello',
      'v': kBrokerProtocolVersion,
      'idToken': idToken,
      'requestId': requestId,
      'scenarioId': scenarioId,
      'simType': simType,
      'tzOffsetMinutes': tzOffsetMinutes,
    });

/// Barge-in. `reason` is 'user_tap' (explicit) or 'client_vad' (the
/// flag-gated local detector). `playing` is the playback state at the
/// moment of cancel, or null if nothing was audible.
String encodeCancel({required String reason, PlaybackPosition? playing}) =>
    jsonEncode({
      'type': 'cancel',
      'reason': reason,
      'playing': playing?.toJson(),
    });

/// Playback ack: an utterance finished playing locally.
String encodePlayed(int utteranceId) =>
    jsonEncode({'type': 'played', 'utteranceId': utteranceId});

/// Normal hang-up: the broker scores the call.
String encodeEnd() => jsonEncode({'type': 'end', 'reason': 'user_hangup'});

/// Client-side technical failure: no score, cap credit refunded.
/// `reason` is 'mic_failure' | 'launch_failure'.
String encodeAbort(String reason) =>
    jsonEncode({'type': 'abort', 'reason': reason});

/// Liveness ping, echoed as `pong`.
String encodePing(int t) => jsonEncode({'type': 'ping', 't': t});

// --------------------------- server -> client -------------------------------

/// One Azure viseme event: id 0..21 and offset ms from the utterance's
/// audio start.
class BrokerVisemeEvent {
  const BrokerVisemeEvent({required this.visemeId, required this.offsetMs});

  final int visemeId;
  final int offsetMs;
}

/// Base type for every decoded server message.
sealed class BrokerServerMessage {
  const BrokerServerMessage();
}

class ReadyMessage extends BrokerServerMessage {
  const ReadyMessage({
    required this.sessionId,
    required this.scenarioId,
    required this.personaName,
    required this.voice,
    required this.interruptTriggerEnabled,
    required this.maxSessionMs,
    required this.idleTimeoutMs,
  });

  final String sessionId;
  final String scenarioId;
  final String personaName;
  final String voice;
  final bool interruptTriggerEnabled;
  final int maxSessionMs;
  final int idleTimeoutMs;
}

class PersonaStateMessage extends BrokerServerMessage {
  const PersonaStateMessage(this.state);

  /// 'listening' | 'thinking' | 'speaking'. Only 'thinking' is
  /// authoritative for UI; audible speaking is derived from playback.
  final String state;
}

class SttPartialMessage extends BrokerServerMessage {
  const SttPartialMessage(this.text);
  final String text;
}

class TranscriptMessage extends BrokerServerMessage {
  const TranscriptMessage({
    required this.index,
    required this.speaker,
    required this.text,
    required this.tsMs,
  });

  final int index;

  /// 'rep' | 'persona'.
  final String speaker;
  final String text;
  final int tsMs;
}

class UtteranceStartMessage extends BrokerServerMessage {
  const UtteranceStartMessage({
    required this.utteranceId,
    required this.sentenceIndex,
    required this.text,
    required this.format,
  });

  final int utteranceId;
  final int sentenceIndex;
  final String text;
  final String format;
}

class VisemeMessage extends BrokerServerMessage {
  const VisemeMessage({required this.utteranceId, required this.events});

  final int utteranceId;
  final List<BrokerVisemeEvent> events;
}

class UtteranceEndMessage extends BrokerServerMessage {
  const UtteranceEndMessage({
    required this.utteranceId,
    required this.chunkCount,
    required this.byteLength,
    required this.approxDurationMs,
  });

  final int utteranceId;
  final int chunkCount;
  final int byteLength;
  final int approxDurationMs;
}

class UtteranceAbortMessage extends BrokerServerMessage {
  const UtteranceAbortMessage({required this.utteranceId, required this.reason});
  final int utteranceId;
  final String reason;
}

class HintMessage extends BrokerServerMessage {
  const HintMessage({
    required this.hint,
    required this.categoryKey,
    required this.text,
    required this.utteranceIndex,
  });

  /// 'good' | 'warn' | 'miss'.
  final String hint;

  /// One of the five locked category keys.
  final String categoryKey;
  final String text;
  final int utteranceIndex;
}

class NextMoveMessage extends BrokerServerMessage {
  const NextMoveMessage({required this.title, required this.body});
  final String title;
  final String body;
}

class InterruptedMessage extends BrokerServerMessage {
  const InterruptedMessage({required this.fromUtteranceId, required this.reason});

  /// First discarded (not fully heard) utteranceId; flush everything
  /// with id >= this.
  final int fromUtteranceId;

  /// 'client_cancel' (confirms our cancel) | 'barge_in' (server trigger).
  final String reason;
}

class EndingMessage extends BrokerServerMessage {
  const EndingMessage(this.reason);

  /// 'time_cap'.
  final String reason;
}

class ScoringMessage extends BrokerServerMessage {
  const ScoringMessage();
}

class ScoredMessage extends BrokerServerMessage {
  const ScoredMessage({
    required this.sessionId,
    required this.total,
    required this.deltaValue,
    required this.deltaBasis,
  });

  final String sessionId;
  final int total;
  final int deltaValue;

  /// 'last_session' | 'rolling_10'.
  final String deltaBasis;
}

class AbortedMessage extends BrokerServerMessage {
  const AbortedMessage(this.reason);
  final String reason;
}

class ErrorMessage extends BrokerServerMessage {
  const ErrorMessage({
    required this.code,
    required this.message,
    required this.fatal,
  });

  final String code;
  final String message;
  final bool fatal;
}

class PongMessage extends BrokerServerMessage {
  const PongMessage(this.t);
  final int t;
}

/// Decodes a text frame into a typed message. Returns null for an
/// unknown `type` (ignore, per forward-compat) or a malformed payload
/// (fail soft, never crash a live call). Accepts a JSON string or an
/// already-decoded Map.
BrokerServerMessage? parseServerMessage(Object? frame) {
  final Map<String, dynamic> json;
  try {
    if (frame is String) {
      final decoded = jsonDecode(frame);
      if (decoded is! Map) return null;
      json = decoded.cast<String, dynamic>();
    } else if (frame is Map) {
      json = frame.cast<String, dynamic>();
    } else {
      return null;
    }
  } on Object {
    return null;
  }

  try {
    switch (json['type']) {
      case 'ready':
        final limits = (json['limits'] as Map).cast<String, dynamic>();
        return ReadyMessage(
          sessionId: json['sessionId'] as String,
          scenarioId: json['scenarioId'] as String,
          personaName: json['personaName'] as String,
          voice: json['voice'] as String,
          interruptTriggerEnabled: json['interruptTriggerEnabled'] == true,
          maxSessionMs: (limits['maxSessionMs'] as num).toInt(),
          idleTimeoutMs: (limits['idleTimeoutMs'] as num).toInt(),
        );
      case 'personaState':
        return PersonaStateMessage(json['state'] as String);
      case 'sttPartial':
        return SttPartialMessage(json['text'] as String);
      case 'transcript':
        return TranscriptMessage(
          index: (json['index'] as num).toInt(),
          speaker: json['speaker'] as String,
          text: json['text'] as String,
          tsMs: (json['tsMs'] as num).toInt(),
        );
      case 'utteranceStart':
        return UtteranceStartMessage(
          utteranceId: (json['utteranceId'] as num).toInt(),
          sentenceIndex: (json['sentenceIndex'] as num).toInt(),
          text: json['text'] as String,
          format: json['format'] as String,
        );
      case 'viseme':
        final rawEvents = (json['events'] as List).cast<dynamic>();
        return VisemeMessage(
          utteranceId: (json['utteranceId'] as num).toInt(),
          events: [
            for (final e in rawEvents)
              BrokerVisemeEvent(
                visemeId: ((e as Map)['visemeId'] as num).toInt(),
                offsetMs: (e['offsetMs'] as num).toInt(),
              ),
          ],
        );
      case 'utteranceEnd':
        return UtteranceEndMessage(
          utteranceId: (json['utteranceId'] as num).toInt(),
          chunkCount: (json['chunkCount'] as num).toInt(),
          byteLength: (json['byteLength'] as num).toInt(),
          approxDurationMs: (json['approxDurationMs'] as num).toInt(),
        );
      case 'utteranceAbort':
        return UtteranceAbortMessage(
          utteranceId: (json['utteranceId'] as num).toInt(),
          reason: json['reason'] as String,
        );
      case 'hint':
        return HintMessage(
          hint: json['hint'] as String,
          categoryKey: json['categoryKey'] as String,
          text: json['text'] as String,
          utteranceIndex: (json['utteranceIndex'] as num).toInt(),
        );
      case 'nextMove':
        return NextMoveMessage(
          title: json['title'] as String,
          body: json['body'] as String,
        );
      case 'interrupted':
        return InterruptedMessage(
          fromUtteranceId: (json['fromUtteranceId'] as num).toInt(),
          reason: json['reason'] as String,
        );
      case 'ending':
        return EndingMessage(json['reason'] as String);
      case 'scoring':
        return const ScoringMessage();
      case 'scored':
        final delta = (json['delta'] as Map).cast<String, dynamic>();
        return ScoredMessage(
          sessionId: json['sessionId'] as String,
          total: (json['total'] as num).toInt(),
          deltaValue: (delta['value'] as num).toInt(),
          deltaBasis: delta['basis'] as String,
        );
      case 'aborted':
        return AbortedMessage(json['reason'] as String);
      case 'error':
        return ErrorMessage(
          code: json['code'] as String,
          message: json['message'] as String? ?? '',
          fatal: json['fatal'] == true,
        );
      case 'pong':
        return PongMessage((json['t'] as num).toInt());
      default:
        // Unknown type: ignore for forward compatibility.
        return null;
    }
  } on Object {
    // Malformed but known type: fail soft, keep the call alive.
    return null;
  }
}

/// A decoded server-to-client TTS audio frame.
class TtsAudioFrame {
  const TtsAudioFrame({
    required this.utteranceId,
    required this.chunkIndex,
    required this.payload,
  });

  final int utteranceId;
  final int chunkIndex;

  /// audio/mpeg bytes for this chunk (a view, not a copy).
  final Uint8List payload;
}

/// Decodes a binary frame. Returns null if it is too short or not a v1
/// TTS-audio frame, so a stray or future binary kind is ignored rather
/// than crashing the call.
TtsAudioFrame? decodeTtsAudioFrame(Uint8List data) {
  if (data.length < kBrokerBinaryHeaderBytes) return null;
  final view = ByteData.sublistView(data);
  if (view.getUint8(0) != kBrokerProtocolVersion) return null;
  if (view.getUint8(1) != kBrokerBinaryKindTtsAudio) return null;
  return TtsAudioFrame(
    utteranceId: view.getUint16(2, Endian.little),
    chunkIndex: view.getUint32(4, Endian.little),
    payload: Uint8List.sublistView(data, kBrokerBinaryHeaderBytes),
  );
}
