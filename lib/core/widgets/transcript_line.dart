import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'hint_card.dart';

/// One transcript utterance: speaker label, timestamp, bubble, and an
/// optional coaching annotation. Annotated lines get a small-caps
/// badge next to the header, a 3px colored left edge, and colored
/// annotation text under the bubble; never a tinted chip.
class TranscriptLine extends StatelessWidget {
  const TranscriptLine({
    super.key,
    required this.speaker,
    required this.text,
    this.timestamp,
    this.annotationKind,
    this.annotation,
  });

  /// e.g. 'You' or 'Sandra'. Rendered small caps.
  final String speaker;

  /// The utterance.
  final String text;

  /// e.g. '1:14'.
  final String? timestamp;

  /// Set together with [annotation] to mark a coaching moment.
  final HintKind? annotationKind;

  /// Coaching note rendered under the bubble in the kind color.
  final String? annotation;

  static String _badgeLabel(HintKind kind) => switch (kind) {
        HintKind.good => 'Strong',
        HintKind.warn => 'Watch',
        HintKind.miss => 'Missed',
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final kind = annotationKind;
    final edge = kind == null ? null : hintKindColor(colors, kind);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              speaker.toUpperCase(),
              style: ClosType.style(
                fontSize: 11,
                weight: FontWeight.w600,
                color: colors.mid,
                letterSpacingEm: 0.08,
              ),
            ),
            if (timestamp != null) ...[
              SizedBox(width: sp.sp2),
              Text(
                timestamp!,
                style: ClosType.style(
                  fontSize: 11,
                  weight: FontWeight.w400,
                  color: colors.dim1,
                ),
              ),
            ],
            if (kind != null && edge != null) ...[
              SizedBox(width: sp.sp2),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: sp.sp2, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.border2),
                  borderRadius: context.closRadius.buttonRadius,
                ),
                child: Text(
                  _badgeLabel(kind).toUpperCase(),
                  style: ClosType.style(
                    fontSize: 10,
                    weight: FontWeight.w600,
                    color: edge,
                    letterSpacingEm: 0.08,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: sp.sp2),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(sp.sp4),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: context.closRadius.cardRadius,
          ),
          child: Text(
            text,
            style: context.closType.bodyMedium.copyWith(height: 1.5),
          ),
        ),
        if (annotation != null && edge != null) ...[
          SizedBox(height: sp.sp2),
          Text(
            annotation!,
            style: ClosType.style(
              fontSize: 13,
              weight: FontWeight.w400,
              color: edge,
            ).copyWith(height: 1.4),
          ),
        ],
      ],
    );

    // A fixed left inset keeps annotated and plain lines aligned; the
    // 3px edge fills the inset only on annotated lines.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 3,
            child: edge == null ? null : ColoredBox(color: edge),
          ),
          SizedBox(width: sp.sp3),
          Expanded(child: content),
        ],
      ),
    );
  }
}
