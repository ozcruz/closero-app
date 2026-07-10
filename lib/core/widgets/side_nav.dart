import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The signed-in user shown at the top of the sidebar.
class SideNavUser {
  const SideNavUser({required this.name, required this.plan, this.onTap});

  final String name;

  /// Plan line under the name, e.g. "Closer" or "Free".
  final String plan;
  final VoidCallback? onTap;
}

/// A labelled group of nav items ("Training", "Library").
class SideNavGroup {
  const SideNavGroup({this.label, required this.items});

  final String? label;
  final List<SideNavItem> items;
}

class SideNavItem {
  const SideNavItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.active = false,
  });

  final String label;

  /// A 15x15 icon; the nav tints it (dim2 rest, hi2 active) and drives
  /// its opacity, so pass it uncolored.
  final Widget icon;
  final VoidCallback? onTap;
  final bool active;
}

/// The app sidebar. No logo, per the wordmark rules. Active item is hi2
/// text, a 2px accentDim left border, and a faint hi1 tint. Collapses to
/// an icon-only rail on narrow web; icon-only tiles get tooltips and
/// semantic labels.
class SideNav extends StatelessWidget {
  const SideNav({
    super.key,
    required this.user,
    required this.groups,
    this.bottomItems = const [],
    this.collapsed = false,
  });

  final SideNavUser user;
  final List<SideNavGroup> groups;

  /// Pinned under a top border at the sidebar's foot (Settings).
  final List<SideNavItem> bottomItems;
  final bool collapsed;

  /// Whether the shell should render the collapsed rail at this
  /// viewport width (below the collapse breakpoint token).
  static bool shouldCollapse(BuildContext context) =>
      MediaQuery.sizeOf(context).width < context.closLayout.collapseBelow;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final width = collapsed ? sp.sp16 : context.closLayout.sidebar;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(sp.sp4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: _UserCard(user: user, collapsed: collapsed),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: sp.sp3),
              child: Column(
                children: [
                  for (final group in groups) ...[
                    if (group.label != null)
                      collapsed
                          ? SizedBox(height: sp.sp3)
                          : Container(
                              width: double.infinity,
                              padding: EdgeInsets.fromLTRB(
                                  sp.sp4, sp.sp3, sp.sp4, sp.sp1),
                              child: Text(
                                group.label!,
                                style: ClosType.style(
                                  fontSize: 10,
                                  weight: FontWeight.w600,
                                  color: colors.dim3,
                                  letterSpacingEm: 0.05,
                                ),
                              ),
                            ),
                    for (final item in group.items)
                      _SideNavTile(item: item, collapsed: collapsed),
                  ],
                ],
              ),
            ),
          ),
          if (bottomItems.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: sp.sp2),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Column(
                children: [
                  for (final item in bottomItems)
                    _SideNavTile(item: item, collapsed: collapsed),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SideNavTile extends StatefulWidget {
  const _SideNavTile({required this.item, required this.collapsed});

  final SideNavItem item;
  final bool collapsed;

  @override
  State<_SideNavTile> createState() => _SideNavTileState();
}

class _SideNavTileState extends State<_SideNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final item = widget.item;

    final interactive = item.onTap != null;
    final hovered = _hovered && interactive;
    final color = item.active
        ? colors.hi2
        : hovered
            ? colors.mid
            : colors.dim2;

    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);

    final icon = Opacity(
      opacity: item.active ? 1 : 0.7,
      child: IconTheme.merge(
        data: IconThemeData(color: color, size: 15),
        child: item.icon,
      ),
    );

    Widget tile = AnimatedContainer(
      duration: duration,
      curve: Curves.fastOutSlowIn,
      transform:
          Matrix4.translationValues(0, hovered && !item.active ? -1 : 0, 0),
      constraints: const BoxConstraints(minHeight: 44),
      padding: widget.collapsed
          ? null
          : EdgeInsets.symmetric(horizontal: sp.sp4),
      decoration: BoxDecoration(
        // Inactive border matches the sidebar bg so only active shows.
        color: item.active ? colors.hi1.withValues(alpha: 0.03) : null,
        border: Border(
          left: BorderSide(
            width: 2,
            color: item.active ? colors.accentDim : colors.sidebar,
          ),
        ),
      ),
      child: widget.collapsed
          ? Center(child: icon)
          : Row(
              children: [
                icon,
                SizedBox(width: sp.sp2),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClosType.style(
                      fontSize: 13,
                      weight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
    );

    if (widget.collapsed) {
      tile = Tooltip(message: item.label, child: tile);
    }

    return Semantics(
      button: true,
      selected: item.active,
      enabled: interactive,
      label: widget.collapsed ? item.label : null,
      child: FocusableActionDetector(
        enabled: interactive,
        onShowFocusHighlight: (value) => setState(() => _hovered = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              item.onTap?.call();
              return null;
            },
          ),
        },
        // Plain MouseRegion: hover must not depend on the focus
        // highlight mode (see _ClosButtonBase).
        child: MouseRegion(
          cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: item.onTap,
            child: tile,
          ),
        ),
      ),
    );
  }
}

/// Avatar + name + plan + chevron at the top of the sidebar. Collapsed,
/// it reduces to the avatar with a tooltip.
class _UserCard extends StatefulWidget {
  const _UserCard({required this.user, required this.collapsed});

  final SideNavUser user;
  final bool collapsed;

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _hovered = false;

  String get _initials {
    final parts = widget.user.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final user = widget.user;
    final interactive = user.onTap != null;

    final avatar = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: colors.surface2,
        border: Border.all(color: colors.border2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: ClosType.style(
          fontSize: 11,
          weight: FontWeight.w700,
          color: colors.dim1,
        ),
      ),
    );

    Widget card;
    if (widget.collapsed) {
      card = Tooltip(
        message: '${user.name}, ${user.plan}',
        child: Center(child: avatar),
      );
    } else {
      card = Row(
        children: [
          avatar,
          SizedBox(width: sp.sp2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClosType.style(
                    fontSize: 13,
                    weight: FontWeight.w600,
                    color: colors.hi2,
                  ),
                ),
                Text(
                  user.plan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClosType.style(
                    fontSize: 11,
                    weight: FontWeight.w400,
                    color: colors.dim2,
                  ),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(12, 12),
            painter: _ChevronPainter(
              color: _hovered && interactive ? colors.hi2 : colors.dim2,
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: interactive,
      enabled: interactive,
      label: widget.collapsed ? '${user.name}, ${user.plan}' : null,
      child: FocusableActionDetector(
        enabled: interactive,
        onShowFocusHighlight: (value) => setState(() => _hovered = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              user.onTap?.call();
              return null;
            },
          ),
        },
        // Plain MouseRegion: hover must not depend on the focus
        // highlight mode (see _ClosButtonBase).
        child: MouseRegion(
          cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: user.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: widget.collapsed ? card : Center(child: card),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width / 12;
    final h = size.height / 12;
    final path = Path()
      ..moveTo(4 * w, 3 * h)
      ..lineTo(7 * w, 6 * h)
      ..lineTo(4 * w, 9 * h);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) =>
      oldDelegate.color != color;
}
