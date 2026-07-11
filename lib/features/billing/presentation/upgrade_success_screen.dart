import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/plan_catalog.dart';
import 'billing_shell.dart';

/// Post-purchase confirmation
/// (context/prototype-screens/18-upgrade-success.png), reached when the
/// entitlement watch sees users/{uid}.entitlement flip to closer.
///
/// Accent audit: the Start practicing CTA is the one accent element.
/// Green marks the completed-purchase state (a permitted green use).
class UpgradeSuccessScreen extends StatelessWidget {
  const UpgradeSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final type = context.closType;

    return BillingShell(
      maxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
                borderRadius: context.closRadius.cardRadius,
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: colors.green, size: 30),
                child: const Center(child: CheckIcon()),
              ),
            ),
          ),
          SizedBox(height: sp.sp6),
          Text(
            "You're on Closer",
            textAlign: TextAlign.center,
            style: type.displayMedium,
          ),
          SizedBox(height: sp.headlineToSubtext),
          Text(
            "Welcome in. Everything's unlocked. Here's what just "
            'opened up:',
            textAlign: TextAlign.center,
            style: type.bodyMedium,
          ),
          SizedBox(height: sp.sp6),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final highlight in kCloserUnlockHighlights)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: sp.sp1),
                    child: Semantics(
                      label: '$highlight, unlocked',
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconTheme.merge(
                              data: IconThemeData(
                                color: colors.green,
                                size: 13,
                              ),
                              child: const CheckIcon(),
                            ),
                            SizedBox(width: sp.sp2),
                            Text(
                              highlight,
                              style: ClosType.style(
                                fontSize: 13.5,
                                weight: FontWeight.w400,
                                color: colors.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: sp.sp8),
          PrimaryButton(
            label: 'Start practicing',
            expand: true,
            onPressed: () => const DashboardRoute().go(context),
          ),
          SizedBox(height: sp.sp6),
          Text(
            'Manage or cancel anytime in Settings.',
            textAlign: TextAlign.center,
            style: ClosType.style(
              fontSize: 12.5,
              weight: FontWeight.w400,
              color: colors.mid,
            ),
          ),
        ],
      ),
    );
  }
}
