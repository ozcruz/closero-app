/// Builds a live broker-backed session for one attempt. Kept apart from
/// [LiveSimSession] so the pure session has no Firebase/Riverpod imports
/// and stays unit-testable; this is the composition root that wires the
/// real transport, mic, playback, and auth token.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/feature_flags.dart';
import '../../auth/application/auth_providers.dart';
import '../../scoring/domain/session_doc.dart';
import 'broker_connection.dart';
import 'live_sim_session.dart';
import 'mic_source.dart';
import 'tts_player.dart';

/// Builds a [LiveSimSession] addressed by [requestId] (the same id the
/// gate granted), for [scenarioId] and [simType]. [ttsPlayer] lets the
/// caller pass a player it already primed inside the Start-tap gesture
/// (Safari autoplay unlock); null builds a fresh one.
typedef LiveSessionBuilder = LiveSimSession Function({
  required String requestId,
  required String scenarioId,
  required SimType simType,
  TtsPlayer? ttsPlayer,
});

/// Creates a fresh [TtsPlayer] per attempt. Overridable in tests; the
/// host reads it to build the player early enough to prime it in the
/// user's Start gesture.
final ttsPlayerFactoryProvider = Provider<TtsPlayer Function()>(
  (ref) => JustAudioTtsPlayer.new,
);

/// The session broker WSS URL for a request: base origin + the versioned
/// per-session path the broker routes on.
Uri brokerSessionUri(String base, String requestId) {
  final trimmed = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return Uri.parse('$trimmed/v1/session/$requestId');
}

/// Factory for live sessions, reading auth + broker config from the
/// container. Real transport/mic/playback are fresh per attempt.
final liveSessionBuilderProvider = Provider<LiveSessionBuilder>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final makePlayer = ref.watch(ttsPlayerFactoryProvider);
  return ({
    required String requestId,
    required String scenarioId,
    required SimType simType,
    TtsPlayer? ttsPlayer,
  }) =>
      LiveSimSession(
        requestId: requestId,
        scenarioId: scenarioId,
        simType: simType,
        fetchIdToken: () async {
          final user = auth.currentUser;
          return user == null ? null : await user.getIdToken();
        },
        openConnection: () =>
            WebSocketBrokerConnection(brokerSessionUri(kBrokerWssBase, requestId)),
        micSource: RecordMicSource(),
        ttsPlayer: ttsPlayer ?? makePlayer(),
        // Bounded auto-reconnect for a mid-call socket drop; without a
        // policy a drop aborts immediately (the scripted path never
        // reaches here).
        reconnect: const ReconnectPolicy(),
      );
});
