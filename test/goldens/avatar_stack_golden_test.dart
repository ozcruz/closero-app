@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

// The Rive layer is exercised in Session 12 with a real rig; these
// goldens lock the permanent placeholder, which is also the loading
// state and the failure fallback.
void main() {
  goldenTest(
    'AvatarStack',
    fileName: 'avatar_stack',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'placeholder with initials',
          child: onBase(
            child: const SizedBox(
              width: 240,
              height: 180,
              child: AvatarStack(
                initials: 'SV',
                semanticLabel: 'Sandra Voss, AI persona',
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'moss tint',
          child: onBase(
            child: const SizedBox(
              width: 240,
              height: 180,
              child: AvatarStack(initials: 'RH', tint: AvatarArtTint.moss),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'circle crop, live sim stage',
          child: onBase(
            child: const ClipOval(
              child: SizedBox(
                width: 160,
                height: 160,
                child: AvatarStack(initials: 'SE'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
