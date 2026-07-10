@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'HintCard',
    fileName: 'hint_card',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'good, live coaching',
          child: onBase(
            child: const SizedBox(
              width: 320,
              child: HintCard(
                kind: HintKind.good,
                label: 'Rapport',
                body: 'Used her name, good start',
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'warn, live coaching',
          child: onBase(
            child: const SizedBox(
              width: 320,
              child: HintCard(
                kind: HintKind.warn,
                label: 'Tonality',
                body: 'Sentences ending on an uptick',
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'miss, key moment with title and timestamp',
          child: onBase(
            child: const SizedBox(
              width: 480,
              child: HintCard(
                kind: HintKind.miss,
                label: 'Missed',
                title: 'Dropped tonality on the budget objection.',
                body: 'Your pitch rose at "is that a concern?" and sounds '
                    'like asking for permission. Same words, flatter '
                    'delivery changes the frame entirely.',
                timestamp: '9:07',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
