import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Section header styles.
enum SectionHeaderVariant {
  /// In-card header, e.g. 'Skill breakdown' with a 'View all' action.
  title,

  /// Page-level small-caps section label, e.g. 'Key moments'.
  /// Pass sentence case; the widget renders it uppercase.
  label,
}

/// Section header with an optional trailing text action. The trailing
/// action keeps a 44px tap target.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.variant = SectionHeaderVariant.title,
    this.trailingLabel,
    this.onTrailingTap,
  });

  final String title;
  final SectionHeaderVariant variant;

  /// e.g. 'View all'.
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;

    final heading = variant == SectionHeaderVariant.title
        ? Text(title, style: context.closType.titleMedium)
        // Small-caps section labels are dim2 per the token usage note.
        : Text(
            title.toUpperCase(),
            style: ClosType.style(
              fontSize: 11,
              weight: FontWeight.w500,
              color: colors.dim2,
              letterSpacingEm: 0.08,
            ),
          );

    if (trailingLabel == null) return heading;

    return Row(
      children: [
        Expanded(child: heading),
        _TrailingAction(label: trailingLabel!, onTap: onTrailingTap),
      ],
    );
  }
}

class _TrailingAction extends StatefulWidget {
  const _TrailingAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  State<_TrailingAction> createState() => _TrailingActionState();
}

class _TrailingActionState extends State<_TrailingAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final interactive = widget.onTap != null;
    return Semantics(
      button: interactive,
      enabled: interactive,
      child: MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                widget.label,
                style: ClosType.style(
                  fontSize: 12,
                  weight: FontWeight.w500,
                  color: _hovered && interactive ? colors.hi2 : colors.dim1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
