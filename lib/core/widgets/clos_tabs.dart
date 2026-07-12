import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// One tab in a [ClosTabs] strip.
class ClosTab {
  const ClosTab({required this.label, this.count});

  final String label;

  /// Optional count rendered as a small neutral badge, e.g. the live
  /// transcript line count.
  final int? count;
}

/// Underline tab strip (live-sim coaching panel): active tab gets hi1
/// text and a 2px hi1 underline on the shared border track; inactive
/// tabs are dim1. Grayscale only, like every utility control.
///
/// 44px tall so each tab meets the minimum tap target.
class ClosTabs extends StatelessWidget {
  const ClosTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<ClosTab> tabs;
  final int selectedIndex;

  /// Called with the tapped index. Null renders the disabled state.
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: _Tab(
                tab: tabs[i],
                selected: i == selectedIndex,
                onTap: onChanged == null ? null : () => onChanged!(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({required this.tab, required this.selected, required this.onTap});

  final ClosTab tab;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final selected = widget.selected;
    final interactive = widget.onTap != null;
    final textColor = selected
        ? colors.hi1
        : (_hovered && interactive ? colors.mid : colors.dim1);

    return Semantics(
      button: true,
      selected: selected,
      enabled: interactive,
      label: widget.tab.count == null
          ? widget.tab.label
          : '${widget.tab.label}, ${widget.tab.count}',
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
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    // Sits on the strip's border track.
                    color: selected ? colors.hi1 : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.tab.label,
                    style: ClosType.style(
                      fontSize: 13,
                      weight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (widget.tab.count != null) ...[
                    SizedBox(width: sp.sp2),
                    // A true circle (full rounding is circles only).
                    Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surface2,
                        border: Border.all(color: colors.border2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${widget.tab.count}',
                        style: ClosType.style(
                          fontSize: 10,
                          weight: FontWeight.w600,
                          color: selected ? colors.hi2 : colors.dim1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
