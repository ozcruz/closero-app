@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'IncomeTrack',
    fileName: 'income_track',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'canonical range with labels',
          child: onBase(
            child: const SizedBox(
              width: 360,
              child: IncomeTrack(
                progress: 0.22,
                startLabel: r'$40K entry',
                endLabel: r'$150K top performer',
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'bare track',
          child: onBase(
            child: const SizedBox(
              width: 360,
              child: IncomeTrack(progress: 0.8),
            ),
          ),
        ),
      ],
    ),
  );
}
