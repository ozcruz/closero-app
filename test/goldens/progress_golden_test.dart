@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/routing/app_shell.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:closero_app/features/progress/data/progress_repository.dart';
import 'package:closero_app/features/progress/presentation/progress_screen.dart';
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

  /// The full shell at a real viewport size (10-my-progress.png /
  /// 11-progress-empty.png).
  Widget progress({
    required double width,
    required double height,
    bool empty = false,
  }) {
    SharedPreferences.setMockInitialValues({});
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        userDocProvider.overrideWith((ref) => Stream.value(osman)),
        progressRepositoryProvider
            .overrideWithValue(FixtureProgressRepository(empty: empty)),
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
            currentPath: '/progress',
            child: ProgressScreen(),
          ),
        ),
      ),
    );
  }

  goldenTest(
    'My progress',
    fileName: 'progress',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'canonical mock data, 30D range',
          child: progress(width: 1440, height: 1900),
        ),
        GoldenTestScenario(
          name: 'session zero: one centered empty state',
          child: progress(width: 1440, height: 900, empty: true),
        ),
      ],
    ),
  );
}
