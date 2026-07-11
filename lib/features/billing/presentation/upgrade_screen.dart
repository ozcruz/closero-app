import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/user_doc.dart';
import '../application/billing_providers.dart';
import '../domain/plan_catalog.dart';
import 'billing_shell.dart';

/// The plan-comparison wall (context/prototype-screens/16-billing-upgrade.png):
/// Free column fully grayscale, the Closer column's CTA the view's one
/// accent-filled element.
///
/// Checkout opens the RevenueCat Web Purchase Link in a new tab with
/// app_user_id = the Firebase uid. This screen never grants anything:
/// the webhook flips users/{uid}.entitlement, the entitlement watch
/// below sees the flip and moves to the success screen.
class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  bool _opening = false;
  String? _error;
  bool _checkoutOpened = false;

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      const DashboardRoute().go(context);
    }
  }

  Future<void> _startCheckout() async {
    final uid = ref.read(authStateProvider).value?.uid;
    final email = ref.read(currentUserEmailProvider);
    final billing = ref.read(billingServiceProvider);
    if (uid == null) return;

    setState(() {
      _opening = true;
      _error = null;
    });
    final opened = await billing.openCheckout(uid: uid, email: email);
    if (!mounted) return;
    setState(() {
      _opening = false;
      _checkoutOpened = opened;
      if (!opened) {
        _error = 'Checkout could not open. Allow popups for this site '
            'and try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final type = context.closType;
    final colors = context.closColors;

    // The purchase completes in the checkout tab; the webhook flips the
    // entitlement and this watch moves the app tab forward.
    ref.listen(entitlementProvider, (previous, next) {
      if (previous != Entitlement.closer && next == Entitlement.closer) {
        const UpgradeSuccessRoute().go(context);
      }
    });

    // Keep the auth stream live so _startCheckout's read sees the
    // signed-in uid (providers are lazy; nothing else here watches it).
    ref.watch(authStateProvider);
    final entitlement = ref.watch(entitlementProvider);
    final onCloser = entitlement == Entitlement.closer;
    final checkoutConfigured =
        ref.watch(billingServiceProvider).checkoutConfigured;

    return BillingShell(
      title: 'Upgrade to Closer',
      onClose: () => _close(context),
      maxWidth: 1080,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Practice without limits.',
            textAlign: TextAlign.center,
            style: type.displayMedium,
          ),
          SizedBox(height: sp.headlineToSubtext),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(
                'Free gets you started. Closer removes the cap and '
                'unlocks the full library: every methodology, every '
                'scenario, every session logged.',
                textAlign: TextAlign.center,
                style: type.bodyLarge.copyWith(height: 1.55),
              ),
            ),
          ),
          SizedBox(height: sp.sp10),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 760;
              final free = _PlanCard(
                stretch: !stacked,
                badge: onCloser ? null : 'Current plan',
                name: 'Free',
                price: r'$0',
                priceNote: 'Enough to get a real feel for the product.',
                includes: kFreePlanIncludes,
                excludes: kFreePlanExcludes,
                cta: GhostButton(
                  label: 'Continue on free',
                  expand: true,
                  onPressed: () => _close(context),
                ),
              );
              final closer = _PlanCard(
                stretch: !stacked,
                badge: onCloser ? 'Current plan' : 'Recommended',
                emphasized: true,
                name: 'Closer',
                price: kCloserMonthlyPrice,
                savingsNote: kAnnualSavingsNote,
                priceNote:
                    'For reps actually trying to close their skill gaps.',
                includes: kCloserPlanIncludes,
                cta: onCloser
                    ? const GhostButton(label: 'Your current plan', expand: true)
                    : PrimaryButton(
                        label: 'Upgrade to Closer',
                        expand: true,
                        loading: _opening,
                        onPressed:
                            checkoutConfigured ? _startCheckout : null,
                      ),
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    free,
                    SizedBox(height: sp.sectionGap),
                    closer,
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: free),
                    SizedBox(width: sp.sectionGap),
                    Expanded(child: closer),
                  ],
                ),
              );
            },
          ),
          if (!checkoutConfigured && !onCloser) ...[
            SizedBox(height: sp.sp4),
            const InlineNotice(
              kind: InlineNoticeKind.error,
              message: 'Checkout is not configured in this build '
                  '(RC_PURCHASE_LINK is unset).',
            ),
          ],
          if (_error != null) ...[
            SizedBox(height: sp.sp4),
            InlineNotice(kind: InlineNoticeKind.error, message: _error!),
          ],
          if (_checkoutOpened && !onCloser) ...[
            SizedBox(height: sp.sp4),
            const InlineNotice(
              kind: InlineNoticeKind.info,
              message: 'Checkout opened in a new tab. This page moves on '
                  'by itself once payment completes.',
            ),
          ],
          SizedBox(height: sp.sp8),
          Text(
            'Cancel anytime. Payments handled securely by Stripe.',
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

/// One pricing column. Emphasis is border-only (emphasized card
/// variant); the recommended tier's CTA carries the accent.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    this.badge,
    this.emphasized = false,
    this.stretch = false,
    required this.name,
    required this.price,
    this.savingsNote,
    required this.priceNote,
    required this.includes,
    this.excludes = const [],
    required this.cta,
  });

  final String? badge;
  final bool emphasized;

  /// True in the side-by-side layout, where the card has a bounded
  /// height and the CTA pins to the foot so the two columns align.
  final bool stretch;
  final String name;
  final String price;
  final String? savingsNote;
  final String priceNote;
  final List<String> includes;
  final List<String> excludes;
  final Widget cta;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final type = context.closType;

    return ClosCard(
      variant:
          emphasized ? ClosCardVariant.emphasized : ClosCardVariant.normal,
      padding: EdgeInsets.all(sp.sp8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            ClosBadge(label: badge!),
            SizedBox(height: sp.sp4),
          ],
          Text(name, style: type.titleLarge),
          SizedBox(height: sp.sp2),
          Text.rich(
            TextSpan(
              text: price,
              style: ClosType.style(
                fontSize: 34,
                weight: FontWeight.w700,
                color: colors.hi1,
                letterSpacingEm: -0.02,
              ),
              children: [
                TextSpan(
                  text: ' / month',
                  style: ClosType.style(
                    fontSize: 13,
                    weight: FontWeight.w400,
                    color: colors.dim1,
                  ),
                ),
              ],
            ),
          ),
          if (savingsNote != null) ...[
            SizedBox(height: sp.sp1),
            Text(
              savingsNote!,
              style: ClosType.style(
                fontSize: 12.5,
                weight: FontWeight.w500,
                color: colors.body,
              ),
            ),
          ],
          SizedBox(height: sp.sp1),
          Text(
            priceNote,
            style: ClosType.style(
              fontSize: 12.5,
              weight: FontWeight.w400,
              color: colors.mid,
            ),
          ),
          SizedBox(height: sp.sp6),
          for (final feature in includes)
            _FeatureRow(label: feature, included: true),
          for (final feature in excludes)
            _FeatureRow(label: feature, included: false),
          SizedBox(height: sp.sp6),
          if (stretch) const Spacer(),
          cta,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label, required this.included});

  final String label;
  final bool included;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Semantics(
      label: included ? '$label, included' : '$label, not included',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: sp.sp1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: IconTheme.merge(
                  data: IconThemeData(
                    color: included ? colors.hi2 : colors.dim2,
                    size: 13,
                  ),
                  child:
                      included ? const CheckIcon() : const CloseIcon(),
                ),
              ),
              SizedBox(width: sp.sp2),
              Expanded(
                child: Text(
                  label,
                  style: ClosType.style(
                    fontSize: 13,
                    weight: FontWeight.w400,
                    color: included ? colors.body : colors.mid,
                  ).copyWith(height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
