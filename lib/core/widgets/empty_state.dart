import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Centered empty state: icon in a surface2 box, headline, supporting
/// copy, optional action. One empty state per view, never a grid of
/// broken charts.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  /// Glyph shown in the icon box, tinted dim2.
  final Widget icon;

  /// e.g. 'Your progress will show up here'.
  final String title;

  /// Supporting copy in the body token.
  final String? body;

  /// Optional CTA, e.g. a PrimaryButton or GhostButton.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: context.closRadius.cardRadius,
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: colors.dim2, size: 22),
            child: Center(child: icon),
          ),
        ),
        SizedBox(height: sp.sp6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.closType.headlineMedium,
        ),
        if (body != null) ...[
          SizedBox(height: sp.headlineToSubtext),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              body!,
              textAlign: TextAlign.center,
              style: context.closType.bodyMedium.copyWith(height: 1.5),
            ),
          ),
        ],
        if (action != null) ...[
          SizedBox(height: sp.sp6),
          action!,
        ],
      ],
    );
  }
}
