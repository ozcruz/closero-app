import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../scoring/domain/session_doc.dart';
import '../application/sim_controller.dart';
import '../domain/sim_script.dart';
import '../domain/sim_session.dart';
import 'sim_host.dart';
import 'sim_widgets.dart';

/// Live Cold Call (prototype-screens/05-live-cold-call.png): no
/// sidebar, opaque topbar with the 2px progress stripe, audio-only
/// persona stage, coaching panel on the right (collapses under
/// 1100px).
///
/// Accent audit: the mic-on control is this screen's one accent-filled
/// element.
class ColdCallSimScreen extends StatelessWidget {
  const ColdCallSimScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  Widget build(BuildContext context) {
    return ClosScaffold(
      body: SimHost(
        scenarioId: scenarioId,
        simType: SimType.coldCall,
        script: coldCallScript,
        builder: (context, controller, onEndCall) => ColdCallView(
          script: coldCallScript,
          elapsedSec: controller.elapsedSec,
          personaSpeaking: controller.personaSpeaking,
          muted: controller.muted,
          nextMove: controller.nextMove,
          hints: controller.hints,
          transcript: controller.transcript,
          goodCount: controller.goodCount,
          onToggleMuted: controller.toggleMuted,
          onEndCall:
              controller.phase == SimPhase.live ? onEndCall : null,
        ),
      ),
    );
  }
}

/// The pure live layout; the host feeds it controller state, goldens
/// feed it fixtures.
class ColdCallView extends StatelessWidget {
  const ColdCallView({
    super.key,
    required this.script,
    required this.elapsedSec,
    required this.personaSpeaking,
    required this.muted,
    required this.nextMove,
    required this.hints,
    required this.transcript,
    required this.goodCount,
    required this.onToggleMuted,
    required this.onEndCall,
  });

  final SimScript script;
  final int elapsedSec;
  final bool personaSpeaking;
  final bool muted;
  final SimNextMove? nextMove;
  final List<SimHint> hints;
  final List<Utterance> transcript;
  final int goodCount;
  final VoidCallback onToggleMuted;
  final VoidCallback? onEndCall;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kSimPanelBreakpoint;

        final stage = Column(
          children: [
            const Spacer(flex: 3),
            RingedAvatar(
              initials: script.personaInitials,
              tint: script.tint,
              personaName: script.personaName,
            ),
            SizedBox(height: sp.sp6),
            Text(script.personaName, style: context.closType.headlineMedium),
            SizedBox(height: sp.sp3),
            Text(
              script.personaRole,
              style: ClosType.style(
                fontSize: 13,
                weight: FontWeight.w400,
                color: colors.mid,
              ),
            ),
            SizedBox(height: sp.sp5),
            SpeakingIndicator(
              personaShortName: script.personaShortName,
              speaking: personaSpeaking,
            ),
            const Spacer(flex: 2),
            MicControls(
              muted: muted,
              onToggleMuted: onToggleMuted,
              onEndCall: onEndCall,
            ),
            SizedBox(height: sp.sp8),
            if (!wide) CollapsedMomentumFooter(goodCount: goodCount),
          ],
        );

        return Column(
          children: [
            SimTopbar(
              kindLabel: 'Cold call',
              scenarioLabel: script.scenarioLabel,
              elapsedSec: elapsedSec,
              onEndCall: onEndCall,
            ),
            SimProgressStripe(
              progress: elapsedSec / (script.estimatedMinutes * 60),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: stage),
                  if (wide)
                    CoachingPanel(
                      personaShortName: script.personaShortName,
                      nextMove: nextMove,
                      hints: hints,
                      transcript: transcript,
                      goodCount: goodCount,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
