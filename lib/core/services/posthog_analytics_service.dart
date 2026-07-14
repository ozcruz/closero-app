import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'analytics_service.dart';

/// PostHog-backed analytics. capture/identify/reset proxy to the
/// Posthog() singleton: posthog-js on web (initialized from the
/// --dart-define key by analytics_bootstrap_web.dart), native on the
/// later iOS target.
///
/// Every call is fire and forget and guarded: a failed send is logged in
/// debug and swallowed, never surfaced to the user or awaited on a hot
/// path.
class PosthogAnalyticsService implements AnalyticsService {
  const PosthogAnalyticsService();

  @override
  void identify(String uid) =>
      _send(() => Posthog().identify(userId: uid));

  @override
  void capture(String event, {Map<String, Object>? properties}) => _send(
        () => Posthog().capture(eventName: event, properties: properties),
      );

  @override
  void reset() => _send(() => Posthog().reset());

  void _send(Future<void> Function() op) {
    unawaited(() async {
      try {
        await op();
      } on Object catch (e) {
        debugPrint('analytics send failed: $e');
      }
    }());
  }
}
