/// Microphone capture for the live pipeline: raw PCM16 little-endian,
/// mono, 16 kHz, streamed for the WHOLE call (barge-in needs the mic up
/// while the persona speaks). Capture uses echo cancellation, without
/// which the persona's own voice returns as rep speech (broker
/// PROTOCOL.md). Abstracted so [LiveSimSession] runs against a fake.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import 'broker_protocol.dart' show kBrokerMicSampleRateHz;

/// A live-or-fake mic. [start] resolves to the PCM chunk stream.
abstract interface class MicSource {
  /// True when the browser/OS has granted microphone permission.
  Future<bool> hasPermission();

  /// Begins capture and returns the PCM16LE mono 16 kHz chunk stream.
  Future<Stream<Uint8List>> start();

  /// Stops capture. Safe to call more than once.
  Future<void> stop();

  Future<void> dispose();
}

/// Root-mean-square level of a PCM16LE buffer, normalized to 0..1 with a
/// mild gain so ordinary speech reads in the upper half. Used for the
/// local input envelope and the client VAD; never sent on the wire.
double pcm16Rms(Uint8List pcm) {
  final samples = pcm.lengthInBytes ~/ 2;
  if (samples == 0) return 0;
  final view = ByteData.sublistView(pcm);
  var sumSquares = 0.0;
  for (var i = 0; i < samples; i++) {
    final s = view.getInt16(i * 2, Endian.little) / 32768.0;
    sumSquares += s * s;
  }
  final rms = math.sqrt(sumSquares / samples);
  // ~3x gain: quiet room ~0.0, conversational speech ~0.3-0.9.
  return (rms * 3).clamp(0.0, 1.0);
}

/// The `record` plugin backing. On web it captures PCM16 via an
/// AudioWorklet (supported in Chrome, Firefox, Safari) and resamples to
/// the requested rate; verify the delivered rate on real browsers.
class RecordMicSource implements MicSource {
  RecordMicSource({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  static const RecordConfig _config = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: kBrokerMicSampleRateHz,
    numChannels: 1,
    // AEC is mandatory: the mic runs during persona playback.
    echoCancel: true,
    noiseSuppress: true,
    autoGain: true,
  );

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> start() => _recorder.startStream(_config);

  @override
  Future<void> stop() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  @override
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
