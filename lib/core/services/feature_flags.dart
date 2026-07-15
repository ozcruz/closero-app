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

/// Base wss:// origin of the session broker, e.g.
/// `wss://closero-session-broker.<subdomain>.workers.dev`. The live
/// pipeline appends `/v1/session/{requestId}`. Empty by default so a
/// build without it configured never attempts a live session.
/// Set with: flutter build web --dart-define=BROKER_WSS_BASE=wss://...
const String kBrokerWssBase = String.fromEnvironment('BROKER_WSS_BASE');

/// Comma-separated scenarioIds routed onto the live broker pipeline;
/// every other scenario stays on ScriptedSimSession. This is how
/// personas roll onto live one at a time. Empty by default (all
/// scripted). Set with:
/// flutter build web --dart-define=LIVE_SCENARIOS=cold-call-saas-gatekeeper,discovery-roi-first-marcus
const String _kLiveScenarios = String.fromEnvironment('LIVE_SCENARIOS');

/// Actual browser mic capture rate in Hz, when it differs from the
/// requested 16 kHz. Browsers often ignore the `record` sampleRate
/// constraint and capture at the AudioContext's native rate (commonly
/// 48000); if a real-device check confirms that, set this so mic audio
/// is downsampled to the broker's 16 kHz STT rate before it goes on the
/// wire. 0 (default) trusts the requested rate and resamples nothing.
/// Set with: flutter build web --dart-define=MIC_INPUT_RATE=48000
const int kMicInputRateHz = int.fromEnvironment('MIC_INPUT_RATE');

/// Whether [scenarioId] runs on the live pipeline. Requires both a
/// configured broker base and the scenario being on the allowlist, so
/// live never fires without a broker to talk to.
bool liveScenarioEnabled(String scenarioId) {
  if (kBrokerWssBase.isEmpty || _kLiveScenarios.isEmpty) return false;
  return _kLiveScenarios
      .split(',')
      .map((s) => s.trim())
      .contains(scenarioId);
}
