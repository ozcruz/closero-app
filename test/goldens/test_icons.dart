import 'package:flutter/material.dart';

/// Simple three-bar chart glyph for golden scenarios that need an
/// icon placeholder. Takes its color from the ambient [IconTheme],
/// matching how components tint the icons they host.
class BarsIcon extends StatelessWidget {
  const BarsIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 16;
    // Host components (StatTile, EmptyState) always set the icon
    // color via IconTheme.merge.
    return CustomPaint(
      size: Size.square(size),
      painter: _BarsPainter(color: theme.color!),
    );
  }
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final w = size.width / 15;
    final h = size.height / 15;
    canvas.drawLine(Offset(3.5 * w, 12 * h), Offset(3.5 * w, 8 * h), paint);
    canvas.drawLine(Offset(7.5 * w, 12 * h), Offset(7.5 * w, 4 * h), paint);
    canvas.drawLine(Offset(11.5 * w, 12 * h), Offset(11.5 * w, 6 * h), paint);
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) => oldDelegate.color != color;
}
