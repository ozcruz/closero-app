import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:closero_app/features/library/presentation/library_screen.dart';
import 'package:closero_app/features/library/presentation/scenario_preview_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;

  Widget app({Entitlement entitlement = Entitlement.free}) {
    router = GoRouter(
      initialLocation: '/simulations',
      routes: [
        GoRoute(
          path: '/simulations',
          builder: (context, state) =>
              const Scaffold(body: LibraryScreen()),
        ),
        GoRoute(
          path: '/upgrade',
          builder: (context, state) =>
              const Scaffold(body: Text('Upgrade screen')),
        ),
        GoRoute(
          path: '/sim/cold-call/:scenarioId',
          builder: (context, state) => Scaffold(
            body: Text('Sim ${state.pathParameters['scenarioId']}'),
          ),
        ),
      ],
    );
    return ProviderScope(
      overrides: [entitlementProvider.overrideWithValue(entitlement)],
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(1440, 1200),
          disableAnimations: true,
        ),
        child: MaterialApp.router(theme: closTheme(), routerConfig: router),
      ),
    );
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    Entitlement entitlement = Entitlement.free,
  }) async {
    tester.view.physicalSize = const Size(1440, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(entitlement: entitlement));
    await tester.pumpAndSettle();
  }

  testWidgets('B2C library renders both sections, scores, never tags',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('PICK UP WHERE YOU LEFT OFF'), findsOne);
    expect(find.text('NEW SCENARIOS'), findsOne);
    expect(
      find.text('Door-to-door, retail, phone, and high-ticket '
          'consumer closing'),
      findsOne,
    );

    // Completion is a personal-best score or Start, never a checkmark.
    expect(find.text('58'), findsOne);
    expect(find.text('81'), findsOne);
    expect(find.text('Resume'), findsOne);
    expect(find.text('Start'), findsNWidgets(2));

    // Methodology tags live only in the modal, never on cards.
    expect(find.text('Straight Line'), findsNothing);
    expect(find.text('Sandler Method'), findsNothing);
  });

  testWidgets('card opens the shared preview modal and starts the session',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Marisol'));
    await tester.pumpAndSettle();

    expect(find.byType(ScenarioPreviewModal), findsOne);
    expect(find.text('Phone shopper / Three quotes open'), findsOne);
    // Tags appear here, and only here.
    expect(find.text('Straight Line'), findsOne);
    // Never completed: no personal-best row.
    expect(find.text('Your personal best'), findsNothing);

    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/sim/cold-call/phone-quote-shopper-marisol',
    );
  });

  testWidgets('in-progress scenario resumes instead of starting',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('The Coopers'));
    await tester.pumpAndSettle();
    expect(find.text('Resume session'), findsOne);
    expect(find.text('Start session'), findsNothing);
  });

  testWidgets('free tier: B2B cards render locked and route to upgrade',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('B2B'));
    await tester.pumpAndSettle();

    expect(find.text('Locked'), findsNWidgets(4));
    // Sandra's personal best stays hidden while gated.
    expect(find.text('78'), findsNothing);

    await tester.tap(find.text('Sandra'));
    await tester.pumpAndSettle();
    expect(find.byType(ScenarioPreviewModal), findsNothing);
    expect(find.text('Upgrade screen'), findsOne);
  });

  testWidgets('closer tier: B2B unlocks with personal bests and the modal',
      (tester) async {
    await pumpApp(tester, entitlement: Entitlement.closer);

    await tester.tap(find.text('B2B'));
    await tester.pumpAndSettle();

    expect(find.text('Locked'), findsNothing);
    expect(find.text('78'), findsOne);

    await tester.tap(find.text('Sandra'));
    await tester.pumpAndSettle();
    expect(find.byType(ScenarioPreviewModal), findsOne);
    expect(find.text('EA / Front desk gatekeeper'), findsOne);
    expect(find.text('Your personal best'), findsOne);
  });
}
