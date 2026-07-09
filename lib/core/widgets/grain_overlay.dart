import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/widgets.dart';

/// Static 2.5% noise. Applied once by the app shell ([ClosScaffold]); never
/// add it per screen.
///
/// The speck pattern is a fixed-seed 96px tile repeated across the surface,
/// so rendering is deterministic (golden-safe) and fully synchronous.
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({required this.color, super.key, this.opacity = 0.025});

  /// Speck color; the shell passes the near-white `hi1` token.
  final Color color;

  /// Layer opacity, 2.5% per the design tokens.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Opacity(
          opacity: opacity,
          child: CustomPaint(
            painter: _GrainPainter(color),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter(this.color);

  final Color color;

  static const double _tileSize = 96;

  /// One speck per ~2 pixels of tile area, fixed seed for determinism.
  static final Float32List _tilePoints = _generateTile();

  static Float32List _generateTile() {
    final rng = Random(20260704);
    const count = (_tileSize * _tileSize) ~/ 2;
    final points = Float32List(count * 2);
    for (var i = 0; i < count; i++) {
      points[i * 2] = rng.nextDouble() * _tileSize;
      points[i * 2 + 1] = rng.nextDouble() * _tileSize;
    }
    return points;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
    canvas.clipRect(Offset.zero & size);
    for (var x = 0.0; x < size.width; x += _tileSize) {
      for (var y = 0.0; y < size.height; y += _tileSize) {
        canvas
          ..save()
          ..translate(x, y)
          ..drawRawPoints(PointMode.points, _tilePoints, paint)
          ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) => color != oldDelegate.color;
}
