import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/billing/presentation/session_limit_screen.dart';
import '../../features/billing/presentation/upgrade_screen.dart';
import '../../features/billing/presentation/upgrade_success_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/methodologies/presentation/methodologies_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/scoring/presentation/score_screen.dart';
import '../../features/scoring/presentation/transcript_screen.dart';
import '../../features/settings/presentation/change_password_screen.dart';
import '../../features/settings/presentation/connected_accounts_screen.dart';
import '../../features/settings/presentation/delete_account_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sim/presentation/cold_call_screen.dart';
import '../../features/sim/presentation/video_sim_screen.dart';
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
      // The billing wall lives outside the shell per prototypes 16-18:
      // brand-ring topbar, no sidebar.
      GoRoute(
        path: UpgradeRoute.path,
        builder: (context, state) => UpgradeScreen(
          source: state.uri.queryParameters['source'],
        ),
      ),
      GoRoute(
        path: SessionLimitRoute.path,
        builder: (context, state) => const SessionLimitScreen(),
      ),
      GoRoute(
        path: UpgradeSuccessRoute.path,
        builder: (context, state) => const UpgradeSuccessScreen(),
      ),
      GoRoute(
        path: ColdCallSimRoute.path,
        builder: (context, state) => ColdCallSimScreen(
          scenarioId: state.pathParameters['scenarioId']!,
        ),
      ),
      GoRoute(
        path: VideoSimRoute.path,
        builder: (context, state) => VideoSimScreen(
          scenarioId: state.pathParameters['scenarioId']!,
        ),
      ),
      // Post-call score + transcript. Deep-link contract from day one.
      GoRoute(
        path: ScoreRoute.path,
        builder: (context, state) =>
            ScoreScreen(sessionId: state.pathParameters['sessionId']!),
        routes: [
          GoRoute(
            path: ScoreTranscriptRoute.subPath,
            builder: (context, state) => TranscriptScreen(
              sessionId: state.pathParameters['sessionId']!,
              moment: int.tryParse(
                state.uri.queryParameters['moment'] ?? '',
              ),
            ),
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
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: ProgressRoute.path,
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: MethodologiesRoute.path,
            builder: (context, state) => const MethodologiesScreen(),
          ),
          GoRoute(
            path: AchievementsRoute.path,
            builder: (context, state) => const AchievementsScreen(),
          ),
          GoRoute(
            path: SettingsRoute.path,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: SettingsPasswordRoute.path,
            builder: (context, state) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: SettingsConnectedRoute.path,
            builder: (context, state) => const ConnectedAccountsScreen(),
          ),
          GoRoute(
            path: SettingsDeleteRoute.path,
            builder: (context, state) => const DeleteAccountScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
