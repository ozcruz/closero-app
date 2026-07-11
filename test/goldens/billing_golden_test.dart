@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/services/billing_service.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:closero_app/features/billing/application/billing_providers.dart';
import 'package:closero_app/features/billing/presentation/session_limit_screen.dart';
import 'package:closero_app/features/billing/presentation/upgrade_screen.dart';
import 'package:closero_app/features/billing/presentation/upgrade_success_screen.dart';
import 'package:closero_app/features/dashboard/data/dashboard_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const freeUser = UserDoc(
    uid: 'uid-1',
    email: 'osman@company.com',
    displayName: 'Osman Cruz',
    entitlement: Entitlement.free,
    sessionsUsed: 5,
    usageMonth: '2026-07',
  );

  Widget billing(
    Widget screen, {
    double width = 1440,
    double height = 1240,
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        userDocProvider.overrideWith((ref) => Stream.value(freeUser)),
        clockProvider.overrideWithValue(() => DateTime(2026, 7, 10, 9)),
        // A configured checkout so the golden shows the shipping state,
        // not the missing-dart-define notice.
        billingServiceProvider.overrideWithValue(
          const WebBillingService(
            purchaseLinkBase: 'https://pay.rev.cat/golden',
          ),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          disableAnimations: true,
        ),
        child: SizedBox(width: width, height: height, child: screen),
      ),
    );
  }

  goldenTest(
    'Billing wall',
    fileName: 'billing',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'upgrade (16-billing-upgrade.png)',
          child: billing(const UpgradeScreen()),
        ),
        GoldenTestScenario(
          name: 'upgrade narrow: stacked plans',
          child: billing(const UpgradeScreen(), width: 720, height: 2050),
        ),
        GoldenTestScenario(
          name: 'session limit (17-session-limit.png)',
          child: billing(const SessionLimitScreen(), height: 1000),
        ),
        GoldenTestScenario(
          name: 'upgrade success (18-upgrade-success.png)',
          child: billing(const UpgradeSuccessScreen(), height: 1000),
        ),
      ],
    ),
  );
}
