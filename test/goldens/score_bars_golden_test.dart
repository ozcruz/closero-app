@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'ScoreBars',
    fileName: 'score_bars',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'threshold colors across the ramp',
          child: onBase(
            child: const SizedBox(
              width: 420,
              height: 140,
              child: ScoreBars(
                scores: [45, 52, 48, 61, 58, 66, 63, 71, 75, 68, 77, 61, 84],
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'few sessions, wide bars capped',
          child: onBase(
            child: const SizedBox(
              width: 420,
              height: 140,
              child: ScoreBars(scores: [58, 77, 61, 84]),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'dense all-time range',
          child: onBase(
            child: SizedBox(
              width: 420,
              height: 140,
              child: ScoreBars(
                scores: [for (var i = 0; i < 47; i++) 42 + (i * 13) % 47],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
