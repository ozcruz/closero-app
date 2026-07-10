import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Neutral chip: surface bg, secondary border, hi2 text. Never a
/// tinted color-wash. Short badge copy is the sentence-case exception.
class ClosBadge extends StatelessWidget {
  const ClosBadge({super.key, required this.label});

  final String label;

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
      child: Text(
        label,
        style: ClosType.style(
          fontSize: 11,
          weight: FontWeight.w600,
          color: colors.hi2,
        ),
      ),
    );
  }
}
