import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/analytics_events.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/feature_flags.dart';
import '../../auth/application/auth_providers.dart';
import '../../scoring/domain/session_doc.dart';
import '../application/sim_controller.dart';
import '../data/scripted_sim_session.dart';
import '../data/sim_gate.dart';
import '../data/sim_session_factory.dart';
import '../data/tts_player.dart';
import '../domain/sim_script.dart';
import '../domain/sim_session.dart';
import 'sim_preflight.dart';
import 'sim_widgets.dart';

/// Shared lifecycle for both sim screens: builds the controller for a
/// script, runs the gate on mount, routes cap hits to Session limit
/// and finished sessions to the post-call score, and hosts the exit
/// confirm. The [builder] renders the live layout.
///
/// The session is live or scripted per [scenarioId]
/// ([liveScenarioEnabled]), so personas roll onto the broker one at a
/// time; the screens are identical either way (Session 11 contract).
class SimHost extends ConsumerStatefulWidget {
  const SimHost({
    super.key,
    required this.scenarioId,
    required this.simType,
    required this.script,
    required this.builder,
  });

  final String scenarioId;
  final SimType simType;
  final SimScript script;

  /// Renders the live phase. [onEndCall] opens the exit confirm.
  final Widget Function(
    BuildContext context,
    SimController controller,
    VoidCallback onEndCall,
  ) builder;

  @override
  ConsumerState<SimHost> createState() => _SimHostState();
}

class _SimHostState extends ConsumerState<SimHost> {
  late final SimController _controller;

  /// Whether this scenario runs on the live broker pipeline (device
  /// check + real mic + audio) or the scripted stand-in (starts at once).
  late final bool _isLive;

  bool _routedAway = false;

  /// Live path only: the gate does not run until the user taps Start in
  /// the preflight, so a denied mic never burns a session.
  bool _started = false;

  /// Live path only: a player built early and preloaded so the Start tap
  /// can prime it inside the user gesture (Safari autoplay unlock). It is
  /// consumed by the first session; disposed here if never consumed.
  TtsPlayer? _primedPlayer;

  /// Last phase an analytics event fired for, so each lifecycle event
  /// fires once per transition rather than on every notifyListeners.
  SimPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _isLive = liveScenarioEnabled(widget.scenarioId);
    _controller = SimController(
      gate: ref.read(simGateProvider),
      createSession: _buildSession,
      // Only a granted live session can be refunded; the scripted path
      // never touches the gate's cap in a refundable way.
      abort: _isLive ? ref.read(simAbortProvider) : null,
    );
    _controller.addListener(_onControllerChanged);
    if (_isLive) {
      // Build + preload the player now so the Start tap can prime it in
      // the user gesture. The gate waits for that tap (device check
      // first), so a denied mic never reaches startSimSession.
      final player = ref.read(ttsPlayerFactoryProvider)();
      _primedPlayer = player;
      unawaited(player.preload());
    } else {
      _started = true;
      _controller.start();
    }
  }

  /// The preflight Start tap: a user gesture. Prime audio here (unblocks
  /// Safari), then run the gate + session.
  void _handleStart() {
    unawaited(_primedPlayer?.prime() ?? Future<void>.value());
    setState(() => _started = true);
    _controller.start();
  }

  SimSession _buildSession(String requestId) {
    if (_isLive) {
      // Consume the primed player once; a retry builds a fresh one (the
      // page's audio context is already unlocked by the first prime).
      final player = _primedPlayer;
      _primedPlayer = null;
      return ref.read(liveSessionBuilderProvider)(
        requestId: requestId,
        scenarioId: widget.scenarioId,
        simType: widget.simType,
        ttsPlayer: player,
      );
    }
    return ScriptedSimSession(widget.script);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final phase = _controller.phase;
    if (phase != _lastPhase) {
      _lastPhase = phase;
      _fireAnalyticsFor(phase);
    }
    if (_routedAway) return;
    switch (phase) {
      case SimPhase.capBlocked:
        _routedAway = true;
        const SessionLimitRoute().go(context);
      case SimPhase.ended:
        _routedAway = true;
        ScoreRoute(sessionId: _controller.result!.sessionId).go(context);
      default:
        // aborted and startFailed stay put and show their own screen.
        break;
    }
  }

  /// One lifecycle event per phase transition. sim_start carries the
  /// tier; sim_completed carries the call duration (the score is
  /// server-written and not known yet, so its band rides score_viewed).
  /// sim_aborted here is the start-failure path; richer mid-call abort
  /// reasons arrive with the Session 16 abort/refund flow.
  void _fireAnalyticsFor(SimPhase phase) {
    final analytics = ref.read(analyticsServiceProvider);
    switch (phase) {
      case SimPhase.live:
        analytics.capture(AnalyticsEvents.simStart, properties: {
          AnalyticsProps.scenarioId: widget.scenarioId,
          AnalyticsProps.simType: widget.simType.schemaValue,
          AnalyticsProps.tier: ref.read(entitlementProvider).name,
        });
      case SimPhase.capBlocked:
        analytics.capture(AnalyticsEvents.capHit, properties: {
          AnalyticsProps.scenarioId: widget.scenarioId,
          AnalyticsProps.simType: widget.simType.schemaValue,
        });
      case SimPhase.ended:
        analytics.capture(AnalyticsEvents.simCompleted, properties: {
          AnalyticsProps.scenarioId: widget.scenarioId,
          AnalyticsProps.simType: widget.simType.schemaValue,
          AnalyticsProps.durationSec: _controller.elapsedSec,
          AnalyticsProps.sessionId: _controller.result!.sessionId,
        });
      case SimPhase.startFailed:
        analytics.capture(AnalyticsEvents.simAborted, properties: {
          AnalyticsProps.scenarioId: widget.scenarioId,
          AnalyticsProps.simType: widget.simType.schemaValue,
          AnalyticsProps.reason: 'start_failed',
        });
      case SimPhase.aborted:
        analytics.capture(AnalyticsEvents.simAborted, properties: {
          AnalyticsProps.scenarioId: widget.scenarioId,
          AnalyticsProps.simType: widget.simType.schemaValue,
          AnalyticsProps.reason: _controller.abortReason ?? 'unknown',
        });
      case SimPhase.requesting:
      case SimPhase.ending:
        break;
    }
  }

  Future<void> _confirmEnd() async {
    final confirmed = await showEndSessionModal(
      context,
      personaShortName: widget.script.personaShortName,
      elapsedSec: _controller.elapsedSec,
      estimatedMinutes: widget.script.estimatedMinutes,
    );
    if (confirmed) await _controller.endSession();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    // The primed player is disposed by the session that consumes it; if
    // the attempt never got that far (cap, back-out), dispose it here.
    unawaited(_primedPlayer?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Live path: run the device check before anything touches the gate.
    if (_isLive && !_started) {
      return SimPreflight(
        script: widget.script,
        onStart: _handleStart,
        onBack: () => const SimulationsRoute().go(context),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => switch (_controller.phase) {
        // capBlocked routes away on the next frame; hold the quiet
        // connecting frame rather than flashing an empty call.
        SimPhase.requesting || SimPhase.capBlocked => SimConnecting(
            personaName: widget.script.personaName,
            initials: widget.script.personaInitials,
            tint: widget.script.tint,
          ),
        SimPhase.startFailed => SimStartFailed(
            onRetry: _controller.retryStart,
            onBack: () => const SimulationsRoute().go(context),
          ),
        SimPhase.aborted => SimAborted(
            refundConfirmed: _controller.refundConfirmed,
            onRetry: _controller.retryStart,
            onBack: () => const SimulationsRoute().go(context),
          ),
        // capBlocked and ended route away on the next frame; keep the
        // last live frame underneath rather than flashing blank.
        _ => _liveView(context),
      },
    );
  }

  /// The live layout, with the reconnecting banner floated over it while
  /// the link is down (the clock is paused underneath).
  Widget _liveView(BuildContext context) {
    final live = widget.builder(context, _controller, _confirmEnd);
    if (!_controller.reconnecting) return live;
    return Stack(
      children: [
        live,
        const Positioned(
          top: 64,
          left: 0,
          right: 0,
          child: Center(child: ReconnectingBanner()),
        ),
      ],
    );
  }
}
