@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'StreakPill',
    fileName: 'streak_pill',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'canonical streak',
          child: onBase(child: const StreakPill(days: 9)),
        ),
        GoldenTestScenario(
          name: 'single day',
          child: onBase(child: const StreakPill(days: 1)),
        ),
      ],
    ),
  );
}
