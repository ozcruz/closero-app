@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/presentation/login_screen.dart';
import 'package:closero_app/features/auth/presentation/reset_password_screen.dart';
import 'package:closero_app/features/auth/presentation/signup_screen.dart';
import 'package:closero_app/features/auth/presentation/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_service.dart';
import 'interactions.dart';

/// Full-screen scenario at the desktop web size the prototypes use.
Widget authScreen(Widget screen, {String? email}) => ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(FakeAuthService()),
        if (email != null) currentUserEmailProvider.overrideWithValue(email),
      ],
      child: noMotion(
        child: SizedBox(width: 1280, height: 800, child: screen),
      ),
    );

void main() {
  goldenTest(
    'Login screen',
    fileName: 'login_screen',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'email step',
          child: authScreen(const LoginScreen()),
        ),
      ],
    ),
  );

  goldenTest(
    'Signup screen',
    fileName: 'signup_screen',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'email step',
          child: authScreen(const SignupScreen()),
        ),
      ],
    ),
  );

  goldenTest(
    'Reset password screen',
    fileName: 'reset_password_screen',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'request step',
          child: authScreen(const ResetPasswordScreen()),
        ),
      ],
    ),
  );

  goldenTest(
    'Verify email screen',
    fileName: 'verify_email_screen',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'waiting',
          child: authScreen(
            const VerifyEmailScreen(),
            email: 'rep@company.com',
          ),
        ),
      ],
    ),
  );
}
