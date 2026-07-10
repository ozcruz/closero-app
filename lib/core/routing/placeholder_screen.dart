import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'app_routes.dart';

/// Temporary stand-in while a screen's build session lands. Routes are
/// registered from day one so deep links and guards are stable; the
/// content here is honest about what exists.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.detail,
    this.action,
  });

  final String title;

  /// Optional context line, e.g. the deep-linked session id.
  final String? detail;

  /// Optional temporary action (e.g. the settings log out button).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final type = context.closType;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: type.headlineMedium),
          SizedBox(height: sp.sp3),
          Text(
            detail == null
                ? 'This screen is not built yet.'
                : 'This screen is not built yet. ($detail)',
            style: type.bodyMedium,
          ),
          if (action != null) ...[
            SizedBox(height: sp.sp6),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Unknown routes. No prototype screenshot exists for the 404; this
/// matches the shell style per the build plan.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final type = context.closType;

    return ClosScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Page not found', style: type.headlineMedium),
            SizedBox(height: sp.sp3),
            Text(
              'That page does not exist, or it moved.',
              style: type.bodyMedium,
            ),
            SizedBox(height: sp.sp6),
            GhostButton(
              label: 'Back to dashboard',
              onPressed: () => const DashboardRoute().go(context),
            ),
          ],
        ),
      ),
    );
  }
}
