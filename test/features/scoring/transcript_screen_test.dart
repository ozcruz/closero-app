import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:closero_app/features/scoring/presentation/transcript_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;

  Widget app({int? moment}) {
    final query = moment == null ? '' : '?moment=$moment';
    router = GoRouter(
      initialLocation: '/score/s1/transcript$query',
      routes: [
        GoRoute(
          path: '/score/:sessionId',
          builder: (context, state) => Scaffold(
            body: Text('Score stub ${state.pathParameters['sessionId']}'),
          ),
          routes: [
            GoRoute(
              path: 'transcript',
              builder: (context, state) => TranscriptScreen(
                sessionId: state.pathParameters['sessionId']!,
                moment:
                    int.tryParse(state.uri.queryParameters['moment'] ?? ''),
              ),
            ),
          ],
        ),
      ],
    );
    return ProviderScope(
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(1440, 1100),
          disableAnimations: true,
        ),
        child: MaterialApp.router(theme: closTheme(), routerConfig: router),
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester, {int? moment}) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(moment: moment));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the read-only utterance column with annotations',
      (tester) async {
    await pumpApp(tester);

    expect(
      find.text(
        'Meridian Software, this is Sandra. How can I direct your call?',
      ),
      findsOne,
    );
    expect(find.text('YOU'), findsWidgets);
    expect(find.text('SANDRA'), findsWidgets);
    // Read-only: nothing editable on this screen.
    expect(find.byType(TextField), findsNothing);
    // 720px centered column.
    expect(
      tester.getSize(find.byType(TranscriptLine).first).width,
      lessThanOrEqualTo(720),
    );
  });

  testWidgets('the meta strip carries persona, duration, and score',
      (tester) async {
    await pumpApp(tester);

    expect(
      find.textContaining('Sandra Voss', findRichText: true),
      findsWidgets,
    );
    expect(find.textContaining('Duration', findRichText: true), findsOne);
    expect(
      find.textContaining('Overall score', findRichText: true),
      findsOne,
    );
  });

  testWidgets('annotation notes come from the key moments', (tester) async {
    await pumpApp(tester);

    expect(find.text('STRONG'), findsOne);
    expect(
      find.textContaining('Disarmed the gatekeeper in under 30 seconds.'),
      findsOne,
    );
  });

  testWidgets('a moment deep link scrolls to its utterance',
      (tester) async {
    // Moment 2 in Strong-Watch-Missed order is the miss at 9:07,
    // far below the fold at 1100px.
    await pumpApp(tester, moment: 2);

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.pixels, greaterThan(0));

    final missLine = find.textContaining('Is that a concern?');
    expect(missLine, findsOne);
    final rect = tester.getRect(missLine);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.top, lessThan(1100));
  });

  testWidgets('back to score returns to the score route', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Back to score'));
    await tester.pumpAndSettle();

    expect(find.text('Score stub s1'), findsOne);
  });
}
