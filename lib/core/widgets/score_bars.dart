import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'score_ring.dart';

/// Score-by-session bar chart: one bar per session in chronological
/// order, height by score, colored by the ring/bar threshold rule
/// (hi2 at 75+, mid 60 to 74, dim1 below 60). Never accent. Bars keep
/// a slight top rounding; never full-rounded (that stays reserved for
/// circles and progress end-caps).
class ScoreBars extends StatelessWidget {
  const ScoreBars({super.key, required this.scores, this.semanticLabel});

  /// Session scores 0 to 100, oldest first.
  final List<int> scores;

  /// Read to screen readers instead of the bars.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;

    return Semantics(
      label: semanticLabel ??
          '${scores.length} session scores, '
              'latest ${scores.isEmpty ? 0 : scores.last} percent',
      child: ExcludeSemantics(
        child: scores.isEmpty
            ? const SizedBox.expand()
            : CustomPaint(
                size: Size.infinite,
                painter: _ScoreBarsPainter(
                  scores: scores,
                  colorFor: (score) => scoreThresholdColor(colors, score),
                ),
              ),
      ),
    );
  }
}

class _ScoreBarsPainter extends CustomPainter {
  const _ScoreBarsPainter({required this.scores, required this.colorFor});

  final List<int> scores;
  final Color Function(int score) colorFor;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / scores.length;
    // Bars fill most of their slot; the gap collapses as bars thin out.
    final gap = (slot * 0.3).clamp(1.0, 10.0);
    final barWidth = (slot - gap).clamp(1.0, 44.0);
    final radius = Radius.circular(barWidth < 6 ? 1 : 3);

    for (var i = 0; i < scores.length; i++) {
      final height = size.height * scores[i].clamp(0, 100) / 100;
      final left = slot * i + (slot - barWidth) / 2;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, size.height - height, barWidth, height),
          topLeft: radius,
          topRight: radius,
        ),
        Paint()..color = colorFor(scores[i]),
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreBarsPainter oldDelegate) =>
      oldDelegate.scores != scores || oldDelegate.colorFor != colorFor;
}
