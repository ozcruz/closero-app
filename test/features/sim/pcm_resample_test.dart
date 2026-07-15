import 'dart:typed_data';

import 'package:closero_app/features/sim/data/pcm_resample.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _pcm(List<int> samples) {
  final data = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(i * 2, samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

List<int> _samples(Uint8List bytes) {
  final view = ByteData.sublistView(bytes);
  return [
    for (var i = 0; i < bytes.lengthInBytes ~/ 2; i++)
      view.getInt16(i * 2, Endian.little),
  ];
}

void main() {
  test('equal rates return the input untouched', () {
    final input = _pcm([1, 2, 3, 4]);
    final out = resamplePcm16Mono(input, fromRate: 16000, toRate: 16000);
    expect(identical(out, input), isTrue);
  });

  test('48k to 16k keeps roughly a third of the samples', () {
    final input = _pcm(List<int>.filled(48, 1000));
    final out = resamplePcm16Mono(input, fromRate: 48000, toRate: 16000);
    // floor(48 * 16000/48000) = 16 samples.
    expect(_samples(out), hasLength(16));
  });

  test('silence stays silence', () {
    final input = _pcm(List<int>.filled(48, 0));
    final out = resamplePcm16Mono(input, fromRate: 48000, toRate: 16000);
    expect(_samples(out).every((s) => s == 0), isTrue);
  });

  test('a steady tone keeps its amplitude within the sample range', () {
    final input = _pcm(List<int>.filled(96, 20000));
    final out = resamplePcm16Mono(input, fromRate: 48000, toRate: 16000);
    // Linear interpolation of a constant is that constant.
    expect(_samples(out).every((s) => s == 20000), isTrue);
    expect(_samples(out), hasLength(32));
  });

  test('empty and degenerate inputs never throw', () {
    expect(_samples(resamplePcm16Mono(Uint8List(0), fromRate: 48000, toRate: 16000)),
        isEmpty);
    final tiny = _pcm([500]);
    expect(
      _samples(resamplePcm16Mono(tiny, fromRate: 48000, toRate: 16000)),
      isEmpty,
    );
    // A zero rate is ignored rather than dividing by zero.
    final input = _pcm([1, 2]);
    expect(identical(resamplePcm16Mono(input, fromRate: 0, toRate: 16000), input),
        isTrue);
  });
}
