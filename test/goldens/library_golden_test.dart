@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/routing/app_shell.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:closero_app/features/library/domain/scenario.dart';
import 'package:closero_app/features/library/presentation/library_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserDoc user(Entitlement entitlement) => UserDoc(
        uid: 'uid-1',
        email: 'osman@company.com',
        displayName: 'Osman Cruz',
        entitlement: entitlement,
        sessionsUsed: 2,
        usageMonth: '2026-07',
      );

  /// The full shell at a real viewport size
  /// (context/prototype-screens/04-simulations.png).
  Widget library({
    required Entitlement entitlement,
    ScenarioTrack track = ScenarioTrack.b2c,
    double width = 1440,
    double height = 1500,
  }) {
    return ProviderScope(
      overrides: [
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
          child: AppShell(
            currentPath: '/simulations',
            child: LibraryScreen(initialTrack: track),
          ),
        ),
      ),
    );
  }

  goldenTest(
    'Library',
    fileName: 'library',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'B2C track, free tier',
          child: library(entitlement: Entitlement.free),
        ),
        GoldenTestScenario(
          name: 'B2B track, free tier: locked cards',
          child: library(
            entitlement: Entitlement.free,
            track: ScenarioTrack.b2b,
          ),
        ),
        GoldenTestScenario(
          name: 'B2B track, closer tier: unlocked',
          child: library(
            entitlement: Entitlement.closer,
            track: ScenarioTrack.b2b,
          ),
        ),
      ],
    ),
  );
}
