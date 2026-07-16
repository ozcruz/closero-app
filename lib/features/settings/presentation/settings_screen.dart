import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/analytics_events.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/user_doc.dart';
import '../../billing/application/billing_providers.dart';
import '../../billing/domain/plan_catalog.dart';
import '../data/settings_store.dart';
import 'widgets/settings_widgets.dart';

const List<String> _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// 'Joined Feb 2026' from the auth account's creation time; null when
/// the platform doesn't report one.
@visibleForTesting
String? joinedLabel(DateTime? createdAt) => createdAt == null
    ? null
    : 'Joined ${_shortMonths[createdAt.month - 1]} ${createdAt.year}';

/// Settings (context/prototype-screens/15-settings.png): profile,
/// practice preferences, notifications, plan and billing, account,
/// danger zone. Server-owned fields (entitlement, sessionsUsed) are
/// display-only here; billing changes happen on RevenueCat's hosted
/// surfaces.
///
/// Accent audit: on the free plan the Upgrade button is the view's one
/// accent element; on Closer the view has none.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.closColors;
    final sp = context.sp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: sp.sp10, vertical: sp.sp4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 28),
                child: Center(
                  child: Text(
                    'Settings',
                    style: ClosType.style(
                      fontSize: 15,
                      weight: FontWeight.w700,
                      color: colors.hi1,
                      letterSpacingEm: -0.01,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(sp.sp10, sp.sp8, sp.sp10, sp.sp10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ProfileCard(),
                    SizedBox(height: sp.sectionGap),
                    const _PracticePreferencesCard(),
                    SizedBox(height: sp.sectionGap),
                    const _NotificationsCard(),
                    SizedBox(height: sp.sectionGap),
                    const _PlanBillingCard(),
                    SizedBox(height: sp.sectionGap),
                    const _AccountCard(),
                    SizedBox(height: sp.sectionGap),
                    const _DangerZoneCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Avatar, name and plan line, and the editable display name.
class _ProfileCard extends ConsumerStatefulWidget {
  const _ProfileCard();

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  final _nameController = TextEditingController();
  bool _seeded = false;
  bool _saving = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _currentName(WidgetRef ref) {
    final userDoc = ref.watch(userDocProvider).value;
    final authUser = ref.watch(authStateProvider).value;
    return userDoc?.displayName ?? authUser?.displayName ?? '';
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authServiceProvider).updateDisplayName(name);
      if (mounted) setState(() => _info = 'Name updated.');
    } on Object catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    final userDoc = ref.watch(userDocProvider).value;
    final authUser = ref.watch(authStateProvider).value;
    final phase = ref.watch(planPhaseProvider);

    final email = userDoc?.email ?? authUser?.email;
    final name = _currentName(ref);
    final displayName =
        name.isEmpty ? (email?.split('@').first ?? 'Your account') : name;
    if (!_seeded && name.isNotEmpty) {
      _nameController.text = name;
      _seeded = true;
    }

    final initials = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(2)
        .join();
    final joined = joinedLabel(authUser?.metadata.creationTime);
    final planLine = [
      phase == PlanPhase.trial ? phase.label : '${phase.label} plan',
      ?joined,
    ].join(' · ');

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.surface2,
                  border: Border.all(color: colors.border2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: ClosType.style(
                      fontSize: 18,
                      weight: FontWeight.w600,
                      color: colors.hi2,
                    ),
                  ),
                ),
              ),
              SizedBox(width: sp.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: context.closType.titleLarge),
                    SizedBox(height: sp.sp1),
                    Text(
                      planLine,
                      style: ClosType.style(
                        fontSize: 12.5,
                        weight: FontWeight.w400,
                        color: colors.mid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: sp.sp6),
          ClosTextField(
            label: 'Full name',
            controller: _nameController,
            hintText: 'Your name',
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.name],
            onSubmitted: (_) => _save(),
          ),
          SizedBox(height: sp.sp3),
          Align(
            alignment: Alignment.centerLeft,
            child: GhostButton(
              label: 'Save name',
              size: ClosButtonSize.medium,
              loading: _saving,
              onPressed: _save,
            ),
          ),
          if (_info != null) ...[
            SizedBox(height: sp.sp2),
            InlineNotice(kind: InlineNoticeKind.info, message: _info!),
          ],
          if (_error != null) ...[
            SizedBox(height: sp.sp2),
            InlineNotice(kind: InlineNoticeKind.error, message: _error!),
          ],
        ],
      ),
    );
  }
}

class _PracticePreferencesCard extends ConsumerWidget {
  const _PracticePreferencesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sp = context.sp;
    final colors = context.closColors;
    final prefs =
        ref.watch(settingsPrefsProvider).value ?? const SettingsPrefs();
    final notifier = ref.read(settingsPrefsProvider.notifier);

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Practice preferences'),
          SizedBox(height: sp.sp1),
          Text(
            'Defaults applied when you start a new session. You can '
            'always override per scenario.',
            style: ClosType.style(
              fontSize: 12.5,
              weight: FontWeight.w400,
              color: colors.mid,
            ),
          ),
          SizedBox(height: sp.sp2),
          SettingRow(
            title: 'Default audience',
            description: 'Which scenario set the Simulations library '
                'opens to.',
            trailing: ClosSegmented(
              segments: const ['B2C', 'B2B'],
              selectedIndex: prefs.audience == PracticeAudience.b2b ? 1 : 0,
              onChanged: (index) => notifier.setAudience(
                index == 1 ? PracticeAudience.b2b : PracticeAudience.b2c,
              ),
            ),
          ),
          SettingRow(
            divided: true,
            title: 'Default sim type',
            description: 'Audio-only cold calls or full video simulations.',
            trailing: ClosSegmented(
              segments: const ['Audio', 'Video'],
              selectedIndex: prefs.simType == PracticeSimType.video ? 1 : 0,
              onChanged: (index) => notifier.setSimType(
                index == 1 ? PracticeSimType.video : PracticeSimType.audio,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsCard extends ConsumerWidget {
  const _NotificationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sp = context.sp;
    final colors = context.closColors;
    final prefs =
        ref.watch(settingsPrefsProvider).value ?? const SettingsPrefs();
    final notifier = ref.read(settingsPrefsProvider.notifier);

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Notifications'),
          SizedBox(height: sp.sp1),
          // No false promise: nothing sends email yet. The preferences
          // are saved now and take effect when sending goes live.
          Text(
            'Your choices are saved now. Email delivery turns on when '
            'live sessions launch.',
            style: ClosType.style(
              fontSize: 12.5,
              weight: FontWeight.w400,
              color: colors.mid,
            ),
          ),
          SizedBox(height: sp.sp2),
          SettingRow(
            title: 'Daily streak reminder',
            description: "One nudge if you haven't practiced yet today.",
            trailing: ClosToggle(
              value: prefs.streakReminder,
              semanticLabel: 'Daily streak reminder',
              onChanged: (value) =>
                  notifier.setStreakReminder(value: value),
            ),
          ),
          SettingRow(
            divided: true,
            title: 'Weekly progress summary',
            description: 'Email recap of scores, streak, and earning '
                'potential.',
            trailing: ClosToggle(
              value: prefs.weeklySummary,
              semanticLabel: 'Weekly progress summary',
              onChanged: (value) => notifier.setWeeklySummary(value: value),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBillingCard extends ConsumerStatefulWidget {
  const _PlanBillingCard();

  @override
  ConsumerState<_PlanBillingCard> createState() => _PlanBillingCardState();
}

class _PlanBillingCardState extends ConsumerState<_PlanBillingCard> {
  String? _notice;

  Future<void> _manageBilling() async {
    ref.read(analyticsServiceProvider).capture(
      AnalyticsEvents.manageBillingClicked,
    );
    final billing = ref.read(billingServiceProvider);
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    if (!billing.manageBillingConfigured) {
      // Builds with no billing backend: RevenueCat's receipt emails
      // carry the portal link.
      setState(() {
        _notice = 'Manage your subscription from the link in the '
            'receipt email RevenueCat sent you.';
      });
      return;
    }
    final opened = await billing.openManageBilling(uid: uid);
    if (!opened && mounted) {
      setState(() {
        // Covers every failure honestly: no portal URL, backend
        // unreachable, or the new tab blocked by the browser.
        _notice = 'The billing portal could not open. Try again, or use '
            'the manage link in the receipt email RevenueCat sent you.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final phase = ref.watch(planPhaseProvider);
    final userDoc = ref.watch(userDocProvider).value;
    // Manage billing keys off the PAID state; a trialing user has no
    // subscription to manage yet.
    final onCloser = phase == PlanPhase.closer;

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Plan & billing'),
          SizedBox(height: sp.sp2),
          Row(
            children: [
              ClosBadge(label: phase.label),
              SizedBox(width: sp.sp3),
              Expanded(
                child: switch (phase) {
                  PlanPhase.closer => const _PlanLine(
                      title: 'Unlimited sessions (fair use: '
                          '$kCloserFairUseCap per month)',
                      subtitle: '$kCloserMonthlyPrice/mo or '
                          '$kCloserAnnualPrice/yr. Payments run through '
                          'RevenueCat and Stripe.',
                    ),
                  PlanPhase.trial => const _PlanLine(
                      title: 'Full access, $kTrialDailyCap sessions '
                          'per day',
                      subtitle: 'Everything is unlocked while your trial '
                          'lasts. Closer keeps it that way.',
                    ),
                  PlanPhase.free => _PlanLine(
                      title:
                          '${userDoc?.sessionsUsed ?? 0} of $kFreeSessionCap '
                          'free sessions used this month',
                      subtitle: 'Closer raises the cap to '
                          '$kCloserFairUseCap sessions a month and '
                          'unlocks the full library.',
                    ),
                },
              ),
              SizedBox(width: sp.sp4),
              if (onCloser)
                GhostButton(
                  label: 'Manage billing',
                  size: ClosButtonSize.medium,
                  onPressed: _manageBilling,
                )
              else
                PrimaryButton(
                  label: 'Upgrade to Closer',
                  size: ClosButtonSize.medium,
                  onPressed: () =>
                      const UpgradeRoute(source: UpgradeSource.settings)
                          .go(context),
                ),
            ],
          ),
          if (_notice != null) ...[
            SizedBox(height: sp.sp3),
            InlineNotice(kind: InlineNoticeKind.info, message: _notice!),
          ],
        ],
      ),
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.closType.titleMedium),
        SizedBox(height: context.sp.sp1),
        Text(
          subtitle,
          style: ClosType.style(
            fontSize: 12.5,
            weight: FontWeight.w400,
            color: colors.mid,
          ).copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sp = context.sp;
    // Rebuild on auth changes so linked-provider facts stay current.
    ref.watch(authStateProvider);
    final auth = ref.watch(authServiceProvider);
    final hasPassword = auth.hasPasswordProvider;

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Account'),
          SizedBox(height: sp.sp2),
          SettingRow(
            title: 'Password',
            description: hasPassword
                ? 'Change the password you log in with.'
                : 'Password login is not set up for this account.',
            trailing: GhostButton(
              label: 'Change',
              size: ClosButtonSize.medium,
              onPressed: hasPassword
                  ? () => const SettingsPasswordRoute().go(context)
                  : null,
            ),
          ),
          SettingRow(
            divided: true,
            title: 'Connected accounts',
            description: 'Single sign-on providers linked to this account.',
            trailing: GhostButton(
              label: 'Manage',
              size: ClosButtonSize.medium,
              onPressed: () => const SettingsConnectedRoute().go(context),
            ),
          ),
          SettingRow(
            divided: true,
            title: 'Log out',
            description: 'Sign out on this device.',
            trailing: GhostButton(
              label: 'Log out',
              size: ClosButtonSize.medium,
              onPressed: auth.signOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard();

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Danger zone'),
          SizedBox(height: sp.sp2),
          SettingRow(
            title: 'Delete account',
            description: 'Permanently removes your account. There is no '
                'undo.',
            trailing: DestructiveButton(
              label: 'Delete',
              size: ClosButtonSize.medium,
              onPressed: () => const SettingsDeleteRoute().go(context),
            ),
          ),
        ],
      ),
    );
  }
}
