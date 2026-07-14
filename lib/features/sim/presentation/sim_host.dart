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
import '../domain/sim_script.dart';
import '../domain/sim_session.dart';
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
  bool _routedAway = false;

  /// Last phase an analytics event fired for, so each lifecycle event
  /// fires once per transition rather than on every notifyListeners.
  SimPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _controller = SimController(
      gate: ref.read(simGateProvider),
      createSession: _buildSession,
    );
    _controller.addListener(_onControllerChanged);
    _controller.start();
  }

  SimSession _buildSession(String requestId) {
    if (liveScenarioEnabled(widget.scenarioId)) {
      return ref.read(liveSessionBuilderProvider)(
        requestId: requestId,
        scenarioId: widget.scenarioId,
        simType: widget.simType,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        // capBlocked and ended route away on the next frame; keep the
        // last live frame underneath rather than flashing blank.
        _ => widget.builder(context, _controller, _confirmEnd),
      },
    );
  }
}
