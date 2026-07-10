import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Dashboard / progress stat card: optional icon in a surface2 box,
/// big value, mid label. [loading] swaps the text for a static
/// skeleton of the same footprint.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.loading = false,
  });

  /// e.g. '9 days'.
  final String value;

  /// e.g. 'Current streak'.
  final String label;

  /// Optional glyph, tinted dim2 and sized by the tile.
  final Widget? icon;

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final radius = context.closRadius;

    Widget text;
    if (loading) {
      text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _skeletonBar(context, width: 64, height: 16),
          SizedBox(height: sp.sp2),
          _skeletonBar(context, width: 96, height: 10),
        ],
      );
    } else {
      text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: ClosType.style(
              fontSize: 18,
              weight: FontWeight.w700,
              color: colors.hi1,
              letterSpacingEm: -0.02,
            ),
          ),
          SizedBox(height: sp.sp1),
          Text(
            label,
            style: ClosType.style(
              fontSize: 12,
              weight: FontWeight.w400,
              color: colors.mid,
            ),
          ),
        ],
      );
    }

    return Semantics(
      label: loading ? 'Loading $label' : '$label: $value',
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.all(sp.sp4),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: radius.cardRadius,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: radius.buttonRadius,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: colors.dim2, size: 16),
                    child: Center(child: icon),
                  ),
                ),
                SizedBox(width: sp.sp3),
              ],
              Expanded(child: text),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonBar(
    BuildContext context, {
    required double width,
    required double height,
  }) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.closColors.surface2,
          borderRadius: context.closRadius.buttonRadius,
        ),
      );
}
