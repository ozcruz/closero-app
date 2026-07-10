/// Compile-time feature flags, set with --dart-define.
library;

/// Apple SSO stays hidden until an Apple Developer account is configured.
/// Enable with: flutter build web --dart-define=APPLE_SSO=true
const bool kAppleSsoEnabled = bool.fromEnvironment('APPLE_SSO');
