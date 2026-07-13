/// Compile-time feature flags, set with --dart-define.
library;

/// Apple SSO stays hidden until an Apple Developer account is configured.
/// Enable with: flutter build web --dart-define=APPLE_SSO=true
const bool kAppleSsoEnabled = bool.fromEnvironment('APPLE_SSO');

/// Mounts the Rive avatar rig on the Video Sim stage and loops the
/// bundled lipsync test clip against its canned viseme timeline.
/// Debug harness only; the live pipeline (Session 14) mounts the rig
/// for real. Enable with: flutter run --dart-define=AVATAR_RIG_DEMO=true
const bool kAvatarRigDemo = bool.fromEnvironment('AVATAR_RIG_DEMO');
