@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

const _series = [
  52.0, 54.0, 53.0, 56.0, 55.0, 58.0, 57.0, 60.0, 62.0, 61.0, 64.0,
];

void main() {
  goldenTest(
    'SparkLine',
    fileName: 'spark_line',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'line (default dim1)',
          child: onBase(
            child: const SizedBox(
              width: 280,
              height: 48,
              child: SparkLine(values: _series),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'filled trend',
          child: onBase(
            child: Builder(
              builder: (context) => SizedBox(
                width: 280,
                height: 72,
                child: SparkLine(
                  values: _series,
                  color: context.closColors.hi2,
                  fill: true,
                ),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'flat series',
          child: onBase(
            child: const SizedBox(
              width: 280,
              height: 48,
              child: SparkLine(values: [60, 60, 60, 60]),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'too few points renders empty, never broken',
          child: onBase(
            child: const SizedBox(
              width: 280,
              height: 48,
              child: SparkLine(values: [60]),
            ),
          ),
        ),
      ],
    ),
  );
}
