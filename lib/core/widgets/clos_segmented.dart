import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Grayscale segmented switch, e.g. the library's B2C/B2B tracks.
/// Active segment gets a surface2 fill, border2 border, and hi1 text;
/// inactive segments are dim1 text on the bare track. Deliberately
/// never accent: like toggles, it is a utility control.
///
/// The control is 44px tall so every segment meets the minimum tap
/// target.
class ClosSegmented extends StatelessWidget {
  const ClosSegmented({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  /// Segment labels in order, e.g. ['B2C', 'B2B'].
  final List<String> segments;

  final int selectedIndex;

  /// Called with the tapped index. Null renders the disabled state.
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Container(
      height: 44,
      padding: EdgeInsets.all(sp.sp1),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: context.closRadius.buttonRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++)
            _Segment(
              label: segments[i],
              selected: i == selectedIndex,
              onTap: onChanged == null ? null : () => onChanged!(i),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final selected = widget.selected;
    final interactive = widget.onTap != null;

    return Semantics(
      button: true,
      selected: selected,
      enabled: interactive,
      label: widget.label,
      child: MouseRegion(
        cursor: interactive && !selected
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: ExcludeSemantics(
            child: Container(
              constraints: const BoxConstraints(minWidth: 64),
              padding: EdgeInsets.symmetric(horizontal: sp.sp5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.surface2 : null,
                border: Border.all(
                  color: selected ? colors.border2 : Colors.transparent,
                ),
                borderRadius: context.closRadius.buttonRadius,
              ),
              child: Text(
                widget.label,
                style: ClosType.style(
                  fontSize: 13,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? colors.hi1
                      : (_hovered && interactive ? colors.mid : colors.dim1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
