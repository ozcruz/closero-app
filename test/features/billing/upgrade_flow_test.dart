import 'dart:async';

import 'package:closero_app/core/services/billing_service.dart';
import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:closero_app/features/billing/application/billing_providers.dart';
import 'package:closero_app/features/billing/presentation/upgrade_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'uid-1';

  @override
  String? get email => 'osman@company.com';
}

void main() {
  const freeUser = UserDoc(
    uid: 'uid-1',
    email: 'osman@company.com',
    displayName: 'Osman Cruz',
    entitlement: Entitlement.free,
    sessionsUsed: 5,
    usageMonth: '2026-07',
  );
  const closerUser = UserDoc(
    uid: 'uid-1',
    email: 'osman@company.com',
    displayName: 'Osman Cruz',
    entitlement: Entitlement.closer,
    sessionsUsed: 5,
    usageMonth: '2026-07',
  );

  late GoRouter router;

  Widget app({
    required Stream<UserDoc?> userDocStream,
    BillingService? billing,
  }) {
    router = GoRouter(
      initialLocation: '/upgrade',
      routes: [
        GoRoute(
          path: '/upgrade',
          builder: (context, state) => const UpgradeScreen(),
        ),
        GoRoute(
          path: '/upgrade-success',
          builder: (context, state) =>
              const Scaffold(body: Text('at /upgrade-success')),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('at /')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream<User?>.value(_FakeUser()),
        ),
        userDocProvider.overrideWith((ref) => userDocStream),
        if (billing != null) billingServiceProvider.overrideWithValue(billing),
      ],
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(1280, 1500),
          disableAnimations: true,
        ),
        child: MaterialApp.router(theme: closTheme(), routerConfig: router),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1280, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  testWidgets('unconfigured checkout disables the CTA and says why',
      (tester) async {
    await pump(tester, app(userDocStream: Stream.value(freeUser)));
    expect(
      find.textContaining('Checkout is not configured'),
      findsOneWidget,
    );
    // .last: the topbar title also reads 'Upgrade to Closer'.
    await tester.tap(find.text('Upgrade to Closer').last);
    await tester.pumpAndSettle();
    // Still on the upgrade screen, nothing opened.
    expect(find.text('Practice without limits.'), findsOneWidget);
  });

  testWidgets('configured checkout opens the purchase link with the uid',
      (tester) async {
    final launched = <Uri>[];
    final billing = WebBillingService(
      purchaseLinkBase: 'https://pay.rev.cat/abc123',
      openUrl: (uri) async {
        launched.add(uri);
        return true;
      },
    );
    await pump(
      tester,
      app(userDocStream: Stream.value(freeUser), billing: billing),
    );
    final cta = find.widgetWithText(PrimaryButton, 'Upgrade to Closer');
    expect(tester.widget<PrimaryButton>(cta).onPressed, isNotNull);
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(find.textContaining('could not open'), findsNothing,
        reason: 'openCheckout reported failure');
    expect(
      launched.single.toString(),
      'https://pay.rev.cat/abc123/uid-1?email=osman%40company.com',
    );
    expect(
      find.textContaining('Checkout opened in a new tab'),
      findsOneWidget,
    );
  });

  testWidgets('entitlement flipping to closer moves to the success screen',
      (tester) async {
    final docs = StreamController<UserDoc?>();
    addTearDown(docs.close);
    await pump(tester, app(userDocStream: docs.stream));
    docs.add(freeUser);
    await tester.pumpAndSettle();
    expect(find.text('Practice without limits.'), findsOneWidget);

    // The webhook flips the doc; the watch moves this tab forward.
    docs.add(closerUser);
    await tester.pumpAndSettle();
    expect(find.text('at /upgrade-success'), findsOneWidget);
  });
}
