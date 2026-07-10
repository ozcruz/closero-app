import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Earning-potential progress track: accentDim to accent gradient
/// fill. This is the SOLE accent gradient in the system; do not reuse
/// the gradient anywhere else. Rounded end-caps are the functional
/// full-rounding exception.
class IncomeTrack extends StatelessWidget {
  const IncomeTrack({
    super.key,
    required this.progress,
    this.startLabel,
    this.endLabel,
    this.height = 6,
  });

  /// 0.0 to 1.0 along the market range.
  final double progress;

  /// e.g. '\$40K entry'.
  final String? startLabel;

  /// e.g. '\$150K top performer'.
  final String? endLabel;

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final radius = BorderRadius.circular(context.closRadius.full);

    final track = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: colors.border2),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.accentDim, colors.accent],
                  ),
                  borderRadius: radius,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (startLabel == null && endLabel == null) {
      return Semantics(
        label: 'Income track, ${(progress * 100).round()} percent of range',
        child: ExcludeSemantics(child: track),
      );
    }

    final labelStyle = ClosType.style(
      fontSize: 11,
      weight: FontWeight.w400,
      color: colors.dim1,
    );

    return Semantics(
      label: 'Income track, ${(progress * 100).round()} percent of range, '
          '${startLabel ?? ''} to ${endLabel ?? ''}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            track,
            SizedBox(height: sp.sp2),
            Row(
              children: [
                if (startLabel != null) Text(startLabel!, style: labelStyle),
                const Spacer(),
                if (endLabel != null) Text(endLabel!, style: labelStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
