/// Generates assets/audio/lipsync_demo.wav, the bundled test clip for
/// the avatar rig demo (AVATAR_RIG_DEMO flag on the Video Sim stage).
///
/// The clip is five sine beeps separated by silence; the canned viseme
/// timeline in avatar_rig_demo.dart opens the mouth exactly at each
/// beep's start and rests it at each beep's end, so lipsync drift is
/// visible by eye. Deterministic output: rerunning produces identical
/// bytes. Run: dart run tool/gen_lipsync_clip.dart
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sampleRate = 22050;
const double clipSeconds = 5.0;

/// (startMs, endMs, frequencyHz). Keep in step with kLipsyncDemoTimeline
/// in lib/features/sim/presentation/avatar_rig_demo.dart.
const List<(int, int, double)> segments = [
  (400, 900, 220),
  (1300, 1800, 140),
  (2200, 2700, 330),
  (3100, 3600, 180),
  (4000, 4600, 260),
];

void main() {
  final totalSamples = (sampleRate * clipSeconds).round();
  final samples = Int16List(totalSamples);

  for (final (startMs, endMs, freq) in segments) {
    final start = startMs * sampleRate ~/ 1000;
    final end = endMs * sampleRate ~/ 1000;
    const fade = 10 * sampleRate ~/ 1000;
    for (var i = start; i < end && i < totalSamples; i++) {
      final t = (i - start) / sampleRate;
      var amp = 0.4;
      if (i - start < fade) amp *= (i - start) / fade;
      if (end - i < fade) amp *= (end - i) / fade;
      samples[i] = (math.sin(2 * math.pi * freq * t) * amp * 32767).round();
    }
  }

  final dataBytes = samples.lengthInBytes;
  final header = BytesBuilder()
    ..add('RIFF'.codeUnits)
    ..add(_u32(36 + dataBytes))
    ..add('WAVE'.codeUnits)
    ..add('fmt '.codeUnits)
    ..add(_u32(16)) // PCM chunk size
    ..add(_u16(1)) // PCM format
    ..add(_u16(1)) // mono
    ..add(_u32(sampleRate))
    ..add(_u32(sampleRate * 2)) // byte rate
    ..add(_u16(2)) // block align
    ..add(_u16(16)) // bits per sample
    ..add('data'.codeUnits)
    ..add(_u32(dataBytes))
    ..add(samples.buffer.asUint8List());

  final out = File('assets/audio/lipsync_demo.wav')
    ..createSync(recursive: true)
    ..writeAsBytesSync(header.toBytes());
  stdout.writeln('wrote ${out.path} (${out.lengthSync()} bytes)');
}

Uint8List _u32(int value) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little);

Uint8List _u16(int value) =>
    Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.little);
