@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  Widget strip({required int selectedIndex, ValueChanged<int>? onChanged}) =>
      onBase(
        child: SizedBox(
          width: 300,
          child: ClosTabs(
            tabs: const [
              ClosTab(label: 'Coaching'),
              ClosTab(label: 'Transcript', count: 5),
            ],
            selectedIndex: selectedIndex,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      );

  goldenTest(
    'ClosTabs',
    fileName: 'clos_tabs',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'first selected with count badge',
          child: strip(selectedIndex: 0),
        ),
        GoldenTestScenario(
          name: 'second selected',
          child: strip(selectedIndex: 1),
        ),
        GoldenTestScenario(
          name: 'disabled',
          child: onBase(
            child: const SizedBox(
              width: 300,
              child: ClosTabs(
                tabs: [
                  ClosTab(label: 'Coaching'),
                  ClosTab(label: 'Transcript', count: 12),
                ],
                selectedIndex: 0,
                onChanged: null,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
