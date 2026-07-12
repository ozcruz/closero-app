import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:closero_app/features/methodologies/domain/methodology.dart';
import 'package:closero_app/features/methodologies/presentation/methodologies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;

  Widget app({Entitlement entitlement = Entitlement.free}) {
    router = GoRouter(
      initialLocation: '/methodologies',
      routes: [
        GoRoute(
          path: '/methodologies',
          builder: (context, state) =>
              const Scaffold(body: MethodologiesScreen()),
        ),
        GoRoute(
          path: '/upgrade',
          builder: (context, state) =>
              const Scaffold(body: Text('Upgrade screen')),
        ),
        GoRoute(
          path: '/simulations',
          builder: (context, state) =>
              const Scaffold(body: Text('Simulations screen')),
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
    tester.view.physicalSize = const Size(1440, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(entitlement: entitlement));
    await tester.pumpAndSettle();
  }

  test('the reference set is the five fixed frameworks', () {
    expect(
      [for (final m in methodologyCatalog) m.name],
      [
        'Sandler Method',
        'SPIN Selling',
        'Challenger Sale',
        'Straight Line Selling',
        '7th Level',
      ],
    );
    for (final methodology in methodologyCatalog) {
      expect(methodology.concepts, hasLength(4));
    }
  });

  testWidgets('free: gate banner, inert cards, upgrade routes',
      (tester) async {
    await pumpApp(tester);

    expect(
      find.text('Advanced frameworks are part of Closer'),
      findsOne,
    );

    // All five cards render behind the blur, inert: tapping a card
    // link goes nowhere.
    expect(find.byType(ImageFiltered), findsNWidgets(5));
    await tester.tap(
      find.text('See scenarios using this →').first,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Simulations screen'), findsNothing);
    expect(find.text('Methodologies'), findsOne);

    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();
    expect(find.text('Upgrade screen'), findsOne);
  });

  testWidgets('closer: no gate, five reference cards, library link only',
      (tester) async {
    await pumpApp(tester, entitlement: Entitlement.closer);

    expect(
      find.text('Advanced frameworks are part of Closer'),
      findsNothing,
    );
    expect(find.text('Upgrade'), findsNothing);

    for (final methodology in methodologyCatalog) {
      expect(find.text(methodology.name), findsOne);
    }
    expect(find.text('Pain funnel'), findsOne);
    expect(
      find.textContaining('Not started', findRichText: true),
      findsOne,
    );

    // No accent anywhere on this screen: no primary buttons at all.
    expect(find.byType(PrimaryButton), findsNothing);

    // Reference only: the card's one link goes to the library, there
    // is no drill-down.
    await tester.tap(find.text('See scenarios using this →').first);
    await tester.pumpAndSettle();
    expect(find.text('Simulations screen'), findsOne);
  });
}
