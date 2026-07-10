import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The ring/bar threshold rule: hi2 at 75 and above, mid from 60 to
/// 74, dim1 below 60. Scores are NEVER accent, anywhere.
Color scoreThresholdColor(ClosColors colors, int score) {
  if (score >= 75) return colors.hi2;
  if (score >= 60) return colors.mid;
  return colors.dim1;
}

/// The score-TEXT rule for cards and lists (per the scoreText
/// component token): green at 75 and above, hi2 from 60 to 74, mid
/// below 60. Rings and bars keep [scoreThresholdColor].
Color scoreTextColor(ClosColors colors, int score) {
  if (score >= 75) return colors.green;
  if (score >= 60) return colors.hi2;
  return colors.mid;
}

/// Post-call and progress score ring: animated sweep from zero on
/// mount, colored by [scoreThresholdColor]. Round end-caps are the
/// functional full-rounding exception.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 120,
    this.strokeWidth = 6,
    this.label,
  });

  /// 0 to 100.
  final int score;
  final double size;
  final double strokeWidth;

  /// Optional small caption under the number, e.g. 'Overall'.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final color = scoreThresholdColor(colors, score);
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 900);

    return Semantics(
      label: '${label ?? 'Score'} $score of 100',
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => CustomPaint(
              painter: _RingPainter(
                progress: value,
                color: color,
                track: colors.border2,
                strokeWidth: strokeWidth,
              ),
              child: child,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: ClosType.style(
                      fontSize: size * 0.28,
                      weight: FontWeight.w700,
                      color: colors.hi1,
                      letterSpacingEm: -0.02,
                    ),
                  ),
                  if (label != null)
                    Text(
                      label!.toUpperCase(),
                      style: ClosType.style(
                        fontSize: math.max(size * 0.075, 9),
                        weight: FontWeight.w500,
                        color: colors.dim1,
                        letterSpacingEm: 0.08,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;
    final sweepPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.track != track ||
      oldDelegate.strokeWidth != strokeWidth;
}
