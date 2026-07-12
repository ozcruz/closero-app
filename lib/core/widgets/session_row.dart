import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'clos_icons.dart';
import 'score_ring.dart';

/// One completed session in a list (dashboard recents, progress
/// history). Icon box, title over a methodology-and-time meta line,
/// score text on the scoreText ramp. The row is a button; hosts route
/// it to the session's score screen.
class SessionRow extends StatefulWidget {
  const SessionRow({
    super.key,
    required this.title,
    required this.methodology,
    required this.timeAgo,
    required this.score,
    this.divided = false,
    this.onTap,
  });

  /// e.g. 'Inbound Demo, Hesitant Buyer'.
  final String title;

  /// e.g. 'Sandler'.
  final String methodology;

  /// e.g. '2h ago'.
  final String timeAgo;

  /// 0 to 100, server-written.
  final int score;

  /// Draws a top divider (every row but the first).
  final bool divided;

  final VoidCallback? onTap;

  @override
  State<SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends State<SessionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Semantics(
      button: true,
      label: '${widget.title}, ${widget.methodology}, '
          '${widget.timeAgo}, scored ${widget.score} percent',
      child: MouseRegion(
        cursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: ExcludeSemantics(
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding:
                  EdgeInsets.symmetric(horizontal: sp.sp6, vertical: sp.sp3),
              decoration: BoxDecoration(
                color: _hovered ? colors.surface2 : null,
                border: widget.divided
                    ? Border(top: BorderSide(color: colors.border))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      border: Border.all(color: colors.border2),
                      borderRadius: context.closRadius.buttonRadius,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(color: colors.dim2, size: 15),
                      child: const Center(child: SimulationsIcon()),
                    ),
                  ),
                  SizedBox(width: sp.sp3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.closType.titleMedium,
                        ),
                        SizedBox(height: sp.sp1),
                        Text(
                          '${widget.methodology} · ${widget.timeAgo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClosType.style(
                            fontSize: 12,
                            weight: FontWeight.w400,
                            color: colors.dim1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: sp.sp4),
                  Text(
                    '${widget.score}%',
                    style: ClosType.style(
                      fontSize: 14,
                      weight: FontWeight.w700,
                      color: scoreTextColor(colors, widget.score),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
