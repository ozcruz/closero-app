import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'avatar_stack.dart';
import 'clos_badge.dart';
import 'score_ring.dart';

/// Scenario card status. Completion shows the personal-best score or
/// 'Start'; never a checkmark.
enum ScenarioCardStatus {
  /// Not attempted: trailing 'Start'.
  start,

  /// Completed: trailing personal-best score, threshold colored.
  personalBest,

  /// Attempted but unfinished: dot on the art, trailing 'Resume'.
  inProgress,

  /// Gated content on the free tier: lock glyph, trailing 'Locked'.
  /// Tapping should route to the upgrade screen (caller's onTap).
  locked,
}

/// Library grid card: avatar art, difficulty badge, name, one-line
/// description, meta row. Methodology tags never appear here; they
/// live only in the Scenario Preview modal.
class ScenarioCard extends StatefulWidget {
  const ScenarioCard({
    super.key,
    required this.name,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.initials,
    this.tint = AvatarArtTint.neutral,
    this.status = ScenarioCardStatus.start,
    this.bestScore,
    this.onTap,
  });

  /// Persona name, e.g. 'Denise'.
  final String name;

  /// One line, e.g. 'Skeptical homeowner, 3rd pitch today'.
  final String description;

  /// e.g. '~12 min'.
  final String duration;

  /// Badge copy, e.g. 'Hard'.
  final String difficulty;

  /// Placeholder initials for the avatar art, e.g. 'DW'.
  final String initials;

  /// Decorative art gradient cast for this persona.
  final AvatarArtTint tint;

  final ScenarioCardStatus status;

  /// Required when [status] is [ScenarioCardStatus.personalBest].
  final int? bestScore;

  final VoidCallback? onTap;

  @override
  State<ScenarioCard> createState() => _ScenarioCardState();
}

class _ScenarioCardState extends State<ScenarioCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final locked = widget.status == ScenarioCardStatus.locked;
    final interactive = widget.onTap != null;

    Widget art = AvatarStack(initials: widget.initials, tint: widget.tint);
    if (locked) art = Opacity(opacity: 0.45, child: art);

    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: _hovered && interactive ? colors.border2 : colors.border,
        ),
        borderRadius: context.closRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                art,
                Positioned(
                  top: sp.sp3,
                  left: sp.sp3,
                  child: ClosBadge(label: widget.difficulty),
                ),
                if (widget.status == ScenarioCardStatus.inProgress)
                  Positioned(
                    top: sp.sp3,
                    right: sp.sp3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.hi2,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(width: 7, height: 7),
                    ),
                  ),
                if (locked)
                  Positioned(
                    top: sp.sp3,
                    right: sp.sp3,
                    child: CustomPaint(
                      size: const Size(13, 14),
                      painter: _LockPainter(color: colors.dim1),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(sp.sp4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.closType.titleLarge,
                ),
                SizedBox(height: sp.sp1),
                Text(
                  widget.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClosType.style(
                    fontSize: 13,
                    weight: FontWeight.w400,
                    color: colors.body,
                  ),
                ),
                SizedBox(height: sp.sp3),
                Row(
                  children: [
                    Text(
                      widget.duration,
                      style: ClosType.style(
                        fontSize: 12,
                        weight: FontWeight.w400,
                        color: colors.dim1,
                      ),
                    ),
                    const Spacer(),
                    _trailing(colors),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: interactive,
      enabled: interactive,
      label: _semanticsLabel,
      child: MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: ExcludeSemantics(child: card),
        ),
      ),
    );
  }

  String get _semanticsLabel {
    final base = '${widget.name}, ${widget.description}, '
        '${widget.difficulty}, ${widget.duration}';
    return switch (widget.status) {
      ScenarioCardStatus.start => '$base, not started',
      ScenarioCardStatus.personalBest =>
        '$base, personal best ${widget.bestScore}',
      ScenarioCardStatus.inProgress => '$base, in progress',
      ScenarioCardStatus.locked => '$base, locked, upgrade to open',
    };
  }

  Widget _trailing(ClosColors colors) {
    switch (widget.status) {
      case ScenarioCardStatus.start:
        return Text(
          'Start',
          style: ClosType.style(
            fontSize: 13,
            weight: FontWeight.w600,
            color: colors.mid,
          ),
        );
      case ScenarioCardStatus.personalBest:
        final score = widget.bestScore ?? 0;
        return Text(
          '$score',
          style: ClosType.style(
            fontSize: 14,
            weight: FontWeight.w700,
            color: scoreTextColor(colors, score),
          ),
        );
      case ScenarioCardStatus.inProgress:
        return Text(
          'Resume',
          style: ClosType.style(
            fontSize: 13,
            weight: FontWeight.w600,
            color: colors.mid,
          ),
        );
      case ScenarioCardStatus.locked:
        return Text(
          'Locked',
          style: ClosType.style(
            fontSize: 13,
            weight: FontWeight.w500,
            color: colors.dim1,
          ),
        );
    }
  }
}

/// Padlock: rounded body plus shackle drawn open with the signature
/// -60 degree gap on the right shoulder. 1.3 stroke, round caps.
class _LockPainter extends CustomPainter {
  const _LockPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width / 13;
    final h = size.height / 14;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(1.5 * w, 6 * h, 11.5 * w, 12.5 * h),
      Radius.circular(1.5 * w),
    );
    canvas.drawRRect(body, paint);

    // Shackle: left leg up and over, ending short of the right leg so
    // the gap edge sits at the -60 degree signature angle.
    final shackle = Path()
      ..moveTo(4 * w, 6 * h)
      ..lineTo(4 * w, 4.2 * h)
      ..cubicTo(4 * w, 2.2 * h, 9 * w, 2.2 * h, 9 * w, 4.2 * h);
    canvas.drawPath(shackle, paint);
  }

  @override
  bool shouldRepaint(_LockPainter oldDelegate) => oldDelegate.color != color;
}
