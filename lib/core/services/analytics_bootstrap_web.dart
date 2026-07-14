import 'dart:js_interop';

import 'package:flutter/foundation.dart';

/// On web, posthog_flutter does NOT call `posthog.init()`; it only hooks
/// into an existing posthog-js instance (see the plugin's web setup).
/// web/index.html loads the posthog-js stub with NO key baked in, and
/// this initializes it with the --dart-define key so nothing sensitive
/// lives in committed HTML.
///
/// Only explicit product events fire: autocapture, pageviews, dead
/// clicks, heatmaps, surveys, exception capture, and session recording
/// are all disabled, so no page content (which could include transcript
/// text) is ever collected automatically.
@JS('posthog.init')
external void _posthogInit(String apiKey, JSObject options);

Future<void> bootstrapPosthogJs({
  required String apiKey,
  required String host,
}) async {
  final options = <String, Object>{
    'api_host': host,
    'autocapture': false,
    'capture_pageview': false,
    'capture_pageleave': false,
    'disable_session_recording': true,
    'disable_surveys': true,
    'rageclick': false,
    'enable_heatmaps': false,
    'capture_dead_clicks': false,
    'capture_exceptions': false,
  }.jsify()! as JSObject;
  try {
    _posthogInit(apiKey, options);
  } on Object catch (e) {
    // The loader stub is missing or failed to load. Analytics stays
    // dark; the app is unaffected.
    debugPrint('posthog-js init failed: $e');
  }
}
