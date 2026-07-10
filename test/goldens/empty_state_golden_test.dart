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
    'EmptyState',
    fileName: 'empty_state',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'with primary CTA',
          child: onBase(
            child: SizedBox(
              width: 520,
              child: EmptyState(
                icon: const BarsIcon(),
                title: 'Your progress will show up here',
                body: 'Complete a session and this page turns into your '
                    'dashboard for tracking skill growth, scores, and '
                    'session history over time.',
                action: PrimaryButton(
                  label: 'Start a session',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'copy only',
          child: onBase(
            child: const SizedBox(
              width: 520,
              child: EmptyState(
                icon: BarsIcon(),
                title: 'Nothing here yet',
                body: 'Sessions you complete will appear in this list.',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
