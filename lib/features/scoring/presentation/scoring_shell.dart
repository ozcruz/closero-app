import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Standalone (no-sidebar) frame shared by the post-call score and
/// transcript screens (08-score-screen.png, 09-transcript.png): brand
/// ring, divider, screen title on the left; session meta and an
/// optional action on the right; scrollable centered body.
class ScoringShell extends StatelessWidget {
  const ScoringShell({
    super.key,
    required this.title,
    this.meta,
    this.trailing,
    this.metaBar,
    required this.maxWidth,
    required this.child,
  });

  /// Topbar title, e.g. 'Session complete'.
  final String title;

  /// Right-aligned context line, e.g. 'Cold call · Sandra Voss · 14:32'.
  final String? meta;

  /// Optional topbar action after the meta (e.g. 'Back to score').
  final Widget? trailing;

  /// Optional second bar under the topbar (transcript meta strip).
  final Widget? metaBar;

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClosScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: sp.sp6, vertical: sp.sp3),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                const CloseroMark(),
                SizedBox(width: sp.sp4),
                Container(width: 1, height: 16, color: colors.border2),
                SizedBox(width: sp.sp4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClosType.style(
                      fontSize: 13,
                      weight: FontWeight.w600,
                      color: colors.mid,
                    ),
                  ),
                ),
                if (meta != null) ...[
                  SizedBox(width: sp.sp4),
                  Text(
                    meta!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClosType.style(
                      fontSize: 12,
                      weight: FontWeight.w400,
                      color: colors.dim1,
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  SizedBox(width: sp.sp4),
                  trailing!,
                ],
              ],
            ),
          ),
          ?metaBar,
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(sp.sp6, sp.sp12, sp.sp6, sp.sp16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// mm:ss for durations and transcript timestamps.
String formatClock(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
