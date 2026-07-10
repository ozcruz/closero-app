@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'DeltaPill',
    fileName: 'delta_pill',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'up',
          child: onBase(
            child: const DeltaPill(delta: 8, sessionNumber: 12),
          ),
        ),
        GoldenTestScenario(
          name: 'down',
          child: onBase(
            child: const DeltaPill(delta: -3, sessionNumber: 12),
          ),
        ),
        GoldenTestScenario(
          name: 'no change',
          child: onBase(
            child: const DeltaPill(delta: 0, sessionNumber: 12),
          ),
        ),
        GoldenTestScenario(
          name: 'rolling average label, session 10 plus',
          child: onBase(
            child: const DeltaPill(
              delta: 6,
              sessionNumber: 47,
              unit: 'pts',
              showComparisonLabel: true,
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'last session label, sessions 1 to 9',
          child: onBase(
            child: const DeltaPill(
              delta: 6,
              sessionNumber: 4,
              unit: 'pts',
              showComparisonLabel: true,
            ),
          ),
        ),
      ],
    ),
  );
}
