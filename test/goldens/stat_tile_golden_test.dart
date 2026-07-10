@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';
import 'test_icons.dart';

void main() {
  goldenTest(
    'StatTile',
    fileName: 'stat_tile',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'with icon',
          child: onBase(
            child: const SizedBox(
              width: 240,
              child: StatTile(
                value: '9 days',
                label: 'Current streak',
                icon: BarsIcon(),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'text only',
          child: onBase(
            child: const SizedBox(
              width: 240,
              child: StatTile(value: '11.2 hrs', label: 'Practice time'),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'loading skeleton',
          child: onBase(
            child: const SizedBox(
              width: 240,
              child: StatTile(
                value: '47',
                label: 'Total sessions',
                icon: BarsIcon(),
                loading: true,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
