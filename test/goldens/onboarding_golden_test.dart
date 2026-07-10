@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth_service.dart';
import 'interactions.dart';

/// Full-screen scenario at the desktop web size the prototypes use.
Widget onboardingStep(OnboardingStep step) {
  SharedPreferences.setMockInitialValues({});
  return ProviderScope(
    overrides: [authServiceProvider.overrideWithValue(FakeAuthService())],
    child: noMotion(
      child: SizedBox(
        width: 1280,
        height: 800,
        child: OnboardingScreen(initialStep: step),
      ),
    ),
  );
}

void main() {
  goldenTest(
    'Onboarding welcome step',
    fileName: 'onboarding_welcome',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'wordmark hero',
          child: onboardingStep(OnboardingStep.welcome),
        ),
      ],
    ),
  );

  goldenTest(
    'Onboarding name step',
    fileName: 'onboarding_name',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'name question',
          child: onboardingStep(OnboardingStep.name),
        ),
      ],
    ),
  );

  goldenTest(
    'Onboarding question step',
    fileName: 'onboarding_question',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'who do you sell to',
          child: onboardingStep(OnboardingStep.track),
        ),
        GoldenTestScenario(
          name: 'focus areas',
          child: onboardingStep(OnboardingStep.focus),
        ),
      ],
    ),
  );

  goldenTest(
    'Onboarding reveal step',
    fileName: 'onboarding_reveal',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'recommended scenario, one CTA',
          child: onboardingStep(OnboardingStep.reveal),
        ),
      ],
    ),
  );
}
