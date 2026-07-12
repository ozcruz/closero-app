import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../scoring/domain/session_doc.dart';
import '../../scoring/presentation/score_screen.dart' show momentHintKind;
import '../../scoring/presentation/scoring_shell.dart' show formatClock;
import '../domain/sim_session.dart';

/// Coaching panel width on wide layouts; below [kSimPanelBreakpoint]
/// the panel collapses to the momentum footer on the stage.
const double kSimPanelWidth = 300;
const double kSimPanelBreakpoint = 1100;

/// Momentum caption under the dots. Mechanically true: a dot fills per
/// logged 'good' hint, and the only score is at the reveal.
String momentumCaption(int goodCount) => switch (goodCount) {
      0 => 'Strong moves fill a dot. Full score at the reveal.',
      1 => '1 strong move this call. Full score at the reveal.',
      _ => '$goodCount strong moves this call. Full score at the reveal.',
    };

/// Live-sim topbar: brand ring, sim kind and scenario, LIVE badge,
/// tabular call clock, End call. [frosted] blurs whatever sits behind
/// it (the Video Sim's full-screen stage).
class SimTopbar extends StatelessWidget {
  const SimTopbar({
    super.key,
    required this.kindLabel,
    required this.scenarioLabel,
    required this.elapsedSec,
    required this.onEndCall,
    this.frosted = false,
  });

  /// e.g. 'Cold call' or 'Video sim'.
  final String kindLabel;

  /// e.g. 'SaaS gatekeeper'.
  final String scenarioLabel;

  final int elapsedSec;

  /// Null while the session is still connecting or already ending.
  final VoidCallback? onEndCall;

  final bool frosted;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    Widget bar = Container(
      padding: EdgeInsets.symmetric(horizontal: sp.sp6, vertical: sp.sp3),
      decoration: BoxDecoration(
        color: frosted
            ? colors.base.withValues(alpha: 0.62)
            : colors.base,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          const CloseroMark(),
          SizedBox(width: sp.sp4),
          Container(width: 1, height: 16, color: colors.border2),
          SizedBox(width: sp.sp4),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$kindLabel · ',
                    style: ClosType.style(
                      fontSize: 13,
                      weight: FontWeight.w400,
                      color: colors.dim1,
                    ),
                  ),
                  TextSpan(
                    text: scenarioLabel,
                    style: ClosType.style(
                      fontSize: 13,
                      weight: FontWeight.w600,
                      color: colors.hi1,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: sp.sp4),
          ClosBadge(label: 'LIVE', dotColor: colors.green),
          SizedBox(width: sp.sp4),
          Text(
            formatClock(elapsedSec),
            style: ClosType.style(
              fontSize: 14,
              weight: FontWeight.w600,
              color: colors.hi1,
            ).copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(width: sp.sp4),
          DestructiveButton(
            label: 'End call',
            size: ClosButtonSize.medium,
            onPressed: onEndCall,
          ),
        ],
      ),
    );

    if (frosted) {
      bar = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: bar,
        ),
      );
    }
    return bar;
  }
}

/// The 2px call-progress stripe under the topbar: elapsed over the
/// scenario estimate, chrome-colored (progress rings and bars color by
/// threshold; this is not a score, so it stays grayscale).
class SimProgressStripe extends StatelessWidget {
  const SimProgressStripe({super.key, required this.progress});

  /// 0 to 1, clamped.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    return SizedBox(
      height: 2,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: ColoredBox(color: colors.hi2),
        ),
      ),
    );
  }
}

/// 'Sandra is speaking' waveform indicator. Bars animate only while
/// the persona speaks and animations are enabled.
class SpeakingIndicator extends StatefulWidget {
  const SpeakingIndicator({
    super.key,
    required this.personaShortName,
    required this.speaking,
  });

  final String personaShortName;
  final bool speaking;

  @override
  State<SpeakingIndicator> createState() => _SpeakingIndicatorState();
}

class _SpeakingIndicatorState extends State<SpeakingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const _heights = [6.0, 12.0, 8.0, 14.0, 7.0];

  void _syncAnimation() {
    final animate =
        widget.speaking && !MediaQuery.of(context).disableAnimations;
    if (animate && !_wave.isAnimating) {
      _wave.repeat();
    } else if (!animate && _wave.isAnimating) {
      _wave.stop();
      _wave.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(SpeakingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final speaking = widget.speaking;

    return Semantics(
      liveRegion: true,
      label: speaking
          ? '${widget.personaShortName} is speaking'
          : 'Listening',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _wave,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _heights.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Container(
                      width: 2.5,
                      height: speaking
                          ? _heights[i] *
                              (0.55 +
                                  0.45 *
                                      (0.5 +
                                          0.5 *
                                              _waveSample(
                                                  _wave.value, i)))
                          : 5,
                      decoration: BoxDecoration(
                        color: speaking ? colors.mid : colors.dim3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: sp.sp3),
            Text(
              speaking
                  ? '${widget.personaShortName} is speaking'
                  : 'Listening',
              style: ClosType.style(
                fontSize: 13,
                weight: FontWeight.w400,
                color: speaking ? colors.mid : colors.dim1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Staggered -1..1 pulse per bar.
  double _waveSample(double t, int index) {
    final phase = (t + index * 0.18) % 1.0;
    return (phase < 0.5 ? phase : 1.0 - phase) * 4 - 1;
  }
}

/// The three call controls. The mic-on state is the ONLY accent-filled
/// element of the Cold Call screen; the Video Sim carries no accent at
/// all, so it passes [accentWhenLive] false and gets an hi1 fill.
class MicControls extends StatelessWidget {
  const MicControls({
    super.key,
    required this.muted,
    required this.onToggleMuted,
    required this.onEndCall,
    this.accentWhenLive = true,
  });

  final bool muted;
  final VoidCallback onToggleMuted;

  /// Opens the exit confirm, same as the topbar End call.
  final VoidCallback? onEndCall;

  final bool accentWhenLive;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final liveFill = accentWhenLive ? colors.accent : colors.hi1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundControl(
          semanticLabel: muted ? 'Unmute microphone' : 'Mute microphone',
          size: 44,
          fill: colors.surface,
          border: colors.border2,
          onTap: onToggleMuted,
          child: IconTheme.merge(
            data: IconThemeData(
              color: muted ? colors.hi2 : colors.dim1,
              size: 16,
            ),
            child: const MicOffIcon(),
          ),
        ),
        SizedBox(width: sp.sp4),
        _RoundControl(
          semanticLabel:
              muted ? 'Microphone muted, tap to unmute' : 'Microphone on',
          size: 56,
          fill: muted ? colors.surface2 : liveFill,
          border: muted ? colors.border2 : null,
          onTap: onToggleMuted,
          child: IconTheme.merge(
            data: IconThemeData(
              color: muted ? colors.dim1 : colors.base,
              size: 20,
            ),
            child: muted ? const MicOffIcon() : const MicIcon(),
          ),
        ),
        SizedBox(width: sp.sp4),
        _RoundControl(
          semanticLabel: 'End call',
          size: 44,
          fill: colors.surface,
          border: colors.border2,
          onTap: onEndCall,
          child: IconTheme.merge(
            data: IconThemeData(color: colors.dim1, size: 16),
            child: const PowerIcon(),
          ),
        ),
      ],
    );
  }
}

class _RoundControl extends StatefulWidget {
  const _RoundControl({
    required this.semanticLabel,
    required this.size,
    required this.fill,
    required this.child,
    required this.onTap,
    this.border,
  });

  final String semanticLabel;
  final double size;
  final Color fill;
  final Color? border;
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_RoundControl> createState() => _RoundControlState();
}

class _RoundControlState extends State<_RoundControl> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final interactive = widget.onTap != null;

    return Semantics(
      button: true,
      enabled: interactive,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: ExcludeSemantics(
            child: Container(
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.fill,
                shape: BoxShape.circle,
                border: widget.border == null
                    ? null
                    : Border.all(
                        color: _hovered && interactive
                            ? colors.dim1
                            : widget.border!,
                      ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Right-hand coaching panel: Coaching/Transcript tabs (Coaching is
/// the default), the Next move card, the This call hint feed, and the
/// momentum footer. 300px on wide layouts.
class CoachingPanel extends StatefulWidget {
  const CoachingPanel({
    super.key,
    required this.personaShortName,
    required this.nextMove,
    required this.hints,
    required this.transcript,
    required this.goodCount,
  });

  final String personaShortName;
  final SimNextMove? nextMove;
  final List<SimHint> hints;
  final List<Utterance> transcript;
  final int goodCount;

  @override
  State<CoachingPanel> createState() => _CoachingPanelState();
}

class _CoachingPanelState extends State<CoachingPanel> {
  /// Coaching tab is the default, both sims.
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Container(
      width: kSimPanelWidth,
      decoration: BoxDecoration(
        color: colors.base,
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClosTabs(
            tabs: [
              const ClosTab(label: 'Coaching'),
              ClosTab(label: 'Transcript', count: widget.transcript.length),
            ],
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: _tab == 0 ? _coachingTab(context) : _transcriptTab(),
          ),
          Container(
            padding: EdgeInsets.all(sp.sp4),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SectionHeader(
                  title: 'Momentum',
                  variant: SectionHeaderVariant.label,
                ),
                SizedBox(height: sp.sp3),
                MomentumDots(
                  filled: widget.goodCount,
                  caption: momentumCaption(widget.goodCount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coachingTab(BuildContext context) {
    final sp = context.sp;

    return ListView(
      padding: EdgeInsets.all(sp.sp4),
      children: [
        if (widget.nextMove != null) ...[
          _NextMoveCard(move: widget.nextMove!),
          SizedBox(height: sp.sp6),
        ],
        const SectionHeader(
          title: 'This call',
          variant: SectionHeaderVariant.label,
        ),
        SizedBox(height: sp.sp3),
        if (widget.hints.isEmpty)
          Text(
            'Coaching notes appear here as the call unfolds.',
            style: ClosType.style(
              fontSize: 13,
              weight: FontWeight.w400,
              color: context.closColors.dim1,
            ),
          ),
        for (final hint in widget.hints) ...[
          HintCard(
            kind: momentHintKind(hint.kind),
            label: hint.label,
            title: hint.note,
          ),
          SizedBox(height: sp.sp3),
        ],
      ],
    );
  }

  Widget _transcriptTab() {
    final sp = context.sp;

    return ListView(
      padding: EdgeInsets.all(sp.sp4),
      children: [
        if (widget.transcript.isEmpty)
          Text(
            'The transcript fills in as you talk.',
            style: ClosType.style(
              fontSize: 13,
              weight: FontWeight.w400,
              color: context.closColors.dim1,
            ),
          ),
        for (final line in widget.transcript) ...[
          TranscriptLine(
            speaker: line.speaker == Speaker.rep
                ? 'You'
                : widget.personaShortName,
            text: line.text,
            timestamp: formatClock(line.tsMs ~/ 1000),
          ),
          SizedBox(height: sp.sp4),
        ],
      ],
    );
  }
}

/// The Next move suggestion: neutral surface with a 3px hi2 left edge
/// (guidance, not a judged state, so it stays off the semantic ramp).
class _NextMoveCard extends StatelessWidget {
  const _NextMoveCard({required this.move});

  final SimNextMove move;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClipRRect(
      borderRadius: context.closRadius.cardRadius,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: context.closRadius.cardRadius,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: colors.hi2,
                child: const SizedBox(width: 3),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(sp.sp4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NEXT MOVE',
                        style: ClosType.style(
                          fontSize: 11,
                          weight: FontWeight.w600,
                          color: colors.dim2,
                          letterSpacingEm: 0.08,
                        ),
                      ),
                      SizedBox(height: sp.sp2),
                      Text(
                        move.title,
                        style: ClosType.style(
                          fontSize: 15,
                          weight: FontWeight.w600,
                          color: colors.hi1,
                        ),
                      ),
                      SizedBox(height: sp.sp2),
                      Text(
                        move.body,
                        style: ClosType.style(
                          fontSize: 13,
                          weight: FontWeight.w400,
                          color: colors.body,
                        ).copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact momentum strip shown on the stage when the coaching panel
/// is collapsed (viewport under [kSimPanelBreakpoint]).
class CollapsedMomentumFooter extends StatelessWidget {
  const CollapsedMomentumFooter({super.key, required this.goodCount});

  final int goodCount;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sp.sp6, vertical: sp.sp4),
      child: MomentumDots(
        filled: goodCount,
        caption: momentumCaption(goodCount),
      ),
    );
  }
}

/// Exit confirm (prototype-screens/23-exit-confirm.png). Resolves true
/// when the rep really wants out. Copy is mechanically true: an early
/// hang-up still counts against the cap and still gets scored.
Future<bool> showEndSessionModal(
  BuildContext context, {
  required String personaShortName,
  required int elapsedSec,
  required int estimatedMinutes,
}) async {
  final confirmed = await showClosModal<bool>(
    context,
    builder: (context) => EndSessionDialog(
      personaShortName: personaShortName,
      elapsedSec: elapsedSec,
      estimatedMinutes: estimatedMinutes,
    ),
  );
  return confirmed ?? false;
}

/// The exit-confirm dialog body.
///
/// Accent audit: Keep talking is the modal's one accent-filled element
/// (the primary CTA); End session now is the solid destructive role.
class EndSessionDialog extends StatelessWidget {
  const EndSessionDialog({
    super.key,
    required this.personaShortName,
    required this.elapsedSec,
    required this.estimatedMinutes,
  });

  final String personaShortName;
  final int elapsedSec;
  final int estimatedMinutes;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClosModal(
      maxWidth: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.destructive,
              shape: BoxShape.circle,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: colors.onDestructive, size: 22),
              child: const AlertIcon(),
            ),
          ),
          SizedBox(height: sp.sp5),
          Text(
            'End this session early?',
            style: context.closType.headlineMedium,
          ),
          SizedBox(height: sp.sp3),
          Text(
            "You're ${formatClock(elapsedSec)} into a call estimated at "
            '~$estimatedMinutes minutes. If you end now, '
            '$personaShortName will hang up and the call '
            "won't continue.",
            style: ClosType.style(
              fontSize: 14,
              weight: FontWeight.w400,
              color: colors.body,
            ).copyWith(height: 1.5),
          ),
          SizedBox(height: sp.sp4),
          ClosCard(
            variant: ClosCardVariant.inset,
            padding: EdgeInsets.all(sp.sp4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'This still counts as a session. ',
                    style: ClosType.style(
                      fontSize: 13,
                      weight: FontWeight.w600,
                      color: colors.hi2,
                    ),
                  ),
                  TextSpan(
                    text: "It'll be scored against the shorter "
                        'transcript and saved to My progress.',
                    style: ClosType.style(
                      fontSize: 13,
                      weight: FontWeight.w400,
                      color: colors.body,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(height: 1.5),
            ),
          ),
          SizedBox(height: sp.sp6),
          PrimaryButton(
            label: 'Keep talking',
            expand: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          SizedBox(height: sp.sp3),
          DestructiveButton(
            label: 'End session now',
            expand: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}

/// Concentric halo rings around the audio-only persona avatar.
class RingedAvatar extends StatelessWidget {
  const RingedAvatar({
    super.key,
    required this.initials,
    required this.tint,
    required this.personaName,
    this.diameter = 150,
  });

  final String initials;
  final AvatarArtTint tint;
  final String personaName;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;

    return SizedBox(
      width: diameter + 80,
      height: diameter + 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final inset in const [0.0, 22.0, 40.0])
            Positioned.fill(
              left: inset,
              top: inset,
              right: inset,
              bottom: inset,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
              ),
            ),
          SizedBox(
            width: diameter,
            height: diameter,
            child: ClipOval(
              child: AvatarStack(
                initials: initials,
                tint: tint,
                semanticLabel: '$personaName, AI persona',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Video Sim's blurred office backdrop, built procedurally from
/// tokens (no photo asset, no faces) and treated per the recipe:
/// blur(3px) brightness(0.28) saturate(0.6) scale(1.06). Saturation is
/// moot on the grayscale set; brightness is the base scrim.
class OfficeBackdrop extends StatelessWidget {
  const OfficeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: 1.06,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: CustomPaint(painter: _OfficePainter(colors)),
            ),
          ),
          ColoredBox(color: colors.base.withValues(alpha: 0.72)),
        ],
      ),
    );
  }
}

class _OfficePainter extends CustomPainter {
  const _OfficePainter(this.colors);

  final ClosColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colors.surface2,
    );

    // Window wall: tall glass panels catching low light.
    final glass = Paint()..color = colors.dim3.withValues(alpha: 0.5);
    final mullion = Paint()..color = colors.border2;
    for (var i = 0; i < 5; i++) {
      final left = w * (0.04 + i * 0.14);
      canvas.drawRect(
        Rect.fromLTWH(left, h * 0.06, w * 0.11, h * 0.55),
        glass,
      );
      canvas.drawRect(
        Rect.fromLTWH(left - w * 0.008, h * 0.06, w * 0.008, h * 0.55),
        mullion,
      );
    }

    // A far shelf line and two monitor slabs on a desk edge.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.68, h * 0.30, w * 0.30, h * 0.02),
      Paint()..color = colors.border,
    );
    final slab = Paint()..color = colors.dim3.withValues(alpha: 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.72, h * 0.38, w * 0.10, h * 0.10),
        const Radius.circular(3),
      ),
      slab,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.85, h * 0.36, w * 0.09, h * 0.12),
        const Radius.circular(3),
      ),
      slab,
    );

    // Desk plane across the foot of the frame.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.72, w, h * 0.28),
      Paint()..color = colors.surface,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.72, w, h * 0.012),
      Paint()..color = colors.border,
    );
  }

  @override
  bool shouldRepaint(_OfficePainter oldDelegate) =>
      oldDelegate.colors != colors;
}

/// Honest start-failure state: the gate call never granted a session,
/// so nothing was burned. Offers retry and a way back.
class SimStartFailed extends StatelessWidget {
  const SimStartFailed({
    super.key,
    required this.onRetry,
    required this.onBack,
  });

  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InlineNotice(
              kind: InlineNoticeKind.error,
              message: "We couldn't start the session. Nothing was "
                  'used from your plan. Check your connection and '
                  'try again.',
            ),
            SizedBox(height: sp.sp4),
            PrimaryButton(label: 'Try again', expand: true, onPressed: onRetry),
            SizedBox(height: sp.sp3),
            GhostButton(
              label: 'Back to simulations',
              expand: true,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

/// Connecting state while the gate resolves: persona placeholder plus
/// a quiet line, no fake conversation yet.
class SimConnecting extends StatelessWidget {
  const SimConnecting({
    super.key,
    required this.personaName,
    required this.initials,
    required this.tint,
  });

  final String personaName;
  final String initials;
  final AvatarArtTint tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RingedAvatar(
            initials: initials,
            tint: tint,
            personaName: personaName,
          ),
          SizedBox(height: sp.sp6),
          Text(
            'Connecting you to $personaName',
            style: ClosType.style(
              fontSize: 14,
              weight: FontWeight.w400,
              color: colors.mid,
            ),
          ),
        ],
      ),
    );
  }
}
