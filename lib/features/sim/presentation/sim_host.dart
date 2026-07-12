import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../application/sim_controller.dart';
import '../data/scripted_sim_session.dart';
import '../data/sim_gate.dart';
import '../domain/sim_script.dart';
import 'sim_widgets.dart';

/// Shared lifecycle for both sim screens: builds the controller for a
/// script, runs the gate on mount, routes cap hits to Session limit
/// and finished sessions to the post-call score, and hosts the exit
/// confirm. The [builder] renders the live layout.
class SimHost extends ConsumerStatefulWidget {
  const SimHost({super.key, required this.script, required this.builder});

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

  @override
  void initState() {
    super.initState();
    _controller = SimController(
      gate: ref.read(simGateProvider),
      createSession: () => ScriptedSimSession(widget.script),
    );
    _controller.addListener(_onControllerChanged);
    _controller.start();
  }

  void _onControllerChanged() {
    if (!mounted || _routedAway) return;
    switch (_controller.phase) {
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
