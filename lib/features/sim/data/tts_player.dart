/// Buffered per-utterance TTS playback for the live pipeline.
///
/// just_audio on web cannot stream progressively from bytes, so each
/// utterance's chunks are buffered and playback starts at `utteranceEnd`
/// via a data-URI source (broker PROTOCOL.md, "Playback on Flutter
/// web"). Utterances play back to back in utteranceId order. The player
/// hands the session each utterance's playback-position stream so visemes
/// schedule against real playback, never arrival time.
///
/// Abstracted as a base class so [LiveSimSession] runs against a fake in
/// tests; the callback fields are wired by the session.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'broker_protocol.dart' show PlaybackPosition;

abstract class TtsPlayer {
  /// An utterance became audible: [position] is its just_audio playback
  /// clock, for viseme scheduling and the output envelope.
  void Function(int utteranceId, Stream<Duration> position)? onPlaying;

  /// An utterance finished playing locally (send `played`, drop visemes).
  void Function(int utteranceId)? onComplete;

  /// Playback fully drained: nothing audible (rest the avatar, envelope 0).
  void Function()? onIdle;

  /// utteranceStart: open a buffer for this id.
  void beginUtterance(int utteranceId);

  /// A binary chunk for an utterance (chunks arrive in order per id).
  void addChunk(int utteranceId, int chunkIndex, Uint8List payload);

  /// utteranceEnd: the buffer is complete, enqueue it for playback.
  void endUtterance(int utteranceId);

  /// utteranceAbort: discard a failed utterance's buffer, never play it.
  void abortUtterance(int utteranceId);

  /// Stop audible playback right now without discarding buffers, and
  /// hold the queue. Used the moment the client SENDS a `cancel`, before
  /// the broker's `interrupted` names the flush point.
  void stopCurrent();

  /// Barge-in flush: stop playback and discard every buffered/queued
  /// utterance with id >= [fromUtteranceId] (broker `interrupted`).
  void interruptFrom(int fromUtteranceId);

  /// The currently audible utterance and position, or null if idle.
  /// Read at the moment of a cancel to make truncation honest.
  PlaybackPosition? get playing;

  Future<void> dispose();
}

class _Buffer {
  final BytesBuilder bytes = BytesBuilder(copy: false);
  bool ready = false;
}

/// just_audio implementation. One [AudioPlayer], one utterance at a time.
class JustAudioTtsPlayer extends TtsPlayer {
  JustAudioTtsPlayer({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  final Map<int, _Buffer> _buffers = {};
  final List<int> _queue = [];

  int? _currentId;

  /// True between a stopCurrent/interrupt and the queue being cleared,
  /// so a queued utterance never auto-starts mid-barge-in.
  bool _suppressed = false;
  bool _disposed = false;

  /// Bumped on every stop/interrupt so a start racing an await bails.
  int _generation = 0;

  StreamSubscription<ProcessingState>? _stateSub;

  @override
  PlaybackPosition? get playing {
    final id = _currentId;
    if (id == null) return null;
    return PlaybackPosition(
      utteranceId: id,
      positionMs: _player.position.inMilliseconds,
    );
  }

  @override
  void beginUtterance(int utteranceId) {
    if (_disposed) return;
    _buffers.putIfAbsent(utteranceId, _Buffer.new);
  }

  @override
  void addChunk(int utteranceId, int chunkIndex, Uint8List payload) {
    if (_disposed) return;
    final buffer = _buffers.putIfAbsent(utteranceId, _Buffer.new);
    buffer.bytes.add(payload);
  }

  @override
  void endUtterance(int utteranceId) {
    if (_disposed) return;
    final buffer = _buffers[utteranceId];
    if (buffer == null) return;
    buffer.ready = true;
    _queue.add(utteranceId);
    _maybeStartNext();
  }

  @override
  void abortUtterance(int utteranceId) {
    if (_disposed) return;
    _buffers.remove(utteranceId);
    _queue.remove(utteranceId);
  }

  @override
  void stopCurrent() {
    if (_disposed) return;
    _generation++;
    _suppressed = true;
    _currentId = null;
    unawaited(_player.stop());
  }

  @override
  void interruptFrom(int fromUtteranceId) {
    if (_disposed) return;
    _generation++;
    _currentId = null;
    unawaited(_player.stop());
    _queue.removeWhere((id) => id >= fromUtteranceId);
    _buffers.removeWhere((id, _) => id >= fromUtteranceId);
    // Release the hold: anything left in the queue is from a prior,
    // fully-heard reply and should not exist, but drain safely.
    _suppressed = false;
    if (_queue.isEmpty) {
      onIdle?.call();
    } else {
      _maybeStartNext();
    }
  }

  void _maybeStartNext() {
    if (_disposed || _suppressed || _currentId != null) return;
    if (_queue.isEmpty) return;
    final id = _queue.removeAt(0);
    final buffer = _buffers[id];
    if (buffer == null || !buffer.ready) return;
    _currentId = id;
    unawaited(_startPlayback(id, buffer));
  }

  Future<void> _startPlayback(int id, _Buffer buffer) async {
    final generation = _generation;
    final bytes = buffer.bytes.toBytes();
    final dataUri = 'data:audio/mpeg;base64,${base64Encode(bytes)}';
    try {
      // NOTE: web uses a data URI; the iOS target will need a temp-file
      // source since AVPlayer does not take data: URIs.
      await _player.setAudioSource(AudioSource.uri(Uri.parse(dataUri)));
    } on Object catch (error) {
      debugPrint('JustAudioTtsPlayer: setAudioSource failed ($error)');
      _finishCurrent(id, completed: false);
      return;
    }
    if (_disposed || generation != _generation || _currentId != id) return;

    final position = _player.createPositionStream(
      minPeriod: const Duration(milliseconds: 16),
      maxPeriod: const Duration(milliseconds: 33),
    );
    onPlaying?.call(id, position);

    await _stateSub?.cancel();
    _stateSub = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && _currentId == id) {
        _finishCurrent(id, completed: true);
      }
    });

    await _player.play();
  }

  void _finishCurrent(int id, {required bool completed}) {
    if (_currentId != id) return;
    _currentId = null;
    _buffers.remove(id);
    _stateSub?.cancel();
    _stateSub = null;
    if (completed) onComplete?.call(id);
    if (_queue.isEmpty) {
      onIdle?.call();
    } else {
      _maybeStartNext();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _buffers.clear();
    _queue.clear();
    await _stateSub?.cancel();
    await _player.dispose();
  }
}
