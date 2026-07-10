import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Card surface variants.
enum ClosCardVariant {
  /// Standard card: surface bg, primary border.
  normal,

  /// Inset panel inside a card: surface2 bg, secondary border.
  inset,
}

/// The base card surface: token bg, 1px border, card radius.
/// Never a shadow or glow.
class ClosCard extends StatelessWidget {
  const ClosCard({
    super.key,
    required this.child,
    this.variant = ClosCardVariant.normal,
    this.padding,
  });

  final Widget child;
  final ClosCardVariant variant;

  /// Defaults to sp6 (24px) on all sides.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final inset = variant == ClosCardVariant.inset;
    return Container(
      padding: padding ?? EdgeInsets.all(context.sp.sp6),
      decoration: BoxDecoration(
        color: inset ? colors.surface2 : colors.surface,
        border: Border.all(
          color: inset ? colors.border2 : colors.border,
        ),
        borderRadius: context.closRadius.cardRadius,
      ),
      child: child,
    );
  }
}
