import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Notice tone. Errors carry the 3px red left edge and red text; info
/// stays fully neutral. Never a tinted wash, per the chip rules.
enum InlineNoticeKind { info, error }

/// Small inline status message under a form: neutral surface2 panel,
/// state carried by the left edge and text color only.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.kind,
    required this.message,
  });

  final InlineNoticeKind kind;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final isError = kind == InlineNoticeKind.error;

    return Semantics(
      liveRegion: true,
      child: ClipRRect(
        borderRadius: context.closRadius.buttonRadius,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface2,
            border: Border.all(color: colors.border2),
            borderRadius: context.closRadius.buttonRadius,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isError)
                  ColoredBox(
                    color: colors.red,
                    child: const SizedBox(width: 3),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: sp.sp3,
                      vertical: sp.sp2,
                    ),
                    child: Text(
                      message,
                      style: ClosType.style(
                        fontSize: 12.5,
                        weight: FontWeight.w400,
                        color: isError ? colors.red : colors.body,
                      ).copyWith(height: 1.45),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
