@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'ClosSegmented',
    fileName: 'clos_segmented',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'first selected',
          child: onBase(
            child: ClosSegmented(
              segments: const ['B2C', 'B2B'],
              selectedIndex: 0,
              onChanged: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'second selected',
          child: onBase(
            child: ClosSegmented(
              segments: const ['B2C', 'B2B'],
              selectedIndex: 1,
              onChanged: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'disabled',
          child: onBase(
            child: const ClosSegmented(
              segments: ['B2C', 'B2B'],
              selectedIndex: 0,
              onChanged: null,
            ),
          ),
        ),
      ],
    ),
  );
}
