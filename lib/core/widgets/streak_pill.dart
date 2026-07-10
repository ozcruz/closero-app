import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Streak counter pill: flame glyph plus 'N day streak'. Neutral
/// surface and border; the flame is the ONLY place the flame token
/// appears.
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    return Semantics(
      label: '$days day streak',
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: sp.sp3, vertical: sp.sp2),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: context.closRadius.buttonRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(12, 14),
                painter: _FlamePainter(color: colors.flame),
              ),
              SizedBox(width: sp.sp2),
              Text.rich(
                TextSpan(
                  text: '$days',
                  style: ClosType.style(
                    fontSize: 13,
                    weight: FontWeight.w700,
                    color: colors.hi1,
                  ),
                  children: [
                    TextSpan(
                      text: ' day streak',
                      style: ClosType.style(
                        fontSize: 13,
                        weight: FontWeight.w500,
                        color: colors.mid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Streak flame: teardrop outline with the signature -60 degree gap
/// at the tip, 1.3 stroke, round caps. Flame color excepted from the
/// grayscale icon rule.
class _FlamePainter extends CustomPainter {
  const _FlamePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width / 12;
    final h = size.height / 14;

    // Outer body, drawn open at the upper-left so the gap edge runs
    // at the -60 degree signature angle toward the tip.
    final body = Path()
      ..moveTo(7.4 * w, 1.6 * h)
      ..cubicTo(10.4 * w, 4.4 * h, 11 * w, 6.6 * h, 11 * w, 8.6 * h)
      ..cubicTo(11 * w, 11.4 * h, 8.8 * w, 13 * h, 6 * w, 13 * h)
      ..cubicTo(3.2 * w, 13 * h, 1 * w, 11.4 * h, 1 * w, 8.6 * h)
      ..cubicTo(1 * w, 6.4 * h, 2.2 * w, 4.6 * h, 4.2 * w, 3.2 * h);
    canvas.drawPath(body, paint);

    // Inner lick.
    final inner = Path()
      ..moveTo(6 * w, 7 * h)
      ..cubicTo(7.4 * w, 8.2 * h, 7.6 * w, 9.4 * h, 6.6 * w, 10.6 * h);
    canvas.drawPath(inner, paint);
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) => oldDelegate.color != color;
}
