import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The Closero icon system (context/prototype-screens/24-icon-set.png):
/// 15x15 grid, 1.2-1.5 strokes, round caps and joins, secondary elements
/// filled at 0.55-0.85 opacity. Any primary circle carries a single ~55
/// degree gap centered on the wordmark's -60 degree cut axis (upper
/// right). Icons live on the grayscale ramp and take their color from
/// the ambient [IconTheme]; hosts (SideNav etc.) tint them.

/// Visible arc for an icon-system ring: everything except the ~55 degree
/// gap centered on the -60 degree axis.
const double _ringGapAxis = -60 * math.pi / 180;
const double _ringGapHalf = 27.5 * math.pi / 180;

void _drawGapRing(Canvas canvas, Offset center, double r, Paint paint) {
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: r),
    _ringGapAxis + _ringGapHalf,
    2 * math.pi - 2 * _ringGapHalf,
    false,
    paint,
  );
}

typedef _PaintIcon = void Function(Canvas canvas, double u, Color color);

/// Shared host: reads size and color from [IconTheme] like the icons it
/// sits beside, and paints on the 15-unit grid (u = one grid unit).
class _ClosIcon extends StatelessWidget {
  const _ClosIcon(this.paint);

  final _PaintIcon paint;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 15;
    return CustomPaint(
      size: Size.square(size),
      painter: _ClosIconPainter(paint, theme.color!),
    );
  }
}

class _ClosIconPainter extends CustomPainter {
  const _ClosIconPainter(this.paintIcon, this.color);

  final _PaintIcon paintIcon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      paintIcon(canvas, size.width / 15, color);

  @override
  bool shouldRepaint(_ClosIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.paintIcon != paintIcon;
}

Paint _stroke(double u, Color color, [double width = 1.3]) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width * u
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint _fill(double u, Color color, [double opacity = 0.85]) => Paint()
  ..color = color.withValues(alpha: opacity)
  ..style = PaintingStyle.fill;

/// Dashboard: 2x2 grid of filled rounded squares (secondary fills).
class DashboardIcon extends StatelessWidget {
  const DashboardIcon({super.key});

  static void _paint(Canvas canvas, double u, Color color) {
    final paint = _fill(u, color);
    for (final origin in const [
      Offset(2.5, 2.5),
      Offset(8, 2.5),
      Offset(2.5, 8),
      Offset(8, 8),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(origin.dx * u, origin.dy * u, 4.5 * u, 4.5 * u),
          Radius.circular(1.1 * u),
        ),
        paint,
      );
    }
  }

  @override
  Widget build(BuildContext context) => const _ClosIcon(_paint);
}

/// Simulations: gap ring around a filled play triangle.
class SimulationsIcon extends StatelessWidget {
  const SimulationsIcon({super.key});

  static void _paint(Canvas canvas, double u, Color color) {
    _drawGapRing(canvas, Offset(7.5 * u, 7.5 * u), 4.9 * u, _stroke(u, color));
    final triangle = Path()
      ..moveTo(6.4 * u, 5.5 * u)
      ..lineTo(9.9 * u, 7.5 * u)
      ..lineTo(6.4 * u, 9.5 * u)
      ..close();
    canvas.drawPath(triangle, _fill(u, color));
  }

  @override
  Widget build(BuildContext context) => const _ClosIcon(_paint);
}

/// My progress: three ascending bars.
class ProgressIcon extends StatelessWidget {
  const ProgressIcon({super.key});

  static void _paint(Canvas canvas, double u, Color color) {
    final paint = _stroke(u, color, 1.4);
    canvas.drawLine(Offset(4 * u, 12 * u), Offset(4 * u, 8.6 * u), paint);
    canvas.drawLine(Offset(7.5 * u, 12 * u), Offset(7.5 * u, 6.2 * u), paint);
    canvas.drawLine(Offset(11 * u, 12 * u), Offset(11 * u, 3.6 * u), paint);
  }

  @override
  Widget build(BuildContext context) => const _ClosIcon(_paint);
}

/// Methodologies: two long list lines and one short.
class MethodologiesIcon extends StatelessWidget {
  const MethodologiesIcon({super.key});

  static void _paint(Canvas canvas, double u, Color color) {
    final paint = _stroke(u, color, 1.4);
    canvas.drawLine(Offset(3 * u, 4 * u), Offset(12 * u, 4 * u), paint);
    canvas.drawLine(Offset(3 * u, 7.5 * u), Offset(12 * u, 7.5 * u), paint);
    canvas.drawLine(Offset(3 * u, 11 * u), Offset(8 * u, 11 * u), paint);
  }

  @override
  Widget build(BuildContext context) => const _ClosIcon(_paint);
}

/// Achievements: award ribbon; gap ring head, secondary center dot,
/// splayed tails.
class AchievementsIcon extends StatelessWidget {
  const AchievementsIcon({super.key});

  static void _paint(Canvas canvas, double u, Color color) {
    final head = Offset(7.5 * u, 5.7 * u);
    _drawGapRing(canvas, head, 3.4 * u, _stroke(u, color));
    canvas.drawCircle(head, 1.1 * u, _fill(u, color, 0.7));
    final paint = _stroke(u, color, 1.35);
    canvas.drawLine(Offset(6.1 * u, 8.7 * u), Offset(5 * u, 12.6 * u), paint);
    canvas.drawLine(Offset(8.9 * u, 8.7 * u), Offset(10 * u, 12.6 * u), paint);
  }

  @override
  Widget build(BuildContext context) => const _ClosIcon(_paint);
}

/// Settings: gap ring with a dial needle pointing at the gap.
class SettingsIcon extends StatelessWidget {
  const SettingsIcon({super.key});

  static void _paint(Canvas canvas, double u, Color color) {
    _drawGapRing(canvas, Offset(7.5 * u, 7.5 * u), 4.9 * u, _stroke(u, color));
    canvas.drawLine(
      Offset(6.9 * u, 8.7 * u),
      Offset(8.6 * u, 5 * u),
      _stroke(u, color, 1.4),
    );
  }

  @override
  Widget build(BuildContext context) => const _ClosIcon(_paint);
}

/// Envelope, for the reset/verify "check your inbox" states.
class MailIcon extends StatelessWidget {
  const MailIcon({super.key});

  static void _paint(Canvas canvas, double u, Color color) {
    final paint = _stroke(u, color, 1.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(1.8 * u, 3.2 * u, 13.2 * u, 11.8 * u),
        Radius.circular(1.6 * u),
      ),
      paint,
    );
    final flap = Path()
      ..moveTo(2.6 * u, 4.6 * u)
      ..lineTo(7.5 * u, 8.2 * u)
      ..lineTo(12.4 * u, 4.6 * u);
    canvas.drawPath(flap, paint);
  }

  @override
  Widget build(BuildContext context) => const _ClosIcon(_paint);
}

/// Checkmark, for plan feature lists and the upgrade-success badge.
/// The rise stroke runs along the -60 degree signature axis.
class CheckIcon extends StatelessWidget {
  const CheckIcon({super.key});

  static void _paint(Canvas canvas, double u, Color color) {
    final check = Path()
      ..moveTo(3.4 * u, 8.4 * u)
      ..lineTo(6.1 * u, 10.9 * u)
      ..lineTo(10.9 * u, 4.1 * u);
    canvas.drawPath(check, _stroke(u, color, 1.4));
  }

  @override
  Widget build(BuildContext context) => const _ClosIcon(_paint);
}

/// Dismiss / not-included: two crossing strokes, one laid along the -60
/// degree signature axis (so the X sits slightly rotated by design).
class CloseIcon extends StatelessWidget {
  const CloseIcon({super.key});

  static void _paint(Canvas canvas, double u, Color color) {
    final paint = _stroke(u, color, 1.4);
    // Along the -60 degree axis and its perpendicular.
    canvas.drawLine(
      Offset(5.6 * u, 10.8 * u),
      Offset(9.4 * u, 4.2 * u),
      paint,
    );
    canvas.drawLine(
      Offset(4.2 * u, 5.6 * u),
      Offset(10.8 * u, 9.4 * u),
      paint,
    );
  }

  @override
  Widget build(BuildContext context) => const _ClosIcon(_paint);
}

/// Padlock, for gated states (session limit). Same drawing as the
/// scenario-card lock: the shackle ends short on the right shoulder so
/// the opening sits on the -60 degree signature axis.
class LockIcon extends StatelessWidget {
  const LockIcon({super.key});

  static void _paint(Canvas canvas, double u, Color color) {
    final paint = _stroke(u, color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(3.2 * u, 6.8 * u, 11.8 * u, 12.4 * u),
        Radius.circular(1.3 * u),
      ),
      paint,
    );
    final shackle = Path()
      ..moveTo(5.3 * u, 6.8 * u)
      ..lineTo(5.3 * u, 5.2 * u)
      ..cubicTo(5.3 * u, 3.4 * u, 9.7 * u, 3.4 * u, 9.7 * u, 5.2 * u);
    canvas.drawPath(shackle, paint);
  }

  @override
  Widget build(BuildContext context) => const _ClosIcon(_paint);
}

/// The brand mark: the app icon's ring alone, for no-sidebar screens.
/// Geometry is ported 1:1 from the locked closero-icon.svg (ellipse
/// rx 269.76 / ry 303.40 / stroke 133.20 on a 1000 grid, sliced by a
/// 53.28-wide strip along the -60 degree cut axis); recolored only,
/// never redrawn. Defaults per the wordmark rules: accentDim, 18px.
class CloseroMark extends StatelessWidget {
  const CloseroMark({super.key, this.size = 18, this.color});

  final double size;

  /// Defaults to accentDim.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Closero',
      child: CustomPaint(
        size: Size.square(size),
        painter: _CloseroMarkPainter(color ?? context.closColors.accentDim),
      ),
    );
  }
}

class _CloseroMarkPainter extends CustomPainter {
  const _CloseroMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 1000;
    final center = Offset(500 * u, 500 * u);
    final rect = Rect.fromCenter(
      center: center,
      width: 2 * 269.76 * u,
      height: 2 * 303.40 * u,
    );
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawOval(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 133.20 * u,
    );
    // The -60 degree cut: one strip through the center clears the ring
    // on both sides, exactly like the SVG mask.
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-60 * math.pi / 180);
    canvas.drawRect(
      Rect.fromLTRB(-500 * u, -26.64 * u, 500 * u, 26.64 * u),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CloseroMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
