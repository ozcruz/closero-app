import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/presentation/login_screen.dart';
import 'package:closero_app/features/auth/presentation/reset_password_screen.dart';
import 'package:closero_app/features/auth/presentation/signup_screen.dart';
import 'package:closero_app/features/auth/presentation/verify_email_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_service.dart';

/// Pumps [screen] inside a minimal router so context.go targets exist,
/// with the auth service faked out.
Future<void> pumpAuthScreen(
  WidgetTester tester,
  Widget screen,
  FakeAuthService auth, {
  String? email,
}) async {
  // Desktop web viewport so the full auth card is on screen and tappable.
  tester.view.physicalSize = const Size(1280, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/under-test',
    routes: [
      GoRoute(path: '/under-test', builder: (_, _) => screen),
      for (final path in [
        '/',
        '/login',
        '/signup',
        '/reset-password',
        '/verify-email',
        '/onboarding',
      ])
        GoRoute(
          path: path,
          builder: (_, _) => Text('stub:$path'),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        if (email != null) currentUserEmailProvider.overrideWithValue(email),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(theme: closTheme(), routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Activates an inline [TextSpan] link (e.g. inside an AuthSwitchLine)
/// by firing its tap recognizer, since span glyph positions aren't
/// addressable through finders.
void tapInlineLink(WidgetTester tester, String label) {
  TapGestureRecognizer? recognizer;
  for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
    widget.text.visitChildren((span) {
      if (span is TextSpan &&
          span.text == label &&
          span.recognizer is TapGestureRecognizer) {
        recognizer = span.recognizer! as TapGestureRecognizer;
        return false;
      }
      return true;
    });
    if (recognizer != null) break;
  }
  expect(recognizer, isNotNull, reason: 'no inline link "$label" found');
  recognizer!.onTap!();
}

void main() {
  group('LoginScreen', () {
    testWidgets('progressive email to password flow, then submit',
        (tester) async {
      final auth = FakeAuthService();
      await pumpAuthScreen(tester, const LoginScreen(), auth);

      expect(find.text('Welcome back.'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'rep@company.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Password step: confirmed email with a change action.
      expect(find.text('rep@company.com'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'hunter22');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(auth.calls, contains('signInWithEmail'));
      expect(auth.lastEmail, 'rep@company.com');
      expect(auth.lastPassword, 'hunter22');
      // Fake has no current user, so the screen goes home.
      expect(find.text('stub:/'), findsOneWidget);
    });

    testWidgets('change returns to the email step', (tester) async {
      final auth = FakeAuthService();
      await pumpAuthScreen(tester, const LoginScreen(), auth);

      await tester.enterText(find.byType(TextField), 'rep@company.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Change'), findsNothing);
    });

    testWidgets('auth failure surfaces the mapped message', (tester) async {
      final auth = FakeAuthService()..failWith = Exception('nope');
      await pumpAuthScreen(tester, const LoginScreen(), auth);

      await tester.enterText(find.byType(TextField), 'rep@company.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hunter22');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.byType(InlineNotice), findsOneWidget);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('google SSO goes straight home', (tester) async {
      final auth = FakeAuthService();
      await pumpAuthScreen(tester, const LoginScreen(), auth);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(auth.calls, contains('signInWithGoogle'));
      expect(find.text('stub:/'), findsOneWidget);
    });

    testWidgets('apple SSO stays hidden behind the flag', (tester) async {
      await pumpAuthScreen(tester, const LoginScreen(), FakeAuthService());
      expect(find.text('Continue with Apple'), findsNothing);
    });
  });

  group('SignupScreen', () {
    testWidgets('short password blocks the account creation', (tester) async {
      final auth = FakeAuthService();
      await pumpAuthScreen(tester, const SignupScreen(), auth);

      await tester.enterText(find.byType(TextField), 'rep@company.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'short');
      await tester.tap(find.text('Create free account'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters.'),
        findsOneWidget,
      );
      expect(auth.calls, isNot(contains('signUpWithEmail')));
    });

    testWidgets('signup lands on verify email', (tester) async {
      final auth = FakeAuthService();
      await pumpAuthScreen(tester, const SignupScreen(), auth);

      await tester.enterText(find.byType(TextField), 'rep@company.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'longenough');
      await tester.tap(find.text('Create free account'));
      await tester.pumpAndSettle();

      expect(auth.calls, contains('signUpWithEmail'));
      expect(find.text('stub:/verify-email'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen', () {
    testWidgets('sends the link and shows the sent state', (tester) async {
      final auth = FakeAuthService();
      await pumpAuthScreen(tester, const ResetPasswordScreen(), auth);

      expect(find.text('Forgot your password?'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'rep@company.com');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(auth.calls, contains('sendPasswordReset'));
      expect(auth.lastEmail, 'rep@company.com');
      expect(find.text('Link sent.'), findsOneWidget);

      // Wrong email? Try again returns to the form. The link is an
      // inline TextSpan, so activate its recognizer directly.
      tapInlineLink(tester, 'Try again');
      await tester.pumpAndSettle();
      expect(find.text('Forgot your password?'), findsOneWidget);
    });
  });

  group('VerifyEmailScreen', () {
    testWidgets('shows the account email and resends', (tester) async {
      final auth = FakeAuthService();
      await pumpAuthScreen(
        tester,
        const VerifyEmailScreen(),
        auth,
        email: 'rep@company.com',
      );

      expect(find.text('Check your inbox.'), findsOneWidget);
      expect(find.textContaining('rep@company.com'), findsOneWidget);

      await tester.tap(find.text('Resend link'));
      await tester.pumpAndSettle();

      expect(auth.calls, contains('resendVerificationEmail'));
      expect(
        find.text('Sent. Check your inbox and spam folder.'),
        findsOneWidget,
      );
    });

    testWidgets('polls and moves a first-time user into onboarding',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final auth = FakeAuthService()..verified = true;
      await pumpAuthScreen(tester, const VerifyEmailScreen(), auth);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(auth.calls, contains('reloadAndCheckVerified'));
      expect(find.text('stub:/onboarding'), findsOneWidget);
    });

    testWidgets('polls and moves an onboarded user to the dashboard',
        (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding.complete': true});
      final auth = FakeAuthService()..verified = true;
      await pumpAuthScreen(tester, const VerifyEmailScreen(), auth);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('stub:/'), findsOneWidget);
    });
  });
}
