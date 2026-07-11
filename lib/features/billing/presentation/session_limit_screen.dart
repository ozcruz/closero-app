import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/user_doc.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../domain/plan_catalog.dart';
import 'billing_shell.dart';

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// When the free cap resets: the first of next month, e.g. 'August 1'.
/// Mirrors the server's usageMonth key rollover.
@visibleForTesting
String freeCapResetLabel(DateTime now) {
  final next = now.month == 12
      ? DateTime(now.year + 1)
      : DateTime(now.year, now.month + 1);
  return '${_monthNames[next.month - 1]} 1';
}

/// The cap wall (context/prototype-screens/17-session-limit.png), shown
/// when startSimSession reports the free cap is spent. Display only:
/// the server decides the cap, this screen never counts sessions.
///
/// Accent audit: the Upgrade CTA is the view's one accent element. The
/// five used-session dots are grayscale (they are not momentum dots).
class SessionLimitScreen extends ConsumerWidget {
  const SessionLimitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.closColors;
    final sp = context.sp;
    final type = context.closType;

    // If the upgrade lands while this wall is up (checkout finished in
    // another tab), the wall is no longer true; move on.
    ref.listen(entitlementProvider, (previous, next) {
      if (previous != Entitlement.closer && next == Entitlement.closer) {
        const UpgradeSuccessRoute().go(context);
      }
    });

    final resetLabel = freeCapResetLabel(ref.watch(clockProvider)());

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
                data: IconThemeData(color: colors.hi2, size: 30),
                child: const Center(child: LockIcon()),
              ),
            ),
          ),
          SizedBox(height: sp.sp6),
          Semantics(
            label: 'All $kFreeSessionCap free sessions used',
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < kFreeSessionCap; i++)
                    Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colors.hi2,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: sp.sp5),
          Text(
            "You've used all $kFreeSessionCap free sessions this month",
            textAlign: TextAlign.center,
            style: type.headlineLarge,
          ),
          SizedBox(height: sp.headlineToSubtext),
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              text: 'Your free sessions reset on ',
              style: type.bodyMedium.copyWith(height: 1.6),
              children: [
                TextSpan(
                  text: resetLabel,
                  style: ClosType.style(
                    fontSize: 14,
                    weight: FontWeight.w600,
                    color: colors.hi2,
                  ),
                ),
                const TextSpan(
                  text: '. Upgrade to Closer for unlimited practice, '
                      'plus the full B2B library, methodologies, and '
                      'live coaching on every call.',
                ),
              ],
            ),
          ),
          SizedBox(height: sp.sp8),
          PrimaryButton(
            label: 'Upgrade to Closer',
            expand: true,
            onPressed: () => const UpgradeRoute().go(context),
          ),
          SizedBox(height: sp.sp3),
          GhostButton(
            label: 'Maybe later',
            expand: true,
            onPressed: () => const DashboardRoute().go(context),
          ),
          SizedBox(height: sp.sp6),
          Text(
            'Closer is $kCloserMonthlyPrice/mo or $kCloserAnnualPrice/yr. '
            'Cancel anytime.',
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
