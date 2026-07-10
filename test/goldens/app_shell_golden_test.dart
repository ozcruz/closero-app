@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/routing/app_shell.dart';
import 'package:closero_app/core/routing/placeholder_screen.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const osman = UserDoc(
    uid: 'uid-1',
    email: 'osman@company.com',
    displayName: 'Osman',
    entitlement: Entitlement.closer,
    sessionsUsed: 12,
    usageMonth: '2026-07',
  );

  Widget shell({required double width, required double height}) =>
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          userDocProvider.overrideWith((ref) => Stream.value(osman)),
        ],
        // Real viewport size so the sidebar collapse breakpoint sees the
        // scenario's width, not the test window's.
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
              child: PlaceholderScreen(title: 'Dashboard'),
            ),
          ),
        ),
      );

  goldenTest(
    'App shell',
    fileName: 'app_shell',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'expanded sidebar, dashboard active',
          child: shell(width: 1280, height: 800),
        ),
        GoldenTestScenario(
          name: 'collapsed rail below the breakpoint',
          child: shell(width: 960, height: 700),
        ),
      ],
    ),
  );
}
