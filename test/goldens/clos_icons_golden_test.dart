@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  const icons = <String, Widget>{
    'dashboard': DashboardIcon(),
    'simulations': SimulationsIcon(),
    'progress': ProgressIcon(),
    'methodologies': MethodologiesIcon(),
    'achievements': AchievementsIcon(),
    'settings': SettingsIcon(),
    'mail': MailIcon(),
  };

  Widget row(Color color, double size) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final icon in icons.values)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconTheme.merge(
                data: IconThemeData(color: color, size: size),
                child: icon,
              ),
            ),
        ],
      );

  goldenTest(
    'Closero icon set',
    fileName: 'clos_icons',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'inactive dim2, 15px',
          child: onBase(child: row(ClosColors.bone.dim2, 15)),
        ),
        GoldenTestScenario(
          name: 'active hi2, 15px',
          child: onBase(child: row(ClosColors.bone.hi2, 15)),
        ),
        GoldenTestScenario(
          name: 'hi2, 30px',
          child: onBase(child: row(ClosColors.bone.hi2, 30)),
        ),
      ],
    ),
  );

  goldenTest(
    'Closero brand mark',
    fileName: 'closero_mark',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'default 18px accentDim',
          child: onBase(child: const CloseroMark()),
        ),
        GoldenTestScenario(
          name: '64px, geometry check',
          child: onBase(child: const CloseroMark(size: 64)),
        ),
      ],
    ),
  );
}
