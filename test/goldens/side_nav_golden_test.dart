@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

/// Placeholder icons: the custom icon set (24-icon-set) lands in a later
/// session; the nav tints whatever icon widget it is given.
SideNav buildNav({required bool collapsed}) => SideNav(
      collapsed: collapsed,
      user: SideNavUser(name: 'Sandra Voss', plan: 'Closer', onTap: () {}),
      groups: [
        SideNavGroup(
          label: 'Training',
          items: [
            SideNavItem(
              label: 'Dashboard',
              icon: const Icon(Icons.grid_view),
              active: true,
              onTap: () {},
            ),
            SideNavItem(
              label: 'Simulations',
              icon: const Icon(Icons.timer_outlined),
              onTap: () {},
            ),
            SideNavItem(
              label: 'My progress',
              icon: const Icon(Icons.bar_chart),
              onTap: () {},
            ),
          ],
        ),
        SideNavGroup(
          label: 'Library',
          items: [
            SideNavItem(
              label: 'Methodologies',
              icon: const Icon(Icons.notes),
              onTap: () {},
            ),
            SideNavItem(
              label: 'Achievements',
              icon: const Icon(Icons.emoji_events_outlined),
              onTap: () {},
            ),
          ],
        ),
      ],
      bottomItems: [
        SideNavItem(
          label: 'Settings',
          icon: const Icon(Icons.settings_outlined),
          onTap: () {},
        ),
      ],
    );

void main() {
  goldenTest(
    'SideNav expanded',
    fileName: 'side_nav',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'expanded, Dashboard active',
          child: SizedBox(height: 480, child: buildNav(collapsed: false)),
        ),
      ],
    ),
  );

  goldenTest(
    'SideNav collapsed rail',
    fileName: 'side_nav_collapsed',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'collapsed, Dashboard active',
          child: SizedBox(height: 480, child: buildNav(collapsed: true)),
        ),
      ],
    ),
  );

  goldenTest(
    'SideNav hover',
    fileName: 'side_nav_hover',
    whilePerforming: hover(find.text('Simulations')),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'hover on Simulations',
          child: SizedBox(height: 480, child: buildNav(collapsed: false)),
        ),
      ],
    ),
  );
}
