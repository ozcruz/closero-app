@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/routing/app_shell.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:closero_app/features/dashboard/data/dashboard_repository.dart';
import 'package:closero_app/features/dashboard/presentation/dashboard_screen.dart';
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

  /// The full shell at a real viewport size, on a fixed morning clock
  /// so the greeting is deterministic.
  Widget dashboard({required double width, required double height}) {
    SharedPreferences.setMockInitialValues({});
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        userDocProvider.overrideWith((ref) => Stream.value(osman)),
        clockProvider.overrideWithValue(() => DateTime(2026, 7, 10, 9)),
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
            currentPath: '/',
            child: DashboardScreen(),
          ),
        ),
      ),
    );
  }

  goldenTest(
    'Dashboard',
    fileName: 'dashboard',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'canonical mock data, expanded sidebar',
          child: dashboard(width: 1440, height: 1380),
        ),
        GoldenTestScenario(
          name: 'narrow: collapsed rail, stacked cards',
          child: dashboard(width: 960, height: 1720),
        ),
      ],
    ),
  );
}
