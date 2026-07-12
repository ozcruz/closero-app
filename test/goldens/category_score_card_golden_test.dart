@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'CategoryScoreCard',
    fileName: 'category_score_card',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'strong (hi2 bar), positive delta',
          child: onBase(
            child: const SizedBox(
              width: 280,
              child: CategoryScoreCard(
                label: 'Building rapport',
                score: 84,
                previousScore: 76,
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'developing (mid bar), small delta',
          child: onBase(
            child: const SizedBox(
              width: 280,
              child: CategoryScoreCard(
                label: 'Objection handling',
                score: 71,
                previousScore: 69,
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'focus area (dim1 bar), negative delta',
          child: onBase(
            child: const SizedBox(
              width: 280,
              child: CategoryScoreCard(
                label: 'Tonality and pacing',
                score: 61,
                previousScore: 64,
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'first session: no pill, no caption',
          child: onBase(
            child: const SizedBox(
              width: 280,
              child: CategoryScoreCard(
                label: 'Discovery questions',
                score: 55,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
