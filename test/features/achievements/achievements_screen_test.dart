import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/features/achievements/data/achievements_repository.dart';
import 'package:closero_app/features/achievements/presentation/achievements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;

  Widget app({bool empty = false}) {
    router = GoRouter(
      initialLocation: '/achievements',
      routes: [
        GoRoute(
          path: '/achievements',
          builder: (context, state) =>
              const Scaffold(body: AchievementsScreen()),
        ),
        GoRoute(
          path: '/simulations',
          builder: (context, state) =>
              const Scaffold(body: Text('Simulations screen')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        achievementsRepositoryProvider
            .overrideWithValue(FixtureAchievementsRepository(empty: empty)),
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
    tester.view.physicalSize = const Size(1440, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(empty: empty));
    await tester.pumpAndSettle();
  }

  /// Every rendered text, with rich spans flattened.
  Iterable<String> allTexts(WidgetTester tester) =>
      tester.widgetList<Text>(find.byType(Text)).map(
            (text) => text.data ?? text.textSpan!.toPlainText(),
          );

  test('the unlock counter falls out of the fixtures', () {
    expect(achievementsFixture.unlockedCount, 7);
    expect(achievementsFixture.totalCount, 16);
    expect(emptyAchievementsData.unlockedCount, 0);
    expect(emptyAchievementsData.totalCount, 16);
  });

  testWidgets('one dollar figure on the whole screen, the shared one',
      (tester) async {
    await pumpApp(tester);

    final dollarTexts =
        allTexts(tester).where((t) => t.contains(r'$')).toList();
    expect(dollarTexts, hasLength(1));
    expect(dollarTexts.single, contains(r'$64K'));
  });

  testWidgets('populated: counter, ranked plan, mastery states',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('7 of 16 unlocked'), findsOne);
    expect(find.text('7 / 16'), findsOne);
    expect(find.text('YOUR FASTEST PATH UP'), findsOne);
    expect(find.text('Close the objection handling gap'), findsOne);
    expect(find.text('Push discovery past 70%'), findsOne);
    expect(find.text('Protect your streak'), findsOne);

    // Mastery: the tier-gating skill leads; met thresholds read as
    // unlocked.
    expect(find.text('Objection Handler'), findsOne);
    expect(find.text('Unlocks next tier'), findsOne);
    expect(find.text('Unlocked'), findsNWidgets(2));

    // Streaks never claim score or income movement.
    expect(find.textContaining('streak unlocks'), findsNothing);
  });

  testWidgets('badge filter narrows the grid', (tester) async {
    await pumpApp(tester);

    await tester.scrollUntilVisible(
      find.text('First rep'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Three in a row'), findsOne);

    await tester.tap(find.text('Streaks'));
    await tester.pumpAndSettle();

    expect(find.text('Three in a row'), findsOne);
    expect(find.text('First rep'), findsNothing);
    expect(find.text('Both tracks'), findsNothing);
  });

  testWidgets('path CTAs route to the library', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Find a scenario →').first);
    await tester.pumpAndSettle();
    expect(find.text('Simulations screen'), findsOne);
  });

  testWidgets('session zero: entry figure, get-started plan, no badges tile',
      (tester) async {
    await pumpApp(tester, empty: true);

    expect(find.text('0 of 16 unlocked'), findsOne);
    expect(find.text('Badges unlocked'), findsNothing);
    expect(find.text('GET STARTED'), findsOne);
    expect(find.text('Every stat on this page starts here.'), findsOne);

    final dollarTexts =
        allTexts(tester).where((t) => t.contains(r'$')).toList();
    expect(dollarTexts, hasLength(1));
    expect(dollarTexts.single, contains(r'$40K'));
  });
}
