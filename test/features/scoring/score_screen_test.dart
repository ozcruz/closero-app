import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:closero_app/features/scoring/presentation/score_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;

  Widget app({String sessionId = 's1'}) {
    router = GoRouter(
      initialLocation: '/score/$sessionId',
      routes: [
        GoRoute(
          path: '/score/:sessionId',
          builder: (context, state) =>
              ScoreScreen(sessionId: state.pathParameters['sessionId']!),
          routes: [
            GoRoute(
              path: 'transcript',
              builder: (context, state) => Scaffold(
                body: Text(
                  'Transcript stub, moment '
                  '${state.uri.queryParameters['moment'] ?? 'none'}',
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/sim/cold-call/:scenarioId',
          builder: (context, state) => Scaffold(
            body: Text('Sim stub ${state.pathParameters['scenarioId']}'),
          ),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Dashboard stub')),
        ),
      ],
    );
    return ProviderScope(
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(1440, 2600),
          disableAnimations: true,
        ),
        child: MaterialApp.router(theme: closTheme(), routerConfig: router),
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester, {String sessionId = 's1'}) async {
    tester.view.physicalSize = const Size(1440, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(sessionId: sessionId));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the ring number, title, and write-time delta',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('78'), findsOne);
    expect(find.text('OVERALL'), findsOne);
    expect(find.text('Gatekeeper bypass, SaaS AE'), findsOne);
    expect(find.text('vs 10-session avg'), findsOne);
    expect(find.text('+6 pts'), findsOne);
  });

  testWidgets('all five locked category names render with their scores',
      (tester) async {
    await pumpApp(tester);

    for (final entry in {
      'OBJECTION HANDLING': '71',
      'DISCOVERY QUESTIONS': '86',
      'CLOSING TECHNIQUE': '85',
      'BUILDING RAPPORT': '84',
      'TONALITY AND PACING': '61',
    }.entries) {
      expect(find.text(entry.key), findsOne);
      expect(find.text(entry.value), findsAtLeast(1));
    }
    // "Last session" captions come from the previous session's doc.
    expect(
      find.textContaining('Last session', findRichText: true),
      findsNWidgets(5),
    );
  });

  testWidgets('accent audit: the primary CTA is the only accent fill',
      (tester) async {
    await pumpApp(tester);

    expect(find.byType(PrimaryButton), findsOne);
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).label,
      'Practice this call again',
    );
  });

  testWidgets('key moments render Strong, Watch, Missed in order and '
      'deep-link by moment index', (tester) async {
    await pumpApp(tester);

    final labels = ['STRONG', 'WATCH', 'MISSED'];
    final positions = [
      for (final label in labels) tester.getTopLeft(find.text(label)).dy,
    ];
    expect(positions[0], lessThan(positions[1]));
    expect(positions[1], lessThan(positions[2]));

    await tester.tap(find.text('WATCH'));
    await tester.pumpAndSettle();

    expect(find.text('Transcript stub, moment 1'), findsOne);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/score/s1/transcript?moment=1',
    );
  });

  testWidgets('the stat strip shows schema-backed stats only',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('14:32'), findsAtLeast(1));
    expect(find.text('43%'), findsOne);
    expect(find.text('YOUR TALK TIME'), findsOne);
    // Not in the stats schema block; prototype drift stays out.
    expect(find.textContaining('EXCHANGES'), findsNothing);
    expect(find.textContaining('STREAK'), findsNothing);
  });

  testWidgets('the primary CTA restarts the same scenario', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Practice this call again'));
    await tester.pumpAndSettle();

    expect(find.text('Sim stub cold-call-saas-gatekeeper'), findsOne);
  });

  testWidgets('aborted sessions get honest copy and no score',
      (tester) async {
    await pumpApp(tester, sessionId: 'aborted');

    expect(
      find.text('This call ended before it could be scored.'),
      findsOne,
    );
    expect(find.byType(ScoreRing), findsNothing);
    expect(find.byType(DeltaPill), findsNothing);
    // Still exactly one accent CTA.
    expect(find.byType(PrimaryButton), findsOne);
  });
}
