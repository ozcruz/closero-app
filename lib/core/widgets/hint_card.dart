import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Coaching hint severity. Shared by [HintCard] and TranscriptLine
/// annotations.
enum HintKind { good, warn, miss }

/// The semantic color for a hint kind.
Color hintKindColor(ClosColors colors, HintKind kind) => switch (kind) {
      HintKind.good => colors.green,
      HintKind.warn => colors.warn,
      HintKind.miss => colors.red,
    };

/// Coaching hint / key-moment card: neutral surface and border with a
/// 3px colored left edge. State is the edge, the label color, nothing
/// else; never a tinted wash.
class HintCard extends StatelessWidget {
  const HintCard({
    super.key,
    required this.kind,
    required this.label,
    this.title,
    this.body,
    this.timestamp,
  });

  final HintKind kind;

  /// Short category label rendered small-caps in the kind color,
  /// e.g. 'Rapport' or 'Strong'.
  final String label;

  /// Optional headline, e.g. 'Disarmed the gatekeeper in under 30 seconds.'
  final String? title;

  /// Optional supporting sentence(s).
  final String? body;

  /// Optional right-aligned time, e.g. '1:14'.
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final edge = hintKindColor(colors, kind);

    return ClipRRect(
      borderRadius: context.closRadius.cardRadius,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: context.closRadius.cardRadius,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: edge,
                child: const SizedBox(width: 3),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(sp.sp4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label.toUpperCase(),
                              style: ClosType.style(
                                fontSize: 11,
                                weight: FontWeight.w600,
                                color: edge,
                                letterSpacingEm: 0.08,
                              ),
                            ),
                          ),
                          if (timestamp != null)
                            Text(
                              timestamp!,
                              style: ClosType.style(
                                fontSize: 11,
                                weight: FontWeight.w400,
                                color: colors.dim1,
                              ),
                            ),
                        ],
                      ),
                      if (title != null) ...[
                        SizedBox(height: sp.sp2),
                        Text(
                          title!,
                          style: ClosType.style(
                            fontSize: 14,
                            weight: FontWeight.w600,
                            color: colors.hi1,
                          ),
                        ),
                      ],
                      if (body != null) ...[
                        SizedBox(height: sp.sp2),
                        Text(
                          body!,
                          style: ClosType.style(
                            fontSize: 13,
                            weight: FontWeight.w400,
                            color: colors.body,
                          ).copyWith(height: 1.45),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
