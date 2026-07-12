import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:closero_app/features/progress/data/progress_repository.dart';
import 'package:closero_app/features/progress/presentation/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;

  Widget app({bool empty = false}) {
    router = GoRouter(
      initialLocation: '/progress',
      routes: [
        GoRoute(
          path: '/progress',
          builder: (context, state) =>
              const Scaffold(body: ProgressScreen()),
        ),
        GoRoute(
          path: '/simulations',
          builder: (context, state) =>
              const Scaffold(body: Text('Simulations screen')),
        ),
        GoRoute(
          path: '/score/:sessionId',
          builder: (context, state) => Scaffold(
            body: Text('Score ${state.pathParameters['sessionId']}'),
          ),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        progressRepositoryProvider
            .overrideWithValue(FixtureProgressRepository(empty: empty)),
      ],
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(1440, 1200),
          disableAnimations: true,
        ),
        child: MaterialApp.router(theme: closTheme(), routerConfig: router),
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester, {bool empty = false}) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(empty: empty));
    await tester.pumpAndSettle();
  }

  testWidgets('the range toggle re-queries every section', (tester) async {
    await pumpApp(tester);

    // 30D is the default range.
    expect(
      find.textContaining('14 sessions', findRichText: true),
      findsOne,
    );
    expect(find.text('3.4 hrs'), findsOne);
    expect(find.text('+6 vs last period'), findsOne);

    await tester.tap(find.text('7D'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('4 sessions', findRichText: true),
      findsOne,
    );
    expect(find.text('1.1 hrs'), findsOne);
    expect(find.text('+4 vs last period'), findsOne);

    // All time: no previous period, so no comparison chip.
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('47 sessions', findRichText: true),
      findsOne,
    );
    expect(find.text('11.2 hrs'), findsOne);
    expect(find.textContaining('vs last period'), findsNothing);
  });

  testWidgets('populated screen renders all five sections', (tester) async {
    await pumpApp(tester);

    expect(find.text('OVERALL SCORE'), findsOne);
    expect(find.text('EARNING POTENTIAL'), findsOne);
    expect(find.text('Current streak'), findsOne);
    expect(find.text('SKILL BREAKDOWN'), findsOne);
    expect(find.text('SCORE BY SESSION'), findsOne);
    expect(find.text('LATEST SESSIONS'), findsOne);
    expect(find.byType(ScoreBars), findsOne);

    // Canonical skills, weakest first.
    expect(find.text('Objection handling'), findsOne);
    expect(find.text('Building rapport'), findsOne);

    // The full-form shared earning figure.
    expect(find.textContaining(r'$64,000', findRichText: true), findsOne);
  });

  testWidgets('history rows open the session score screen', (tester) async {
    await pumpApp(tester);

    await tester.scrollUntilVisible(
      find.text('Inbound Demo, Hesitant Buyer'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Inbound Demo, Hesitant Buyer'));
    await tester.pumpAndSettle();

    expect(find.text('Score inbound-demo-hesitant-buyer'), findsOne);
  });

  testWidgets('session zero is one centered empty state', (tester) async {
    await pumpApp(tester, empty: true);

    expect(find.byType(EmptyState), findsOne);
    expect(find.text('Your progress will show up here'), findsOne);

    // No range toggle and no broken charts at session zero.
    expect(find.byType(ClosSegmented), findsNothing);
    expect(find.byType(ScoreBars), findsNothing);
    expect(find.byType(SparkLine), findsNothing);

    await tester.tap(find.text('Start a session'));
    await tester.pumpAndSettle();
    expect(find.text('Simulations screen'), findsOne);
  });
}
