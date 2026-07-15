import 'package:flutter/material.dart';

import '../../../core/services/feature_flags.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../scoring/domain/session_doc.dart';
import '../application/sim_controller.dart';
import '../domain/sim_script.dart';
import '../domain/sim_session.dart';
import 'avatar_rig_demo.dart';
import 'live_avatar_stack.dart';
import 'sim_host.dart';
import 'sim_widgets.dart';

/// Live Video Sim (prototype-screens/06-live-video.png): full-screen
/// stage over the blurred office backdrop, frosted topbar overlaid,
/// same coaching panel as the Cold Call. The avatar stays on the
/// AvatarStack gradient placeholder; the Rive runtime is Session 12.
///
/// Accent audit: zero accent-filled elements on this screen (mic-on
/// accent is the Cold Call's; here the live mic fills hi1).
class VideoSimScreen extends StatelessWidget {
  const VideoSimScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  Widget build(BuildContext context) {
    return ClosScaffold(
      body: SimHost(
        scenarioId: scenarioId,
        simType: SimType.video,
        script: videoSimScript,
        builder: (context, controller, onEndCall) => VideoSimView(
          script: videoSimScript,
          elapsedSec: controller.elapsedSec,
          personaSpeaking: controller.personaSpeaking,
          muted: controller.muted,
          nextMove: controller.nextMove,
          hints: controller.hints,
          transcript: controller.transcript,
          goodCount: controller.goodCount,
          visemeGroups: controller.visemeGroups,
          onToggleMuted: controller.toggleMuted,
          // End is held while reconnecting: there is no live socket to
          // carry the hang-up, and the banner already says to hold on.
          onEndCall:
              controller.phase == SimPhase.live && !controller.reconnecting
                  ? onEndCall
                  : null,
        ),
      ),
    );
  }
}

/// The pure live layout; the host feeds it controller state, goldens
/// feed it fixtures.
class VideoSimView extends StatelessWidget {
  const VideoSimView({
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
    this.visemeGroups,
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

  /// Live persona mouth-group stream; null on the scripted path (the
  /// avatar then stays on its gradient placeholder, or the demo rig
  /// under AVATAR_RIG_DEMO).
  final Stream<int>? visemeGroups;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kSimPanelBreakpoint;

        final stage = Stack(
          fit: StackFit.expand,
          children: [
            const OfficeBackdrop(),
            // The persona layer: permanent gradient placeholder. The
            // live pipeline drives the rig from the broker's visemes;
            // AVATAR_RIG_DEMO loops the canned test clip; otherwise the
            // scripted path shows the placeholder.
            Center(
              child: SizedBox(
                width: 420,
                height: 540,
                child: switch ((visemeGroups, kAvatarRigDemo)) {
                  (final Stream<int> groups, _) => LiveAvatarStack(
                      visemeGroups: groups,
                      initials: script.personaInitials,
                      tint: script.tint,
                      semanticLabel: '${script.personaName}, AI persona',
                    ),
                  (null, true) => AvatarRigDemoStack(
                      initials: script.personaInitials,
                      tint: script.tint,
                      semanticLabel: '${script.personaName}, AI persona',
                    ),
                  (null, false) => AvatarStack(
                      initials: script.personaInitials,
                      tint: script.tint,
                      semanticLabel: '${script.personaName}, AI persona',
                    ),
                },
              ),
            ),
            // Frosted topbar over the stage, stripe riding under it.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SimTopbar(
                    kindLabel: 'Video sim',
                    scenarioLabel:
                        '${script.scenarioLabel} · ${script.personaName}',
                    elapsedSec: elapsedSec,
                    onEndCall: onEndCall,
                    frosted: true,
                  ),
                  SimProgressStripe(
                    progress:
                        elapsedSec / (script.estimatedMinutes * 60),
                  ),
                ],
              ),
            ),
            // Name plate, bottom left.
            Positioned(
              left: sp.sp6,
              bottom: sp.sp6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    script.personaName,
                    style: context.closType.headlineMedium,
                  ),
                  SizedBox(height: sp.sp1),
                  Text(
                    script.personaRole,
                    style: ClosType.style(
                      fontSize: 13,
                      weight: FontWeight.w400,
                      color: colors.mid,
                    ),
                  ),
                ],
              ),
            ),
            // Speaking indicator, bottom center.
            Positioned(
              left: 0,
              right: 0,
              bottom: sp.sp8,
              child: Center(
                child: SpeakingIndicator(
                  personaShortName: script.personaShortName,
                  speaking: personaSpeaking,
                ),
              ),
            ),
            // Controls, bottom right.
            Positioned(
              right: sp.sp6,
              bottom: sp.sp6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MicControls(
                    muted: muted,
                    onToggleMuted: onToggleMuted,
                    onEndCall: onEndCall,
                    accentWhenLive: false,
                  ),
                  if (!wide) ...[
                    SizedBox(height: sp.sp3),
                    CollapsedMomentumFooter(goodCount: goodCount),
                  ],
                ],
              ),
            ),
          ],
        );

        return Row(
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
        );
      },
    );
  }
}
