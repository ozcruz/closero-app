@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'StatStrip',
    fileName: 'stat_strip',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'post-call stats (five cells)',
          child: onBase(
            child: const SizedBox(
              width: 960,
              child: StatStrip(
                items: [
                  StatStripItem(value: '14:32', label: 'Duration'),
                  StatStripItem(value: '43%', label: 'Your talk time'),
                  StatStripItem(value: '9', label: 'Questions asked'),
                  StatStripItem(value: '2.1', label: 'Fillers per min'),
                  StatStripItem(value: '48s', label: 'Longest monologue'),
                ],
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'narrow (labels wrap, cells stay equal)',
          child: onBase(
            child: const SizedBox(
              width: 480,
              child: StatStrip(
                items: [
                  StatStripItem(value: '14:32', label: 'Duration'),
                  StatStripItem(value: '43%', label: 'Your talk time'),
                  StatStripItem(value: '9', label: 'Questions asked'),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
