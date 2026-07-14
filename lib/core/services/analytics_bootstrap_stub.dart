/// Non-web targets: no HTML posthog-js to initialize. The native
/// posthog_flutter SDK initializes through Posthog().setup instead.
Future<void> bootstrapPosthogJs({
  required String apiKey,
  required String host,
}) async {}
