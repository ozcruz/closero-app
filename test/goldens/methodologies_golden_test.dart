@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/routing/app_shell.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:closero_app/features/methodologies/presentation/methodologies_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  /// The full shell at a real viewport size (12-methodologies.png).
  Widget methodologies({
    required double width,
    required double height,
    required Entitlement entitlement,
  }) {
    SharedPreferences.setMockInitialValues({});
    final doc = UserDoc(
      uid: 'uid-1',
      email: 'osman@company.com',
      displayName: 'Osman Cruz',
      entitlement: entitlement,
      sessionsUsed: 3,
      usageMonth: '2026-07',
    );
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        userDocProvider.overrideWith((ref) => Stream.value(doc)),
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
            currentPath: '/methodologies',
            child: MethodologiesScreen(),
          ),
        ),
      ),
    );
  }

  goldenTest(
    'Methodologies',
    fileName: 'methodologies',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'free: gate banner, blurred reference cards',
          child: methodologies(
            width: 1440,
            height: 2080,
            entitlement: Entitlement.free,
          ),
        ),
        GoldenTestScenario(
          name: 'closer: five reference cards, no gate',
          child: methodologies(
            width: 1440,
            height: 1960,
            entitlement: Entitlement.closer,
          ),
        ),
      ],
    ),
  );
}
