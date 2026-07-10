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
    this.hairline = false,
  });

  final Widget child;
  final ClosCardVariant variant;

  /// Defaults to sp6 (24px) on all sides.
  final EdgeInsetsGeometry? padding;

  /// Gradient hairline across the top edge (dim1 to hi2 and back),
  /// the auth-card treatment.
  final bool hairline;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final inset = variant == ClosCardVariant.inset;
    final resolvedPadding = padding ?? EdgeInsets.all(context.sp.sp6);

    Widget body = Padding(padding: resolvedPadding, child: child);
    if (hairline) {
      final edge = colors.dim1.withValues(alpha: 0);
      body = ClipRRect(
        borderRadius: context.closRadius.cardRadius,
        child: Stack(
          children: [
            body,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.6,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      stops: const [0, 0.3, 0.5, 0.7, 1],
                      colors: [
                        edge,
                        colors.dim1,
                        colors.hi2,
                        colors.dim1,
                        edge,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: inset ? colors.surface2 : colors.surface,
        border: Border.all(
          color: inset ? colors.border2 : colors.border,
        ),
        borderRadius: context.closRadius.cardRadius,
      ),
      child: body,
    );
  }
}
