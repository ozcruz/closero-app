/// Sample-rate correction for the mic path. Deepgram (broker STT) is
/// configured for 16 kHz, and the `record` plugin is asked for 16 kHz,
/// but browsers frequently ignore that constraint and capture at the
/// AudioContext's native rate (commonly 48 kHz). When a real-device
/// check shows a mismatch, this resamples each PCM16 chunk down to the
/// rate the broker expects before it ever hits the wire.
library;

import 'dart:typed_data';

/// Resamples interleaved PCM16 little-endian MONO audio from [fromRate]
/// to [toRate] with linear interpolation.
///
/// Returns [input] unchanged when the rates already match. Linear
/// interpolation is intentionally simple (no anti-alias low-pass): it is
/// cheap, allocation-light, and more than adequate for speech STT, which
/// is what this feeds. Each chunk is resampled independently, so a
/// sub-sample discontinuity can occur at chunk seams; inaudible to STT.
Uint8List resamplePcm16Mono(
  Uint8List input, {
  required int fromRate,
  required int toRate,
}) {
  if (fromRate <= 0 || toRate <= 0) return input;
  if (fromRate == toRate) return input;

  final inSamples = input.lengthInBytes ~/ 2;
  if (inSamples == 0) return Uint8List(0);

  final inView = ByteData.sublistView(input);
  final ratio = toRate / fromRate;
  final outSamples = (inSamples * ratio).floor();
  if (outSamples <= 0) return Uint8List(0);

  final out = ByteData(outSamples * 2);
  for (var i = 0; i < outSamples; i++) {
    final srcPos = i / ratio;
    final i0 = srcPos.floor();
    final i1 = (i0 + 1 < inSamples) ? i0 + 1 : i0;
    final frac = srcPos - i0;
    final s0 = inView.getInt16(i0 * 2, Endian.little);
    final s1 = inView.getInt16(i1 * 2, Endian.little);
    final interp = (s0 + (s1 - s0) * frac).round().clamp(-32768, 32767);
    out.setInt16(i * 2, interp, Endian.little);
  }
  return out.buffer.asUint8List();
}
