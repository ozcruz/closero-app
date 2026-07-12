@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'ClosBadge',
    fileName: 'clos_badge',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'plain',
          child: onBase(child: const ClosBadge(label: 'Sandler Method')),
        ),
        GoldenTestScenario(
          name: 'status dot (complete)',
          child: onBase(
            child: Builder(
              builder: (context) => ClosBadge(
                label: 'Session complete',
                dotColor: context.closColors.green,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
