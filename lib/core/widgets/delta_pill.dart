import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Score delta pill: neutral chip, colored text only (green up, red
/// down, mid for no change). Never a tinted wash. The comparison
/// label follows the session rule: sessions 1 to 9 compare vs last
/// session, 10 and up vs the 10-session rolling average.
class DeltaPill extends StatelessWidget {
  const DeltaPill({
    super.key,
    required this.delta,
    required this.sessionNumber,
    this.unit,
    this.showComparisonLabel = false,
    this.comparisonLabelOverride,
  });

  /// Signed point change, e.g. 6 or -3.
  final int delta;

  /// 1-based count of completed sessions; drives the label rule.
  final int sessionNumber;

  /// Optional unit suffix, e.g. 'pts'.
  final String? unit;

  /// When true, renders the comparison label before the pill.
  final bool showComparisonLabel;

  /// Replaces the session-number-derived label. Session docs store
  /// the delta basis at write time; screens rendering a stored basis
  /// pass its label here so history never re-renders differently.
  final String? comparisonLabelOverride;

  /// The comparison copy for a given session number.
  static String comparisonLabel(int sessionNumber) =>
      sessionNumber < 10 ? 'vs last session' : 'vs 10-session avg';

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    final color = delta > 0
        ? colors.green
        : delta < 0
            ? colors.red
            : colors.mid;
    final sign = delta > 0 ? '+' : '';
    final text = unit == null ? '$sign$delta' : '$sign$delta $unit';
    final label = comparisonLabelOverride ?? comparisonLabel(sessionNumber);

    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: sp.sp2, vertical: sp.sp1),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border2),
        borderRadius: context.closRadius.buttonRadius,
      ),
      child: Text(
        text,
        style: ClosType.style(
          fontSize: 12,
          weight: FontWeight.w600,
          color: color,
        ),
      ),
    );

    return Semantics(
      label: '$text $label',
      child: ExcludeSemantics(
        child: showComparisonLabel
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: ClosType.style(
                      fontSize: 13,
                      weight: FontWeight.w400,
                      color: colors.body,
                    ),
                  ),
                  SizedBox(width: sp.sp2),
                  pill,
                ],
              )
            : pill,
      ),
    );
  }
}
