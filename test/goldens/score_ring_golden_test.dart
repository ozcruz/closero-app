@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'ScoreRing',
    fileName: 'score_ring',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'high, hi2 at 75 plus',
          child: onBase(
            child: const ScoreRing(score: 78, label: 'Overall'),
          ),
        ),
        GoldenTestScenario(
          name: 'mid, 60 to 74',
          child: onBase(child: const ScoreRing(score: 71)),
        ),
        GoldenTestScenario(
          name: 'low, dim1 below 60',
          child: onBase(child: const ScoreRing(score: 45)),
        ),
        GoldenTestScenario(
          name: 'small variant',
          child: onBase(
            child: const ScoreRing(score: 76, size: 64, strokeWidth: 4),
          ),
        ),
      ],
    ),
  );
}
