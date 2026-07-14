import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_config.dart';
import 'posthog_analytics_service.dart';

/// Product analytics behind an interface, so a no-op runs in tests and
/// in any build without a PostHog key configured. Screens never touch
/// PostHog directly; they read [analyticsServiceProvider] and call
/// [capture].
///
/// Identity contract: [identify] takes the Firebase uid ONLY. No email,
/// displayName, or transcript content ever enters this layer (see
/// analytics_events.dart).
abstract interface class AnalyticsService {
  /// Associates subsequent events with [uid] (the Firebase uid). Called
  /// once per sign-in by the analytics observer.
  void identify(String uid);

  /// Records [event] (an [AnalyticsEvents] const) with optional
  /// [properties] (an [AnalyticsProps]-keyed map). Fire and forget:
  /// analytics never blocks or fails a user flow.
  void capture(String event, {Map<String, Object>? properties});

  /// Clears the identified user on sign-out.
  void reset();
}

/// Does nothing. The default in tests and in any build where
/// [kPosthogApiKey] is unset.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  void identify(String uid) {}

  @override
  void capture(String event, {Map<String, Object>? properties}) {}

  @override
  void reset() {}
}

/// Real analytics only when a key is compiled in; the no-op otherwise,
/// so `flutter test` and unconfigured builds never reach PostHog.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  if (kPosthogApiKey.isEmpty) return const NoopAnalyticsService();
  return const PosthogAnalyticsService();
});
