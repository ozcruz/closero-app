# Session 14: live sim pipeline (client)

Built 2026-07-13. Implements `LiveSimSession` against the broker wire
protocol (closero-broker `docs/PROTOCOL.md` / `src/protocol.ts`) behind
the existing `SimSession` interface, so the screens are untouched: which
implementation a scenario uses is a feature-flag decision, not a rewrite.

Prototype screens matched: none new. This is the runtime behind the
Session 11 Cold Call (`05-live-cold-call.png`) and Video Sim
(`06-live-video.png`) screens; the layouts are unchanged.

## What shipped

New (`lib/features/sim/data/`):
- `broker_protocol.dart` — Dart mirror of the v1 wire protocol: client
  encoders (hello/cancel/played/end/abort/ping), a sealed decoder for
  every server message, the 8-byte little-endian TTS binary frame, close
  codes, constants. Decoding is fail-soft: unknown `type` or malformed
  payload returns null (never crashes a live call).
- `broker_connection.dart` — `BrokerConnection` (WSS transport) +
  `WebSocketBrokerConnection` over `web_socket_channel`.
- `mic_source.dart` — `MicSource` + `RecordMicSource` (record plugin,
  PCM16LE mono 16 kHz, `echoCancel` on) and `pcm16Rms` for the local
  input level and VAD. AEC is mandatory: the mic runs during persona
  playback.
- `tts_player.dart` — `TtsPlayer` + `JustAudioTtsPlayer`: buffers each
  utterance's chunks, starts playback at `utteranceEnd` from a data-URI
  source, plays utterances back to back in id order, exposes each one's
  playback-position stream and the current `playing` position, and
  supports `stopCurrent` / `interruptFrom` for barge-in.
- `live_sim_session.dart` — the orchestrator (`SimSession`). Owns the
  connection, mic, player, and `VisemeScheduler`. Pure Dart, no
  Flutter/Rive imports, fully unit-tested.
- `sim_session_factory.dart` — composition root: `liveSessionBuilderProvider`
  wires the real transport/mic/playback + Firebase id token.

New (`lib/features/sim/presentation/`):
- `live_avatar_stack.dart` — mounts the Rive avatar for a live Video Sim
  and drives its mouth from the session's `visemeGroups` stream. The Rive
  controller lifecycle lives here (Session 12's `RiveAvatarController`,
  reused, no new Rive code); the session only emits mouth-group ints.

Changed:
- `feature_flags.dart` — `kBrokerWssBase`, `LIVE_SCENARIOS`, and
  `liveScenarioEnabled(scenarioId)` (needs both a broker base and the
  scenario on the allowlist).
- `sim_gate.dart` — `newSimRequestId()` now returns a UUIDv4. The broker
  enforces `[A-Za-z0-9_-]{20,128}`; the old base36 id could fall under 20.
- `sim_session.dart` — added `setMuted({required bool muted})`.
- `sim_controller.dart` — the session factory now takes the `requestId`
  (same id the gate granted, so a live session addresses the broker with
  it); wires mute, the `visemeGroups` stream, server-initiated end
  (time cap), and a start-failure path.
- `sim_host.dart` / `cold_call_screen.dart` / `video_sim_screen.dart` —
  thread `scenarioId` + `simType`; the Video Sim mounts the live avatar.

Tests: `broker_protocol_test.dart` (encode/decode round-trips, binary
frame), `live_sim_session_test.dart` (hello handshake, transcript/hint
mapping, utterance buffer → viseme-against-playback → played ack, server
interrupt flush, flag-gated client VAD, mute gating, end → scored,
unexpected close). Full suite green (324 tests); `flutter analyze` clean;
`flutter build web` (incl. wasm dry run) clean.

## Barge-in model (as built)

The client is barge-in READY, not turn-locked:
- The mic streams for the whole call, including during persona playback,
  so the broker's STT never stops.
- Playback is interruptible: on a trigger we stop local audio, rest the
  avatar (viseme 0), and send `cancel` with the exact `playing` position
  (so the broker truncates the persona transcript to what was heard),
  without waiting for `interrupted`.
- Two triggers, both gated the same way as the broker:
  - Server trigger: broker sends an unprompted `interrupted` (reason
    `barge_in`) only when `INTERRUPT_TRIGGER_ENABLED`. Always handled.
  - Client local VAD: fires a `client_vad` cancel only when the broker
    reported `interruptTriggerEnabled: true` in `ready`. Conservative:
    a clear sustained utterance (>= 700 ms over threshold), once per
    reply, never a backchannel.
- Launch default is OFF on both sides (`INTERRUPT_TRIGGER_ENABLED:false`
  in the broker), so at launch the persona finishes its turn. Flip the
  broker flag and barge-in activates with zero client changes.

## Rolling a persona onto live (the flag mechanism)

Live requires BOTH:
1. `--dart-define=BROKER_WSS_BASE=wss://<broker-host>` set at build time.
2. `--dart-define=LIVE_SCENARIOS=<id>,<id>` listing the scenarioIds to
   route live. Everything else stays on ScriptedSimSession.

Example (Sandra + Marcus live, everyone else scripted):
```
flutter build web \
  --dart-define=BROKER_WSS_BASE=wss://closero-session-broker.<subdomain>.workers.dev \
  --dart-define=LIVE_SCENARIOS=cold-call-saas-gatekeeper,discovery-roi-first-marcus
```
scenarioIds come from `scenario_repository.dart` (e.g.
`cold-call-saas-gatekeeper` = Sandra, `discovery-roi-first-marcus` =
Marcus). These MUST match the broker's `content/` persona keys.

## Manual work required (cannot be done from the app repo)

1. Deploy the broker with the full Session 13 session logic
   (`wrangler deploy` in closero-broker) and its one-time manual items:
   `FIREBASE_SERVICE_ACCOUNT_JSON` secret, and the Firestore composite
   index (`sessions`: uid ASC, status ASC, endedAt DESC). See the broker
   README and the session-13-broker memory.
2. Get the deployed broker wss origin and set `BROKER_WSS_BASE`
   (workers.dev subdomain, or a custom route/domain if added).
3. Configure the app build's `LIVE_SCENARIOS` for the pilot persona(s).
4. Real-browser test on Chrome AND Safari against the deployed broker
   with a signed-in test user and a real mic (cannot be done headless):
   grant mic, confirm hello → ready, persona audio plays, lipsync tracks,
   transcript + hints stream, hang up → score screen loads.

## HARD BLOCKS / pre-reqs before Session 15

1. **`startSimSession` must write the grant doc the broker checks.** The
   broker verifies `users/{uid}/simSessions/{requestId}` exists at hello
   (else close 4403). Confirm the deployed callable writes that doc keyed
   by requestId; the backend memory notes only that it increments and is
   idempotent, so this is UNVERIFIED and is a hard block for any live
   call. (Same requestId now flows gate → hello, which was also required.)
2. **Broker must be deployed and reachable**, with the scenario content
   keyed by the app's scenarioIds (else 4400 unknown_scenario at hello).
3. **Safari autoplay:** the first persona utterance starts playback from
   an `utteranceEnd` event, not directly from the user's tap, so Safari's
   autoplay policy may block it. getUserMedia (the mic grant on Start)
   usually unlocks audio in the same gesture, but this MUST be verified on
   real Safari; if blocked, prime the AudioPlayer with a short silent play
   inside the Start tap. Not reproducible headless.
4. **Mic sample rate:** `record` on web should deliver 16 kHz PCM, but
   browsers often capture at 48 kHz; verify the broker's STT (Deepgram,
   16 kHz) gets the rate it expects on Chrome and Safari. If not,
   resample client-side. Real-device check.

## Known gaps handed to Session 16 (abort/refund UX)

- A failed or dropped call does NOT yet call `abortSimSession` from the
  client. The broker refunds post-auth broker faults server-side, but a
  client-side pre-`ready` failure (mic denied, socket refused) leaves the
  gate grant consumed with no client refund. Wire `abortSimSession` on
  every unexpected close / start failure.
- `SimStartFailed` copy ("Nothing was used from your plan.") is accurate
  only when start fails BEFORE the gate grant. On the live path start can
  fail AFTER the grant; reconcile the copy with the refund path.
- No mid-call resume in v1: an unexpected close is an aborted call
  (`_onSessionError` currently just logs). Session 16 owns the UX.
- iOS target: `JustAudioTtsPlayer` uses a data URI, which web accepts but
  AVPlayer does not; the iOS target needs a temp-file audio source.
