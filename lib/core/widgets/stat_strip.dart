import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// One cell of a [StatStrip].
class StatStripItem {
  const StatStripItem({required this.value, required this.label});

  /// e.g. '14:32'.
  final String value;

  /// Rendered small caps, e.g. 'Duration'.
  final String label;
}

/// Post-call stat strip (08-score-screen.png): one bordered container,
/// equal-width cells split by hairline dividers, centered value over a
/// small-caps label. Values are chrome-neutral; state never tints the
/// container.
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.items});

  final List<StatStripItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Semantics(
      label: [for (final item in items) '${item.label}: ${item.value}']
          .join(', '),
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: context.closRadius.cardRadius,
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (i > 0)
                    Container(width: 1, color: colors.border),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: sp.sp3,
                        vertical: sp.sp4,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.value,
                            style: ClosType.style(
                              fontSize: 18,
                              weight: FontWeight.w700,
                              color: colors.hi1,
                              letterSpacingEm: -0.02,
                            ),
                          ),
                          SizedBox(height: sp.sp1),
                          Text(
                            item.label.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: ClosType.style(
                              fontSize: 10,
                              weight: FontWeight.w500,
                              color: colors.dim2,
                              letterSpacingEm: 0.08,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
