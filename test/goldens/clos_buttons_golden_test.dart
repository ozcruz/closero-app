import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'PrimaryButton states',
    fileName: 'primary_button',
    // Fixed pump count: the loading spinner never settles.
    pumpBeforeTest: pumpNTimes(2, const Duration(milliseconds: 300)),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'default',
          child: onBase(
            child: PrimaryButton(label: 'Start session', onPressed: () {}),
          ),
        ),
        GoldenTestScenario(
          name: 'with icon',
          child: onBase(
            child: PrimaryButton(
              label: 'Start session',
              icon: const Icon(Icons.play_arrow),
              onPressed: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'medium',
          child: onBase(
            child: PrimaryButton(
              label: 'Save changes',
              size: ClosButtonSize.medium,
              onPressed: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'disabled',
          child: onBase(child: const PrimaryButton(label: 'Start session')),
        ),
        GoldenTestScenario(
          name: 'loading',
          child: onBase(
            child: PrimaryButton(
              label: 'Start session',
              loading: true,
              onPressed: () {},
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'PrimaryButton hover lift',
    fileName: 'primary_button_hover',
    whilePerforming: hover(find.byType(PrimaryButton)),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'hover',
          child: onBase(
            child: PrimaryButton(label: 'Start session', onPressed: () {}),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'PrimaryButton pressed',
    fileName: 'primary_button_pressed',
    whilePerforming: press(find.byType(PrimaryButton)),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'pressed',
          child: onBase(
            child: PrimaryButton(label: 'Start session', onPressed: () {}),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'GhostButton states',
    fileName: 'ghost_button',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'default',
          child: onBase(
            child: GhostButton(label: 'Preview scenario', onPressed: () {}),
          ),
        ),
        GoldenTestScenario(
          name: 'medium',
          child: onBase(
            child: GhostButton(
              label: 'Cancel',
              size: ClosButtonSize.medium,
              onPressed: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'disabled',
          child: onBase(child: const GhostButton(label: 'Preview scenario')),
        ),
      ],
    ),
  );

  goldenTest(
    'GhostButton hover',
    fileName: 'ghost_button_hover',
    whilePerforming: hover(find.byType(GhostButton)),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'hover',
          child: onBase(
            child: GhostButton(label: 'Preview scenario', onPressed: () {}),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'DestructiveButton states',
    fileName: 'destructive_button',
    pumpBeforeTest: pumpNTimes(2, const Duration(milliseconds: 300)),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'default',
          child: onBase(
            child: DestructiveButton(
              label: 'Permanently delete account',
              onPressed: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'disabled',
          child: onBase(
            child: const DestructiveButton(label: 'Permanently delete account'),
          ),
        ),
        GoldenTestScenario(
          name: 'loading',
          child: onBase(
            child: DestructiveButton(
              label: 'Permanently delete account',
              loading: true,
              onPressed: () {},
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'DestructiveButton hover',
    fileName: 'destructive_button_hover',
    whilePerforming: hover(find.byType(DestructiveButton)),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'hover',
          child: onBase(
            child: DestructiveButton(
              label: 'Permanently delete account',
              onPressed: () {},
            ),
          ),
        ),
      ],
    ),
  );
}
