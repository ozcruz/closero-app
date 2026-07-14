import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Typed routes for every screen in the build plan. Screens navigate with
/// `const DashboardRoute().go(context)` or
/// `ScoreRoute(sessionId: id).go(context)`; raw location strings never
/// appear outside this file and the router table.
sealed class AppRoute {
  const AppRoute();

  String get location;

  void go(BuildContext context) => context.go(location);

  void push(BuildContext context) => context.push(location);
}

String? _query(Map<String, String?> params) {
  final entries = params.entries.where((e) => e.value != null).map(
      (e) => '${e.key}=${Uri.encodeQueryComponent(e.value!)}');
  return entries.isEmpty ? null : entries.join('&');
}

// ── Auth (outside the shell) ─────────────────────────────────────────

class LoginRoute extends AppRoute {
  const LoginRoute({this.from});

  static const path = '/login';

  /// In-app location to return to after auth; must start with '/'.
  final String? from;

  @override
  String get location {
    final q = _query({'from': from});
    return q == null ? path : '$path?$q';
  }
}

class SignupRoute extends AppRoute {
  const SignupRoute({this.from});

  static const path = '/signup';

  final String? from;

  @override
  String get location {
    final q = _query({'from': from});
    return q == null ? path : '$path?$q';
  }
}

class ResetPasswordRoute extends AppRoute {
  const ResetPasswordRoute();

  static const path = '/reset-password';

  @override
  String get location => path;
}

class VerifyEmailRoute extends AppRoute {
  const VerifyEmailRoute({this.from});

  static const path = '/verify-email';

  final String? from;

  @override
  String get location {
    final q = _query({'from': from});
    return q == null ? path : '$path?$q';
  }
}

// ── Standalone (signed in, no sidebar) ───────────────────────────────

class OnboardingRoute extends AppRoute {
  const OnboardingRoute();

  static const path = '/onboarding';

  @override
  String get location => path;
}

class ColdCallSimRoute extends AppRoute {
  const ColdCallSimRoute({required this.scenarioId});

  static const path = '/sim/cold-call/:scenarioId';

  final String scenarioId;

  @override
  String get location => '/sim/cold-call/${Uri.encodeComponent(scenarioId)}';
}

class VideoSimRoute extends AppRoute {
  const VideoSimRoute({required this.scenarioId});

  static const path = '/sim/video/:scenarioId';

  final String scenarioId;

  @override
  String get location => '/sim/video/${Uri.encodeComponent(scenarioId)}';
}

/// Post-call score. Deep-linkable: registered from day one.
class ScoreRoute extends AppRoute {
  const ScoreRoute({required this.sessionId});

  static const path = '/score/:sessionId';

  final String sessionId;

  @override
  String get location => '/score/${Uri.encodeComponent(sessionId)}';
}

/// Full transcript, deep-linkable from Key Moments with an optional
/// moment index.
class ScoreTranscriptRoute extends AppRoute {
  const ScoreTranscriptRoute({required this.sessionId, this.moment});

  /// Relative to [ScoreRoute.path] in the route table.
  static const subPath = 'transcript';

  final String sessionId;
  final int? moment;

  @override
  String get location {
    final base = '/score/${Uri.encodeComponent(sessionId)}/transcript';
    return moment == null ? base : '$base?moment=$moment';
  }
}

// ── Shell (sidebar) screens ──────────────────────────────────────────

class DashboardRoute extends AppRoute {
  const DashboardRoute();

  static const path = '/';

  @override
  String get location => path;
}

class SimulationsRoute extends AppRoute {
  const SimulationsRoute();

  static const path = '/simulations';

  @override
  String get location => path;
}

class ProgressRoute extends AppRoute {
  const ProgressRoute();

  static const path = '/progress';

  @override
  String get location => path;
}

class AchievementsRoute extends AppRoute {
  const AchievementsRoute();

  static const path = '/achievements';

  @override
  String get location => path;
}

class MethodologiesRoute extends AppRoute {
  const MethodologiesRoute();

  static const path = '/methodologies';

  @override
  String get location => path;
}

class SettingsRoute extends AppRoute {
  const SettingsRoute();

  static const path = '/settings';

  @override
  String get location => path;
}

class SettingsPasswordRoute extends AppRoute {
  const SettingsPasswordRoute();

  static const path = '/settings/password';

  @override
  String get location => path;
}

class SettingsConnectedRoute extends AppRoute {
  const SettingsConnectedRoute();

  static const path = '/settings/connected';

  @override
  String get location => path;
}

class SettingsDeleteRoute extends AppRoute {
  const SettingsDeleteRoute();

  static const path = '/settings/delete';

  @override
  String get location => path;
}

class UpgradeRoute extends AppRoute {
  const UpgradeRoute({this.source});

  static const path = '/upgrade';

  /// Where the user came from ('cap' | 'locked_card' | 'settings', the
  /// [UpgradeSource] values). Surfaces as the upgrade_screen_viewed
  /// `source` property; null for a direct visit.
  final String? source;

  @override
  String get location {
    final q = _query({'source': source});
    return q == null ? path : '$path?$q';
  }
}

class SessionLimitRoute extends AppRoute {
  const SessionLimitRoute();

  static const path = '/session-limit';

  @override
  String get location => path;
}

class UpgradeSuccessRoute extends AppRoute {
  const UpgradeSuccessRoute();

  static const path = '/upgrade-success';

  @override
  String get location => path;
}
