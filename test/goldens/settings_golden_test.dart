@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/routing/app_shell.dart';
import 'package:closero_app/core/services/auth_service.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:closero_app/features/settings/presentation/change_password_screen.dart';
import 'package:closero_app/features/settings/presentation/connected_accounts_screen.dart';
import 'package:closero_app/features/settings/presentation/delete_account_screen.dart';
import 'package:closero_app/features/settings/presentation/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth_service.dart';

void main() {
  UserDoc user(Entitlement entitlement) => UserDoc(
        uid: 'uid-1',
        email: 'osman@company.com',
        displayName: 'Osman Cruz',
        entitlement: entitlement,
        sessionsUsed: 3,
        usageMonth: '2026-07',
      );

  Widget shell(
    Widget screen, {
    required String path,
    Entitlement entitlement = Entitlement.closer,
    double width = 1440,
    double height = 1560,
  }) {
    SharedPreferences.setMockInitialValues({});
    final auth = FakeAuthService()
      ..providers = [
        const LinkedProvider(
          providerId: 'password',
          email: 'osman@company.com',
        ),
        const LinkedProvider(
          providerId: 'google.com',
          email: 'osman@company.com',
        ),
      ];
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        userDocProvider.overrideWith((ref) => Stream.value(user(entitlement))),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          disableAnimations: true,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: AppShell(currentPath: path, child: screen),
        ),
      ),
    );
  }

  goldenTest(
    'Settings',
    fileName: 'settings',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'Closer plan (15-settings.png)',
          child: shell(const SettingsScreen(), path: '/settings'),
        ),
        GoldenTestScenario(
          name: 'free plan: usage line, accent Upgrade',
          child: shell(
            const SettingsScreen(),
            path: '/settings',
            entitlement: Entitlement.free,
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'Settings sub-pages',
    fileName: 'settings_subpages',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'change password (19)',
          child: shell(
            const ChangePasswordScreen(),
            path: '/settings/password',
            height: 1100,
          ),
        ),
        GoldenTestScenario(
          name: 'connected accounts (20)',
          child: shell(
            const ConnectedAccountsScreen(),
            path: '/settings/connected',
            height: 900,
          ),
        ),
        GoldenTestScenario(
          name: 'delete account (21)',
          child: shell(
            const DeleteAccountScreen(),
            path: '/settings/delete',
            height: 1200,
          ),
        ),
      ],
    ),
  );
}
