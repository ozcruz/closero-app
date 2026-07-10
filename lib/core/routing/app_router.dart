import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../widgets/widgets.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'auth_guard.dart';
import 'placeholder_screen.dart';

/// Pokes GoRouter to re-run the redirect whenever the auth stream emits
/// (sign-in, sign-out, user reload flipping emailVerified).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final refresh = GoRouterRefreshStream(authService.userChanges());
  ref.onDispose(refresh.dispose);

  String? from(GoRouterState state) =>
      sanitizeFrom(state.uri.queryParameters['from']);

  // Screens whose build session hasn't landed yet render an honest
  // placeholder; the routes themselves are final.
  Widget shellStub(String title, {String? detail, Widget? action}) =>
      PlaceholderScreen(title: title, detail: detail, action: action);

  Widget standaloneStub(String title, {String? detail}) =>
      ClosScaffold(body: PlaceholderScreen(title: title, detail: detail));

  final router = GoRouter(
    refreshListenable: refresh,
    initialLocation: DashboardRoute.path,
    redirect: (context, state) {
      final user = authService.currentUser;
      return authRedirect(
        signedIn: user != null,
        emailVerified: user?.emailVerified ?? false,
        uri: state.uri,
      );
    },
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      // Auth, outside the shell.
      GoRoute(
        path: LoginRoute.path,
        builder: (context, state) => LoginScreen(from: from(state)),
      ),
      GoRoute(
        path: SignupRoute.path,
        builder: (context, state) => SignupScreen(from: from(state)),
      ),
      GoRoute(
        path: ResetPasswordRoute.path,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: VerifyEmailRoute.path,
        builder: (context, state) => VerifyEmailScreen(from: from(state)),
      ),

      // Standalone signed-in screens (no sidebar).
      GoRoute(
        path: OnboardingRoute.path,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: ColdCallSimRoute.path,
        builder: (context, state) => standaloneStub(
          'Cold call session',
          detail: state.pathParameters['scenarioId'],
        ),
      ),
      GoRoute(
        path: VideoSimRoute.path,
        builder: (context, state) => standaloneStub(
          'Video session',
          detail: state.pathParameters['scenarioId'],
        ),
      ),
      // Deep-link contract, registered from day one.
      GoRoute(
        path: ScoreRoute.path,
        builder: (context, state) => standaloneStub(
          'Session score',
          detail: state.pathParameters['sessionId'],
        ),
        routes: [
          GoRoute(
            path: ScoreTranscriptRoute.subPath,
            builder: (context, state) {
              final moment = state.uri.queryParameters['moment'];
              return standaloneStub(
                'Transcript',
                detail: [
                  state.pathParameters['sessionId'],
                  if (moment != null) 'moment $moment',
                ].join(', '),
              );
            },
          ),
        ],
      ),

      // The sidebar shell.
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(currentPath: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: DashboardRoute.path,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: SimulationsRoute.path,
            builder: (context, state) => shellStub('Simulations'),
          ),
          GoRoute(
            path: ProgressRoute.path,
            builder: (context, state) => shellStub('My progress'),
          ),
          GoRoute(
            path: MethodologiesRoute.path,
            builder: (context, state) => shellStub('Methodologies'),
          ),
          GoRoute(
            path: AchievementsRoute.path,
            builder: (context, state) => shellStub('Achievements'),
          ),
          GoRoute(
            path: SettingsRoute.path,
            builder: (context, state) => shellStub(
              'Settings',
              // Temporary until the settings session lands: the only
              // way out of a signed-in session lives here.
              action: GhostButton(
                label: 'Log out',
                onPressed: authService.signOut,
              ),
            ),
          ),
          GoRoute(
            path: SettingsPasswordRoute.path,
            builder: (context, state) => shellStub('Change password'),
          ),
          GoRoute(
            path: SettingsConnectedRoute.path,
            builder: (context, state) => shellStub('Connected accounts'),
          ),
          GoRoute(
            path: SettingsDeleteRoute.path,
            builder: (context, state) => shellStub('Delete account'),
          ),
          GoRoute(
            path: UpgradeRoute.path,
            builder: (context, state) => shellStub('Upgrade'),
          ),
          GoRoute(
            path: SessionLimitRoute.path,
            builder: (context, state) => shellStub('Session limit'),
          ),
          GoRoute(
            path: UpgradeSuccessRoute.path,
            builder: (context, state) => shellStub('Upgrade complete'),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
