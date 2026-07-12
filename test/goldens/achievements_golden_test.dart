@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/routing/app_shell.dart';
import 'package:closero_app/features/achievements/data/achievements_repository.dart';
import 'package:closero_app/features/achievements/presentation/achievements_screen.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const osman = UserDoc(
    uid: 'uid-1',
    email: 'osman@company.com',
    displayName: 'Osman Cruz',
    entitlement: Entitlement.closer,
    sessionsUsed: 12,
    usageMonth: '2026-07',
  );

  /// The full shell at a real viewport size (13-achievements.png /
  /// 14-achievements-empty.png).
  Widget achievements({
    required double width,
    required double height,
    bool empty = false,
  }) {
    SharedPreferences.setMockInitialValues({});
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        userDocProvider.overrideWith((ref) => Stream.value(osman)),
        achievementsRepositoryProvider
            .overrideWithValue(FixtureAchievementsRepository(empty: empty)),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          disableAnimations: true,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: const AppShell(
            currentPath: '/achievements',
            child: AchievementsScreen(),
          ),
        ),
      ),
    );
  }

  goldenTest(
    'Achievements',
    fileName: 'achievements',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'canonical mock data, 7 of 16 unlocked',
          child: achievements(width: 1440, height: 2260),
        ),
        GoldenTestScenario(
          name: 'session zero: entry figure, get-started plan',
          child: achievements(width: 1440, height: 2160, empty: true),
        ),
      ],
    ),
  );
}
