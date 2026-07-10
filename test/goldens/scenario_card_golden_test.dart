@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'ScenarioCard',
    fileName: 'scenario_card',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'start',
          child: onBase(
            child: SizedBox(
              width: 260,
              child: ScenarioCard(
                name: 'Marisol',
                description: 'Price-shopping three quotes side by side',
                duration: '~16 min',
                difficulty: 'Hard',
                initials: 'MG',
                tint: AvatarArtTint.violet,
                onTap: () {},
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'personal best',
          child: onBase(
            child: SizedBox(
              width: 260,
              child: ScenarioCard(
                name: 'Walter',
                description: 'Warm but wanders, hard to bring to close',
                duration: '~11 min',
                difficulty: 'Medium',
                initials: 'WB',
                tint: AvatarArtTint.umber,
                status: ScenarioCardStatus.personalBest,
                bestScore: 81,
                onTap: () {},
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'in progress',
          child: onBase(
            child: SizedBox(
              width: 260,
              child: ScenarioCard(
                name: 'The Coopers',
                description: 'Just sat down to dinner, door knock',
                duration: '~14 min',
                difficulty: 'Medium',
                initials: 'TC',
                tint: AvatarArtTint.umber,
                status: ScenarioCardStatus.inProgress,
                onTap: () {},
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'locked',
          child: onBase(
            child: SizedBox(
              width: 260,
              child: ScenarioCard(
                name: 'Denise',
                description: 'Skeptical homeowner, 3rd pitch today',
                duration: '~12 min',
                difficulty: 'Hard',
                initials: 'DW',
                tint: AvatarArtTint.violet,
                status: ScenarioCardStatus.locked,
                onTap: () {},
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
