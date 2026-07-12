import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Neutral chip: surface bg, secondary border, hi2 text. Never a
/// tinted color-wash. Short badge copy is the sentence-case exception.
/// State is carried by the optional solid [dotColor], per the
/// no-tinted-chips rule (e.g. green for live/complete status).
class ClosBadge extends StatelessWidget {
  const ClosBadge({super.key, required this.label, this.dotColor});

  final String label;

  /// Renders a 6px solid status dot before the label when set.
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sp.sp2, vertical: sp.sp1),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border2),
        borderRadius: context.closRadius.buttonRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: sp.sp2),
          ],
          // Flexible so tightly constrained labels wrap exactly as the
          // pre-dot single-child layout did.
          Flexible(
            child: Text(
              label,
              style: ClosType.style(
                fontSize: 11,
                weight: FontWeight.w600,
                color: colors.hi2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
