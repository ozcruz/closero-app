import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/onboarding/data/onboarding_store.dart';
import 'package:closero_app/features/onboarding/domain/onboarding_answers.dart';
import 'package:closero_app/features/onboarding/domain/recommended_scenario.dart';
import 'package:closero_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_service.dart';

void main() {
  late FakeAuthService auth;

  Widget app() => ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(auth)],
        child: MediaQuery(
          // Deterministic pumps: transitions snap, only the selection
          // hold timer advances with pump durations.
          data: const MediaQueryData(
            size: Size(1280, 800),
            disableAnimations: true,
          ),
          child: MaterialApp(
            theme: closTheme(),
            home: const OnboardingScreen(),
          ),
        ),
      );

  setUp(() {
    auth = FakeAuthService();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('walks all six steps and pre-loads the recommendation',
      (tester) async {
    await tester.pumpWidget(app());

    // Step 1: welcome hero, wordmark, single CTA.
    expect(find.text("Three quick questions.\nThen you're in."), findsOne);
    expect(find.byType(CloseroWordmark), findsOne);
    await tester.tap(find.text("Let's go"));
    await tester.pump();

    // Step 2: name, written to users/{uid} on continue.
    expect(find.text('What should we call you?'), findsOne);
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(auth.calls, contains('updateDisplayName'));
    expect(auth.lastDisplayName, 'Alex');

    // Step 3: track. No auto-advance before the hold elapses.
    expect(find.text('Who do you sell to?'), findsOne);
    await tester.tap(find.text('I sell to businesses'));
    await tester.pump(kOnboardingSelectionHold - const Duration(milliseconds: 50));
    expect(find.text('Who do you sell to?'), findsOne);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('How long have you been in sales?'), findsOne);

    // Step 4: experience.
    await tester.tap(find.text('Under 2 years'));
    await tester.pump(kOnboardingSelectionHold);

    // Step 5: focus.
    expect(find.text('Where do you want to improve most?'), findsOne);
    await tester.tap(find.text('Handling objections'));
    await tester.pump(kOnboardingSelectionHold);

    // Step 6: reveal. One CTA, a display-only scenario card, no
    // auto-start.
    expect(find.text("You're set, Alex."), findsOne);
    expect(find.text('Continue to dashboard'), findsOne);
    expect(find.byType(ScenarioCard), findsOne);
    expect(find.byType(PrimaryButton), findsOne);

    // The recommendation is persisted for the Dashboard hero.
    await tester.pump();
    const store = OnboardingStore();
    expect(await store.isComplete(), isTrue);
    expect(
      await store.recommendedScenarioId(),
      gatekeeperScenario.id,
    );
    final answers = await store.answers();
    expect(answers?.track, SellTrack.business);
    expect(answers?.experience, ExperienceLevel.underTwoYears);
    expect(answers?.focus, FocusArea.objections);
  });

  testWidgets('consumer track recommends the consumer scenario',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("Let's go"));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('I sell to people, directly'));
    await tester.pump(kOnboardingSelectionHold);
    await tester.tap(find.text('Just getting started'));
    await tester.pump(kOnboardingSelectionHold);
    await tester.tap(find.text('Building rapport'));
    await tester.pump(kOnboardingSelectionHold);

    expect(find.text(homeownerScenario.personaName), findsOne);
    expect(
      await const OnboardingStore().recommendedScenarioId(),
      homeownerScenario.id,
    );
  });

  testWidgets('empty name shows an error and stays put', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("Let's go"));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter a name to continue.'), findsOne);
    expect(find.text('What should we call you?'), findsOne);
    expect(auth.calls, isNot(contains('updateDisplayName')));
  });

  testWidgets('failed displayName write surfaces an error and stays',
      (tester) async {
    auth.failWith = Exception('offline');
    await tester.pumpWidget(app());
    await tester.tap(find.text("Let's go"));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Something went wrong. Please try again.'), findsOne);
    expect(find.text('What should we call you?'), findsOne);
  });

  testWidgets('back links retrace the steps', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("Let's go"));
    await tester.pump();
    await tester.tap(find.text('Back'));
    await tester.pump();
    expect(find.text("Three quick questions.\nThen you're in."), findsOne);
  });

  testWidgets('changing an answer within the hold restarts it',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("Let's go"));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.text('Continue'));
    await tester.pump();

    await tester.tap(find.text('I sell to businesses'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('I sell to people, directly'));
    // 200ms into the second hold: still on the question.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Who do you sell to?'), findsOne);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('How long have you been in sales?'), findsOne);

    // The corrected answer is the one that sticks.
    await tester.tap(find.text('Just getting started'));
    await tester.pump(kOnboardingSelectionHold);
    await tester.tap(find.text('Closing the deal'));
    await tester.pump(kOnboardingSelectionHold);
    expect(find.text(homeownerScenario.personaName), findsOne);
  });
}
