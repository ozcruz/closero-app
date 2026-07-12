import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Decorative trend line for progress cards: a thin polyline over the
/// series, optionally with a soft fade fill underneath (the earning
/// chart). Grayscale by default; the line color comes from the ramp,
/// never accent, and the widget carries no axes or values. Numbers
/// belong in the surrounding text, not the chart.
class SparkLine extends StatelessWidget {
  const SparkLine({
    super.key,
    required this.values,
    this.color,
    this.fill = false,
    this.strokeWidth = 1.5,
    this.semanticLabel,
  });

  /// The series in chronological order. Fewer than two points renders
  /// an empty box rather than a broken chart.
  final List<double> values;

  /// Line color; defaults to dim1 on the grayscale ramp.
  final Color? color;

  /// Adds a soft color-to-transparent fade under the line.
  final bool fill;

  final double strokeWidth;

  /// Read to screen readers instead of the (decorative) line.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final line = color ?? context.closColors.dim1;

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: values.length < 2
            ? const SizedBox.expand()
            : CustomPaint(
                size: Size.infinite,
                painter: _SparkLinePainter(
                  values: values,
                  color: line,
                  fill: fill,
                  strokeWidth: strokeWidth,
                ),
              ),
      ),
    );
  }
}

class _SparkLinePainter extends CustomPainter {
  const _SparkLinePainter({
    required this.values,
    required this.color,
    required this.fill,
    required this.strokeWidth,
  });

  final List<double> values;
  final Color color;
  final bool fill;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    var min = values.first;
    var max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    // Flat series still draws a visible midline.
    final span = (max - min) == 0 ? 1.0 : max - min;

    // Inset vertically so the round caps never clip.
    final inset = strokeWidth;
    final drawHeight = size.height - inset * 2;

    Offset point(int i) {
      final x = size.width * i / (values.length - 1);
      final y = inset + drawHeight * (1 - (values[i] - min) / span);
      return Offset(x, y);
    }

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.14),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkLinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.fill != fill ||
      oldDelegate.strokeWidth != strokeWidth;
}
