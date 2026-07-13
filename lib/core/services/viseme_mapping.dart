/// Azure viseme ID to avatar mouth group, the ONLY place this mapping
/// exists (context/rive-contract.md). Azure Speech emits viseme IDs
/// 0 to 21 per utterance; the rig's `AvatarVM.viseme` Number property
/// selects one of eight mouth groups. Tune by eye here, never inline
/// a viseme map anywhere else.
library;

/// Mouth group values, exactly the `AvatarVM.viseme` values the rig
/// compares by equality. The production rig must keep these.
abstract final class MouthGroup {
  /// Silence / neutral.
  static const int rest = 0;

  /// Open vowels.
  static const int aa = 1;

  /// Spread vowels.
  static const int ee = 2;

  /// p, b, m (closed).
  static const int mm = 3;

  /// f, v (teeth on lip).
  static const int ff = 4;

  /// Rounded vowels, w.
  static const int oo = 5;

  /// l, and tongue-forward d/t/n/th.
  static const int ll = 6;

  /// s, z, sh, ch, j.
  static const int ss = 7;
}

/// Azure viseme ID (index 0 to 21) to mouth group.
const List<int> _azureToMouthGroup = [
  MouthGroup.rest, // 0  silence
  MouthGroup.aa, //   1  ae, ax, ah
  MouthGroup.aa, //   2  aa
  MouthGroup.oo, //   3  ao
  MouthGroup.ee, //   4  eh, uh
  MouthGroup.ee, //   5  er
  MouthGroup.ee, //   6  iy, ih, ix
  MouthGroup.oo, //   7  w, uw
  MouthGroup.oo, //   8  ow
  MouthGroup.aa, //   9  aw
  MouthGroup.oo, //  10  oy
  MouthGroup.aa, //  11  ay
  MouthGroup.aa, //  12  h
  MouthGroup.oo, //  13  r
  MouthGroup.ll, //  14  l
  MouthGroup.ss, //  15  s, z
  MouthGroup.ss, //  16  sh, ch, jh, zh
  MouthGroup.ll, //  17  dh
  MouthGroup.ff, //  18  f, v
  MouthGroup.ll, //  19  d, t, n, th
  MouthGroup.aa, //  20  k, g, ng
  MouthGroup.mm, //  21  p, b, m
];

/// Mouth group for an Azure viseme ID. Unknown IDs fall back to rest:
/// an unmapped sound should relax the mouth, never crash a call.
int mouthGroupForAzureViseme(int azureVisemeId) {
  if (azureVisemeId < 0 || azureVisemeId >= _azureToMouthGroup.length) {
    return MouthGroup.rest;
  }
  return _azureToMouthGroup[azureVisemeId];
}
