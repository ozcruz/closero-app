import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../library/data/scenario_repository.dart';
import '../../library/presentation/scenario_preview_modal.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_data.dart';

/// The mechanically true time-of-day greeting.
String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// The signed-in home screen (context/prototype-screens/02-dashboard.png):
/// topbar greeting + streak, next-session hero, skill breakdown sorted
/// weakest first, earning potential, recent sessions. All data arrives
/// through [DashboardRepository]; the screen never computes a score.
///
/// Accent audit: the hero's Start session CTA is the view's one
/// accent-filled element. The IncomeTrack gradient is its own permitted
/// use (the sole accent gradient in the system).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardDataProvider);

    return data.when(
      // The fixture load resolves within a frame; no skeleton flash.
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The dashboard could not load.',
              style: context.closType.headlineSmall,
            ),
            SizedBox(height: context.sp.sp3),
            Text(
              'Check your connection and try again.',
              style: context.closType.bodyMedium,
            ),
            SizedBox(height: context.sp.sp6),
            GhostButton(
              label: 'Try again',
              size: ClosButtonSize.medium,
              onPressed: () => ref.invalidate(dashboardDataProvider),
            ),
          ],
        ),
      ),
      data: (data) => _DashboardBody(data: data),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(streakDays: data.streakDays),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(sp.sp10, sp.sp8, sp.sp10, sp.sp10),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.closLayout.siteContainerMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(scenario: data.featured),
                    SizedBox(height: sp.sectionGap),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final skills =
                            _SkillBreakdownCard(skills: data.skills);
                        final earning =
                            _EarningPotentialCard(earning: data.earning);
                        if (constraints.maxWidth < 860) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              skills,
                              SizedBox(height: sp.sectionGap),
                              earning,
                            ],
                          );
                        }
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: skills),
                              SizedBox(width: sp.sectionGap),
                              Expanded(child: earning),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: sp.sectionGap),
                    _RecentSessionsCard(sessions: data.recentSessions),
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

/// Greeting left, streak pill right, over a bottom border.
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.closColors;
    final sp = context.sp;

    final userDoc = ref.watch(userDocProvider).value;
    final authUser = ref.watch(authStateProvider).value;
    final email = userDoc?.email ?? authUser?.email;
    final name =
        userDoc?.displayName ?? authUser?.displayName ?? email?.split('@').first;
    final firstName = name?.trim().split(RegExp(r'\s+')).first;

    final greeting = greetingFor(ref.watch(clockProvider)());

    return Container(
      padding: EdgeInsets.symmetric(horizontal: sp.sp10, vertical: sp.sp4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: firstName == null ? '$greeting.' : '$greeting, $firstName.',
                style: ClosType.style(
                  fontSize: 15,
                  weight: FontWeight.w700,
                  color: colors.hi1,
                  letterSpacingEm: -0.01,
                ),
                children: [
                  TextSpan(
                    text: '  Ready to close?',
                    style: ClosType.style(
                      fontSize: 14,
                      weight: FontWeight.w400,
                      color: colors.body,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: sp.sp4),
          StreakPill(days: streakDays),
        ],
      ),
    );
  }
}

/// Next-session hero: label, title, description, tags, CTAs on the
/// left; persona avatar on the right; meta strip along the foot.
class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.scenario});

  final FeaturedScenario scenario;

  /// Opens the shared Scenario Preview modal for the hero, resolved
  /// from the one shared catalog by id (the repository test pins that
  /// every hero id resolves).
  Future<void> _preview(BuildContext context, WidgetRef ref) async {
    final resolved =
        await ref.read(scenarioRepositoryProvider).byId(scenario.id);
    if (resolved == null || !context.mounted) return;
    await showScenarioPreviewModal(context, scenario: resolved);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.closColors;
    final sp = context.sp;
    final type = context.closType;

    return ClosCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(sp.sp8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Next-session marker, on the accentDim tier
                          // like the sidebar's active edge; never a
                          // second full-accent element.
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: colors.accentDim,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: sp.sp2),
                          const SectionHeader(
                            title: 'Next session',
                            variant: SectionHeaderVariant.label,
                          ),
                        ],
                      ),
                      SizedBox(height: sp.headlineToSubtext),
                      Text(scenario.title, style: type.displaySmall),
                      SizedBox(height: sp.headlineToSubtext),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Text(
                          scenario.description,
                          style: type.bodyMedium.copyWith(height: 1.55),
                        ),
                      ),
                      SizedBox(height: sp.sp4),
                      Wrap(
                        spacing: sp.sp2,
                        runSpacing: sp.sp2,
                        children: [
                          for (final tag in scenario.tags)
                            ClosBadge(label: tag),
                        ],
                      ),
                      SizedBox(height: sp.sp6),
                      Wrap(
                        spacing: sp.sp3,
                        runSpacing: sp.sp3,
                        children: [
                          PrimaryButton(
                            label: 'Start session',
                            onPressed: () =>
                                ColdCallSimRoute(scenarioId: scenario.id)
                                    .go(context),
                          ),
                          GhostButton(
                            label: 'Preview scenario',
                            onPressed: () => _preview(context, ref),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: sp.sp8),
                _PersonaSide(scenario: scenario),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: sp.sp8, vertical: sp.sp4),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Wrap(
              spacing: sp.sp8,
              runSpacing: sp.sp2,
              children: [
                _MetaItem(label: 'Est.', value: scenario.duration),
                _MetaItem(label: 'Targets', value: scenario.targets),
                _MetaItem(
                  label: 'Difficulty',
                  value: scenario.difficultyLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar, persona line, difficulty dots on the hero's right.
class _PersonaSide extends StatelessWidget {
  const _PersonaSide({required this.scenario});

  final FeaturedScenario scenario;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SizedBox(
            width: 96,
            height: 96,
            child: AvatarStack(
              initials: scenario.initials,
              tint: scenario.tint,
              semanticLabel: '${scenario.personaLine}, AI persona',
            ),
          ),
        ),
        SizedBox(height: sp.sp3),
        Text(
          'AI persona',
          style: ClosType.style(
            fontSize: 11,
            weight: FontWeight.w400,
            color: colors.dim2,
          ),
        ),
        SizedBox(height: sp.sp1),
        Text(
          scenario.personaLine,
          style: ClosType.style(
            fontSize: 13,
            weight: FontWeight.w600,
            color: colors.hi2,
          ),
        ),
        SizedBox(height: sp.sp2),
        Semantics(
          label: 'Difficulty ${scenario.difficulty} '
              'of ${scenario.difficultyMax}',
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < scenario.difficultyMax; i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i < scenario.difficulty
                            ? colors.mid
                            : colors.border2,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One 'label value' pair in the hero's meta strip.
class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: ClosType.style(
          fontSize: 12,
          weight: FontWeight.w400,
          color: colors.dim1,
        ),
        children: [
          TextSpan(
            text: value,
            style: ClosType.style(
              fontSize: 12,
              weight: FontWeight.w500,
              color: colors.mid,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skill rows sorted weakest first (the repository guarantees order).
/// Bars color by the ring/bar threshold rule, the percent text by the
/// scoreText ramp; never accent.
class _SkillBreakdownCard extends StatelessWidget {
  const _SkillBreakdownCard({required this.skills});

  final List<SkillScore> skills;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Skill breakdown',
            trailingLabel: 'View all',
            onTrailingTap: () => const ProgressRoute().go(context),
          ),
          SizedBox(height: sp.sp2),
          for (final skill in skills) _SkillRow(skill: skill),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill});

  final SkillScore skill;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Semantics(
      label: '${skill.label}, ${skill.percent} percent',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: sp.sp3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  skill.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClosType.style(
                    fontSize: 13,
                    weight: FontWeight.w400,
                    color: colors.body,
                  ),
                ),
              ),
              SizedBox(width: sp.sp3),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(context.closRadius.full),
                  child: SizedBox(
                    height: 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: colors.border2),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: skill.percent / 100,
                          child: ColoredBox(
                            color: scoreThresholdColor(colors, skill.percent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${skill.percent}%',
                  textAlign: TextAlign.right,
                  style: ClosType.style(
                    fontSize: 13,
                    weight: FontWeight.w600,
                    color: scoreTextColor(colors, skill.percent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Earning potential: market-median figure, skill-tier delta (never a
/// personal dollar delta), the income track, and the sourced next-tier
/// note in an inset panel.
class _EarningPotentialCard extends StatelessWidget {
  const _EarningPotentialCard({required this.earning});

  final EarningPotential earning;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Earning potential'),
          SizedBox(height: sp.sp4),
          Text(
            'At your current skill level',
            style: ClosType.style(
              fontSize: 12,
              weight: FontWeight.w400,
              color: colors.mid,
            ),
          ),
          SizedBox(height: sp.sp1),
          Text(
            earning.currentLabel,
            style: ClosType.style(
              fontSize: 34,
              weight: FontWeight.w700,
              color: colors.hi1,
              letterSpacingEm: -0.02,
            ),
          ),
          SizedBox(height: sp.sp1),
          Semantics(
            label: 'Up ${earning.tierDelta}',
            child: ExcludeSemantics(
              // Green is permitted here: a positive delta.
              child: Text(
                '↑ ${earning.tierDelta}',
                style: ClosType.style(
                  fontSize: 13,
                  weight: FontWeight.w500,
                  color: colors.green,
                ),
              ),
            ),
          ),
          SizedBox(height: sp.sp5),
          IncomeTrack(
            progress: earning.progress,
            startLabel: earning.entryLabel,
            endLabel: earning.topLabel,
          ),
          SizedBox(height: sp.sp5),
          ClosCard(
            variant: ClosCardVariant.inset,
            padding: EdgeInsets.all(sp.sp4),
            child: Text(
              earning.nextTierNote,
              style: ClosType.style(
                fontSize: 13,
                weight: FontWeight.w400,
                color: colors.body,
              ).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// The recent-sessions list. Rows open the session's score screen;
/// score text colors by the scoreText ramp.
class _RecentSessionsCard extends StatelessWidget {
  const _RecentSessionsCard({required this.sessions});

  final List<RecentSession> sessions;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    return ClosCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(sp.sp6, sp.sp6, sp.sp6, sp.sp2),
            child: SectionHeader(
              title: 'Recent sessions',
              trailingLabel: 'View all',
              onTrailingTap: () => const ProgressRoute().go(context),
            ),
          ),
          for (var i = 0; i < sessions.length; i++)
            _SessionRow(session: sessions[i], divided: i > 0),
        ],
      ),
    );
  }
}

class _SessionRow extends StatefulWidget {
  const _SessionRow({required this.session, required this.divided});

  final RecentSession session;
  final bool divided;

  @override
  State<_SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends State<_SessionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final session = widget.session;

    return Semantics(
      button: true,
      label: '${session.title}, ${session.methodology}, '
          '${session.timeAgo}, scored ${session.score} percent',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => ScoreRoute(sessionId: session.id).go(context),
          child: ExcludeSemantics(
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding:
                  EdgeInsets.symmetric(horizontal: sp.sp6, vertical: sp.sp3),
              decoration: BoxDecoration(
                color: _hovered ? colors.surface2 : null,
                border: widget.divided
                    ? Border(top: BorderSide(color: colors.border))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      border: Border.all(color: colors.border2),
                      borderRadius: context.closRadius.buttonRadius,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(color: colors.dim2, size: 15),
                      child: const Center(child: SimulationsIcon()),
                    ),
                  ),
                  SizedBox(width: sp.sp3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.closType.titleMedium,
                        ),
                        SizedBox(height: sp.sp1),
                        Text(
                          '${session.methodology} · ${session.timeAgo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClosType.style(
                            fontSize: 12,
                            weight: FontWeight.w400,
                            color: colors.dim1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: sp.sp4),
                  Text(
                    '${session.score}%',
                    style: ClosType.style(
                      fontSize: 14,
                      weight: FontWeight.w700,
                      color: scoreTextColor(colors, session.score),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
