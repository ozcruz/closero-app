import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/theme.dart';

/// Shared frame for the settings sub-pages
/// (context/prototype-screens/19-21): back link to Settings, page
/// headline, intro copy, then the page's cards.
class SettingsSubPage extends StatelessWidget {
  const SettingsSubPage({
    super.key,
    required this.title,
    required this.intro,
    required this.children,
  });

  final String title;
  final String intro;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final type = context.closType;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(sp.sp10, sp.sp8, sp.sp10, sp.sp10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BackToSettingsLink(),
              SizedBox(height: sp.sp4),
              Text(title, style: type.headlineLarge),
              SizedBox(height: sp.headlineToSubtext),
              Text(intro, style: type.bodyMedium.copyWith(height: 1.55)),
              SizedBox(height: sp.sectionGap),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _BackToSettingsLink extends StatefulWidget {
  const _BackToSettingsLink();

  @override
  State<_BackToSettingsLink> createState() => _BackToSettingsLinkState();
}

class _BackToSettingsLinkState extends State<_BackToSettingsLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final color = _hovered ? colors.hi2 : colors.mid;

    return Semantics(
      button: true,
      label: 'Back to settings',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => const SettingsRoute().go(context),
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Text(
                    '‹',
                    style: ClosType.style(
                      fontSize: 15,
                      weight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                SizedBox(width: context.sp.sp2),
                ExcludeSemantics(
                  child: Text(
                    'Settings',
                    style: ClosType.style(
                      fontSize: 13,
                      weight: FontWeight.w600,
                      color: color,
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

/// One settings row: title and description on the left, a control on
/// the right. Rows after the first draw a top divider.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    required this.description,
    required this.trailing,
    this.divided = false,
  });

  final String title;
  final String description;
  final Widget trailing;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Container(
      padding: EdgeInsets.symmetric(vertical: sp.sp4),
      decoration: divided
          ? BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.closType.titleMedium),
                SizedBox(height: sp.sp1),
                Text(
                  description,
                  style: ClosType.style(
                    fontSize: 12.5,
                    weight: FontWeight.w400,
                    color: colors.mid,
                  ).copyWith(height: 1.45),
                ),
              ],
            ),
          ),
          SizedBox(width: sp.sp4),
          trailing,
        ],
      ),
    );
  }
}
