/// Platform entry point for initializing posthog-js on web. Resolves to
/// [analytics_bootstrap_web.dart] on web (JS interop init) and to
/// [analytics_bootstrap_stub.dart] elsewhere (no-op; the native SDK
/// initializes through Posthog().setup on the later iOS target).
library;

export 'analytics_bootstrap_stub.dart'
    if (dart.library.js_interop) 'analytics_bootstrap_web.dart';
