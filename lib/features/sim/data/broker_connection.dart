/// The one WebSocket per granted sim session, abstracted so
/// [LiveSimSession] can be driven by a fake in tests. Frames are the
/// raw wire units: a text frame is a String (JSON), a binary frame is a
/// Uint8List (a TTS audio chunk with its 8-byte header).
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

/// A live-or-fake transport to the broker.
abstract interface class BrokerConnection {
  /// Resolves when the socket is open (or throws if it never opens).
  Future<void> get ready;

  /// Incoming frames: `String` (JSON text) or `Uint8List` (binary).
  /// Closes when the socket closes.
  Stream<Object> get frames;

  /// The close code once [frames] has closed, else null.
  int? get closeCode;

  void sendText(String text);

  void sendBinary(Uint8List bytes);

  /// Closes the socket. [code] defaults to a normal 1000.
  Future<void> close([int? code, String? reason]);
}

/// Opens `wss://<host>/v1/session/{requestId}` via web_socket_channel
/// (HtmlWebSocketChannel on web, delivering binary as Uint8List).
class WebSocketBrokerConnection implements BrokerConnection {
  WebSocketBrokerConnection(Uri uri)
      : _channel = WebSocketChannel.connect(uri) {
    _frames = _channel.stream.map<Object>(_normalizeFrame).asBroadcastStream();
  }

  final WebSocketChannel _channel;
  late final Stream<Object> _frames;

  static Object _normalizeFrame(Object? event) {
    if (event is String) return event;
    if (event is Uint8List) return event;
    if (event is TypedData) {
      return Uint8List.view(
        event.buffer,
        event.offsetInBytes,
        event.lengthInBytes,
      );
    }
    if (event is List<int>) return Uint8List.fromList(event);
    // Unknown frame kind: hand back an empty binary so the session's
    // decoder ignores it rather than the stream carrying a stray type.
    return Uint8List(0);
  }

  @override
  Future<void> get ready => _channel.ready;

  @override
  Stream<Object> get frames => _frames;

  @override
  int? get closeCode => _channel.closeCode;

  @override
  void sendText(String text) => _channel.sink.add(text);

  @override
  void sendBinary(Uint8List bytes) => _channel.sink.add(bytes);

  @override
  Future<void> close([int? code, String? reason]) =>
      _channel.sink.close(code ?? ws_status.normalClosure, reason);
}
