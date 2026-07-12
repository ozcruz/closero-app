import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'delta_pill.dart';
import 'score_ring.dart';

/// Post-call category card (08-score-screen.png): small-caps label,
/// delta pill vs last session, big score, and a thin progress bar
/// colored by the ring/bar threshold rule (never accent). The "Last
/// session" caption and pill only render when a previous score exists.
class CategoryScoreCard extends StatelessWidget {
  const CategoryScoreCard({
    super.key,
    required this.label,
    required this.score,
    this.previousScore,
  });

  /// Locked category display name, e.g. 'Objection handling'.
  final String label;

  /// 0 to 100.
  final int score;

  /// The same category's score last session; null on a first session.
  final int? previousScore;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final previous = previousScore;

    return Semantics(
      label: '$label $score of 100'
          '${previous == null ? '' : ', last session $previous'}',
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.all(sp.sp4),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: context.closRadius.cardRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      // Optically centers the label against the pill.
                      padding: EdgeInsets.only(top: sp.sp1),
                      child: Text(
                        label.toUpperCase(),
                        style: ClosType.style(
                          fontSize: 11,
                          weight: FontWeight.w600,
                          color: colors.dim2,
                          letterSpacingEm: 0.08,
                        ),
                      ),
                    ),
                  ),
                  if (previous != null) ...[
                    SizedBox(width: sp.sp2),
                    DeltaPill(delta: score - previous, sessionNumber: 1),
                  ],
                ],
              ),
              SizedBox(height: sp.sp3),
              Text(
                '$score',
                style: ClosType.style(
                  fontSize: 32,
                  weight: FontWeight.w700,
                  color: colors.hi1,
                  letterSpacingEm: -0.02,
                ),
              ),
              SizedBox(height: sp.sp3),
              ClipRRect(
                // Progress end-caps are the functional full-rounding
                // exception.
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: Row(
                    children: [
                      Expanded(
                        flex: score.clamp(0, 100),
                        child: ColoredBox(
                          color: scoreThresholdColor(colors, score),
                        ),
                      ),
                      Expanded(
                        flex: 100 - score.clamp(0, 100),
                        child: ColoredBox(color: colors.border2),
                      ),
                    ],
                  ),
                ),
              ),
              if (previous != null) ...[
                SizedBox(height: sp.sp3),
                Text.rich(
                  TextSpan(
                    text: 'Last session ',
                    style: ClosType.style(
                      fontSize: 12,
                      weight: FontWeight.w400,
                      color: colors.mid,
                    ),
                    children: [
                      TextSpan(
                        text: '$previous',
                        style: ClosType.style(
                          fontSize: 12,
                          weight: FontWeight.w600,
                          color: colors.hi2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
