import 'package:closero_app/core/services/viseme_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every Azure viseme ID per the rive contract table', () {
    const expected = {
      0: MouthGroup.rest, // silence
      1: MouthGroup.aa, // ae, ax, ah
      2: MouthGroup.aa, // aa
      3: MouthGroup.oo, // ao
      4: MouthGroup.ee, // eh, uh
      5: MouthGroup.ee, // er
      6: MouthGroup.ee, // iy, ih, ix
      7: MouthGroup.oo, // w, uw
      8: MouthGroup.oo, // ow
      9: MouthGroup.aa, // aw
      10: MouthGroup.oo, // oy
      11: MouthGroup.aa, // ay
      12: MouthGroup.aa, // h
      13: MouthGroup.oo, // r
      14: MouthGroup.ll, // l
      15: MouthGroup.ss, // s, z
      16: MouthGroup.ss, // sh, ch, jh, zh
      17: MouthGroup.ll, // dh
      18: MouthGroup.ff, // f, v
      19: MouthGroup.ll, // d, t, n, th
      20: MouthGroup.aa, // k, g, ng
      21: MouthGroup.mm, // p, b, m
    };
    for (final entry in expected.entries) {
      expect(
        mouthGroupForAzureViseme(entry.key),
        entry.value,
        reason: 'Azure viseme ${entry.key}',
      );
    }
  });

  test('mouth group values match the locked AvatarVM.viseme contract', () {
    expect(MouthGroup.rest, 0);
    expect(MouthGroup.aa, 1);
    expect(MouthGroup.ee, 2);
    expect(MouthGroup.mm, 3);
    expect(MouthGroup.ff, 4);
    expect(MouthGroup.oo, 5);
    expect(MouthGroup.ll, 6);
    expect(MouthGroup.ss, 7);
  });

  test('unknown IDs relax to rest instead of crashing', () {
    expect(mouthGroupForAzureViseme(-1), MouthGroup.rest);
    expect(mouthGroupForAzureViseme(22), MouthGroup.rest);
    expect(mouthGroupForAzureViseme(999), MouthGroup.rest);
  });
}
