import 'package:closero_app/core/services/auth_service.dart';
import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:closero_app/features/settings/data/settings_store.dart';
import 'package:closero_app/features/settings/presentation/change_password_screen.dart';
import 'package:closero_app/features/settings/presentation/connected_accounts_screen.dart';
import 'package:closero_app/features/settings/presentation/delete_account_screen.dart';
import 'package:closero_app/features/settings/presentation/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_service.dart';

void main() {
  const freeUser = UserDoc(
    uid: 'uid-1',
    email: 'osman@company.com',
    displayName: 'Osman Cruz',
    entitlement: Entitlement.free,
    sessionsUsed: 3,
    usageMonth: '2026-07',
  );

  late FakeAuthService auth;
  late GoRouter router;

  Widget app(Widget screen, {UserDoc userDoc = freeUser}) {
    SharedPreferences.setMockInitialValues({});
    router = GoRouter(
      initialLocation: '/screen',
      routes: [
        GoRoute(
          path: '/screen',
          builder: (context, state) => Scaffold(body: screen),
        ),
        for (final path in const [
          '/settings',
          '/settings/password',
          '/settings/connected',
          '/settings/delete',
          '/upgrade',
        ])
          GoRoute(
            path: path,
            builder: (context, state) => Scaffold(body: Text('at $path')),
          ),
      ],
    );
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        userDocProvider.overrideWith((ref) => Stream.value(userDoc)),
      ],
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(1280, 1400),
          disableAnimations: true,
        ),
        child: MaterialApp.router(theme: closTheme(), routerConfig: router),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, Widget screen,
      {UserDoc userDoc = freeUser}) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(screen, userDoc: userDoc));
    await tester.pumpAndSettle();
  }

  setUp(() {
    auth = FakeAuthService()
      ..providers = [
        const LinkedProvider(providerId: 'password', email: 'osman@company.com'),
      ];
  });

  group('SettingsScreen', () {
    testWidgets('free plan shows usage and routes Upgrade to /upgrade',
        (tester) async {
      await pump(tester, const SettingsScreen());
      expect(
        find.text('3 of 3 free sessions used this month'),
        findsOneWidget,
      );
      await tester.tap(find.text('Upgrade to Closer'));
      await tester.pumpAndSettle();
      expect(find.text('at /upgrade'), findsOneWidget);
    });

    testWidgets('practice preference persists through the store',
        (tester) async {
      await pump(tester, const SettingsScreen());
      await tester.tap(find.text('B2B'));
      await tester.pumpAndSettle();
      final stored = await const SettingsStore().load();
      expect(stored.audience, PracticeAudience.b2b);
    });

    testWidgets('log out row signs out', (tester) async {
      await pump(tester, const SettingsScreen());
      final button = find.text('Log out').last;
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(auth.calls, contains('signOut'));
    });
  });

  group('ChangePasswordScreen', () {
    Future<void> fill(WidgetTester tester,
        {required String current,
        required String next,
        required String confirm}) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), current);
      await tester.enterText(fields.at(1), next);
      await tester.enterText(fields.at(2), confirm);
    }

    testWidgets('mismatched confirmation blocks the update', (tester) async {
      await pump(tester, const ChangePasswordScreen());
      await fill(tester,
          current: 'oldpassword1', next: 'closerdeal42', confirm: 'different42');
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();
      expect(find.text("Those passwords don't match."), findsOneWidget);
      expect(auth.calls, isNot(contains('changePassword')));
    });

    testWidgets('valid input reauthenticates and updates', (tester) async {
      await pump(tester, const ChangePasswordScreen());
      await fill(tester,
          current: 'oldpassword1',
          next: 'closerdeal42',
          confirm: 'closerdeal42');
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();
      expect(auth.calls, contains('changePassword'));
      expect(auth.lastPassword, 'closerdeal42');
      expect(find.text('Password updated.'), findsOneWidget);
    });

    testWidgets('SSO-only account gets a notice, not a form', (tester) async {
      auth.providers = [
        const LinkedProvider(
            providerId: 'google.com', email: 'osman@company.com'),
      ];
      await pump(tester, const ChangePasswordScreen());
      expect(find.byType(TextField), findsNothing);
      expect(
        find.textContaining('Password login is not set up'),
        findsOneWidget,
      );
    });
  });

  group('ConnectedAccountsScreen', () {
    testWidgets('connect calls linkProvider for Google', (tester) async {
      await pump(tester, const ConnectedAccountsScreen());
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
      expect(auth.calls, contains('linkProvider'));
      expect(auth.lastProviderId, 'google.com');
    });

    testWidgets('the only sign-in method cannot be disconnected',
        (tester) async {
      auth.providers = [
        const LinkedProvider(
            providerId: 'google.com', email: 'osman@company.com'),
      ];
      await pump(tester, const ConnectedAccountsScreen());
      expect(find.text('Connected · osman@company.com'), findsOneWidget);
      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();
      expect(auth.calls, isNot(contains('unlinkProvider')));
    });
  });

  group('DeleteAccountScreen', () {
    testWidgets('delete stays disabled until DELETE is typed exactly',
        (tester) async {
      await pump(tester, const DeleteAccountScreen());
      await tester.tap(find.text('Permanently delete account'));
      await tester.pumpAndSettle();
      expect(auth.calls, isNot(contains('deleteAccount')));

      await tester.enterText(find.byType(TextField).first, 'delete');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Permanently delete account'));
      await tester.pumpAndSettle();
      expect(auth.calls, isNot(contains('deleteAccount')));
    });

    testWidgets('password accounts must confirm with the password',
        (tester) async {
      await pump(tester, const DeleteAccountScreen());
      await tester.enterText(find.byType(TextField).at(0), 'DELETE');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Permanently delete account'));
      await tester.pumpAndSettle();
      expect(auth.calls, isNot(contains('deleteAccount')));
      expect(
        find.text('Enter your current password to confirm.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).at(1), 'oldpassword1');
      await tester.tap(find.text('Permanently delete account'));
      // Success leaves the button in its loading state (the auth flip
      // navigates in production), so settle would spin forever.
      await tester.pump();
      expect(auth.calls, contains('deleteAccount'));
      expect(auth.lastPassword, 'oldpassword1');
    });
  });
}
