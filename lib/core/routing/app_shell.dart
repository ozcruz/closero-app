import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../widgets/widgets.dart';
import 'app_routes.dart';

/// The signed-in app frame: sidebar plus screen content, inside the one
/// grain-bearing scaffold. Nav structure matches the dashboard
/// prototype: Training (Dashboard, Simulations, My Progress), Library
/// (Methodologies, Achievements), Settings pinned at the foot.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.currentPath, required this.child});

  /// The current location path, for the active nav state.
  final String currentPath;
  final Widget child;

  bool _isActive(String path) => path == DashboardRoute.path
      ? currentPath == DashboardRoute.path
      : currentPath == path || currentPath.startsWith('$path/');

  SideNavItem _item(
    BuildContext context, {
    required String label,
    required Widget icon,
    required AppRoute route,
    required String path,
  }) =>
      SideNavItem(
        label: label,
        icon: icon,
        active: _isActive(path),
        onTap: () => route.go(context),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(userDocProvider).value;
    final authUser = ref.watch(authStateProvider).value;
    final entitlement = ref.watch(entitlementProvider);

    final email = userDoc?.email ?? authUser?.email;
    final name = userDoc?.displayName ??
        authUser?.displayName ??
        (email == null ? 'Your account' : email.split('@').first);

    return ClosScaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SideNav(
            collapsed: SideNav.shouldCollapse(context),
            user: SideNavUser(
              name: name,
              plan: '${entitlement.label} plan',
              onTap: () => const SettingsRoute().go(context),
            ),
            groups: [
              SideNavGroup(
                label: 'Training',
                items: [
                  _item(
                    context,
                    label: 'Dashboard',
                    icon: const DashboardIcon(),
                    route: const DashboardRoute(),
                    path: DashboardRoute.path,
                  ),
                  _item(
                    context,
                    label: 'Simulations',
                    icon: const SimulationsIcon(),
                    route: const SimulationsRoute(),
                    path: SimulationsRoute.path,
                  ),
                  _item(
                    context,
                    label: 'My Progress',
                    icon: const ProgressIcon(),
                    route: const ProgressRoute(),
                    path: ProgressRoute.path,
                  ),
                ],
              ),
              SideNavGroup(
                label: 'Library',
                items: [
                  _item(
                    context,
                    label: 'Methodologies',
                    icon: const MethodologiesIcon(),
                    route: const MethodologiesRoute(),
                    path: MethodologiesRoute.path,
                  ),
                  _item(
                    context,
                    label: 'Achievements',
                    icon: const AchievementsIcon(),
                    route: const AchievementsRoute(),
                    path: AchievementsRoute.path,
                  ),
                ],
              ),
            ],
            bottomItems: [
              _item(
                context,
                label: 'Settings',
                icon: const SettingsIcon(),
                route: const SettingsRoute(),
                path: SettingsRoute.path,
              ),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
