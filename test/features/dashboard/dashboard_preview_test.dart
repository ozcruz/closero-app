import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/dashboard/data/dashboard_repository.dart';
import 'package:closero_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:closero_app/features/library/presentation/scenario_preview_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'dashboard preview opens the shared modal for the hero scenario',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: DashboardScreen()),
        ),
        GoRoute(
          path: '/sim/cold-call/:scenarioId',
          builder: (context, state) => Scaffold(
            body: Text('Sim ${state.pathParameters['scenarioId']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          clockProvider.overrideWithValue(() => DateTime(2026, 7, 10, 9)),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(1440, 1400),
            disableAnimations: true,
          ),
          child:
              MaterialApp.router(theme: closTheme(), routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Preview scenario'));
    await tester.pumpAndSettle();

    // The default hero is the canonical gatekeeper; the modal renders
    // the same scenario from the one shared catalog.
    expect(find.byType(ScenarioPreviewModal), findsOne);
    expect(find.text('Sandra'), findsOne);
    expect(find.text('EA / Front desk gatekeeper'), findsOne);
    expect(find.text('Your personal best'), findsOne);
    expect(find.text('78'), findsOne);
  });
}
