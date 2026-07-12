import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/achievements_repository.dart';
import '../domain/achievements_data.dart';

/// Achievements (context/prototype-screens/13-achievements.png and
/// 14-achievements-empty.png): unlock counter, stat tiles, the
/// earning-path hero, the ranked fastest-path plan, skill mastery,
/// and the filtered badge grid. The hero reuses the dashboard's
/// earning figure and is the ONE dollar figure on the whole screen;
/// every other milestone is phrased as a skill threshold.
///
/// Accent audit: the hero's IncomeTrack gradient is the view's one
/// permitted accent use; every CTA here is a text link.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  /// null = the All segment.
  BadgeCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(achievementsDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(data: data.value),
        Expanded(
          child: data.when(
            // The fixture load resolves within a frame; no skeleton
            // flash.
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your achievements could not load.',
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
                    onPressed: () =>
                        ref.invalidate(achievementsDataProvider),
                  ),
                ],
              ),
            ),
            data: (data) => _AchievementsBody(
              data: data,
              filter: _filter,
              onFilterChanged: (filter) => setState(() => _filter = filter),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.data});

  final AchievementsData? data;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final data = this.data;

    return Container(
      constraints: const BoxConstraints(minHeight: 57),
      padding: EdgeInsets.symmetric(horizontal: sp.sp10, vertical: sp.sp3),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Achievements',
              style: ClosType.style(
                fontSize: 15,
                weight: FontWeight.w700,
                color: colors.hi1,
                letterSpacingEm: -0.01,
              ),
            ),
          ),
          if (data != null)
            ClosBadge(
              label: '${data.unlockedCount} of ${data.totalCount} unlocked',
            ),
        ],
      ),
    );
  }
}

class _AchievementsBody extends StatelessWidget {
  const _AchievementsBody({
    required this.data,
    required this.filter,
    required this.onFilterChanged,
  });

  final AchievementsData data;
  final BadgeCategory? filter;
  final ValueChanged<BadgeCategory?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final badges = filter == null
        ? data.badges
        : data.badges.where((b) => b.category == filter).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(sp.sp10, sp.sp8, sp.sp10, sp.sp10),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.closLayout.siteContainerMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatsRow(data: data),
              SizedBox(height: sp.sectionGap),
              _EarningPathHero(data: data),
              SizedBox(height: sp.sectionGap),
              SectionHeader(
                title: data.pathTitle,
                variant: SectionHeaderVariant.label,
              ),
              SizedBox(height: sp.sp4),
              _PathRow(path: data.path),
              SizedBox(height: sp.sectionGap),
              const SectionHeader(
                title: 'Skill mastery',
                variant: SectionHeaderVariant.label,
                trailingLabel: 'Ranked by impact on your earning potential',
              ),
              SizedBox(height: sp.sp4),
              for (final (i, mastery) in data.mastery.indexed) ...[
                if (i > 0) SizedBox(height: sp.sp3),
                _MasteryRow(mastery: mastery, rank: i + 1),
              ],
              SizedBox(height: sp.sectionGap),
              const SectionHeader(
                title: 'More badges',
                variant: SectionHeaderVariant.label,
              ),
              SizedBox(height: sp.sp4),
              Align(
                alignment: Alignment.centerLeft,
                child: ClosSegmented(
                  segments: [
                    'All',
                    for (final category in BadgeCategory.values)
                      category.label,
                  ],
                  selectedIndex:
                      filter == null ? 0 : filter!.index + 1,
                  onChanged: (i) => onFilterChanged(
                    i == 0 ? null : BadgeCategory.values[i - 1],
                  ),
                ),
              ),
              SizedBox(height: sp.sp4),
              _BadgeGrid(badges: badges),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data});

  final AchievementsData data;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    final tiles = [
      // Session zero matches the prototype: streak and sessions only.
      if (data.totalSessions > 0)
        StatTile(
          value: '${data.unlockedCount} / ${data.totalCount}',
          label: 'Badges unlocked',
          icon: const AchievementsIcon(),
        ),
      StatTile(
        value: '${data.streakDays} days',
        label: 'Current streak',
        icon: const FlameGlyph(),
      ),
      StatTile(
        value: '${data.totalSessions}',
        label: 'Total sessions',
        icon: const SimulationsIcon(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, tile) in tiles.indexed) ...[
                if (i > 0) SizedBox(height: sp.sp3),
                tile,
              ],
            ],
          );
        }
        return Row(
          children: [
            for (final (i, tile) in tiles.indexed) ...[
              if (i > 0) SizedBox(width: sp.sp5),
              Expanded(child: tile),
            ],
          ],
        );
      },
    );
  }
}

/// The earning-path hero. The current-tier figure is the screen's one
/// dollar figure; the track endpoints and the milestone note stay
/// dollar-free.
class _EarningPathHero extends StatelessWidget {
  const _EarningPathHero({required this.data});

  final AchievementsData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Your earning path',
            variant: SectionHeaderVariant.label,
          ),
          SizedBox(height: sp.sp4),
          Text.rich(
            TextSpan(
              text: data.earning.currentLabel,
              style: ClosType.style(
                fontSize: 34,
                weight: FontWeight.w700,
                color: colors.hi1,
                letterSpacingEm: -0.02,
              ),
              children: [
                TextSpan(
                  text: '  market median',
                  style: ClosType.style(
                    fontSize: 13,
                    weight: FontWeight.w400,
                    color: colors.dim1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: sp.sp2),
          Text(
            data.earningNote,
            style: ClosType.style(
              fontSize: 13,
              weight: FontWeight.w400,
              color: colors.body,
            ),
          ),
          SizedBox(height: sp.sp5),
          IncomeTrack(
            progress: data.earning.progress,
            startLabel: 'Entry',
            endLabel: 'Top performer',
          ),
          SizedBox(height: sp.sp3),
          Text(
            data.milestoneNote,
            style: ClosType.style(
              fontSize: 12,
              weight: FontWeight.w400,
              color: colors.dim1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({required this.path});

  final List<PathStep> path;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, step) in path.indexed) ...[
                if (i > 0) SizedBox(height: sp.sp3),
                _PathCard(step: step, number: i + 1),
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, step) in path.indexed) ...[
                if (i > 0) SizedBox(width: sp.sp5),
                Expanded(child: _PathCard(step: step, number: i + 1)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({required this.step, required this.number});

  final PathStep step;
  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: colors.border2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: ClosType.style(
                fontSize: 13,
                weight: FontWeight.w600,
                color: colors.dim1,
              ),
            ),
          ),
          SizedBox(height: sp.sp4),
          Text(step.title, style: context.closType.titleMedium),
          SizedBox(height: sp.headlineToSubtext),
          Text(
            step.line,
            style: context.closType.bodyMedium.copyWith(height: 1.5),
          ),
          SizedBox(height: sp.sp3),
          _TextLink(
            label: step.cta,
            onTap: () => const SimulationsRoute().go(context),
          ),
        ],
      ),
    );
  }
}

/// Arrowed text link on the grayscale ramp, 44px tap target.
class _TextLink extends StatefulWidget {
  const _TextLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<_TextLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;

    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: ExcludeSemantics(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.label} →',
                style: ClosType.style(
                  fontSize: 13,
                  weight: FontWeight.w600,
                  color: _hovered ? colors.hi2 : colors.mid,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MasteryRow extends StatelessWidget {
  const _MasteryRow({required this.mastery, required this.rank});

  final SkillMastery mastery;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final unlocked = mastery.unlocked;

    return ClosCard(
      padding: EdgeInsets.symmetric(horizontal: sp.sp6, vertical: sp.sp4),
      child: Semantics(
        label: '${mastery.name}, ${mastery.requirement}, '
            '${unlocked ? 'unlocked' : '${mastery.percent} of '
                '${mastery.threshold} percent'}',
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.surface2,
                  border: Border.all(color: colors.border2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: unlocked
                    ? IconTheme.merge(
                        data: IconThemeData(color: colors.hi2, size: 14),
                        child: const CheckIcon(),
                      )
                    : Text(
                        '$rank',
                        style: ClosType.style(
                          fontSize: 13,
                          weight: FontWeight.w600,
                          color: colors.dim1,
                        ),
                      ),
              ),
              SizedBox(width: sp.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mastery.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.closType.titleMedium,
                    ),
                    SizedBox(height: sp.sp1),
                    Text(
                      mastery.requirement,
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
              _MasteryProgress(mastery: mastery),
              SizedBox(width: sp.sp5),
              SizedBox(
                width: 132,
                child: unlocked
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Complete status is a solid green dot, per
                          // the no-tinted-chips rule.
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: sp.sp2),
                          Text(
                            'Unlocked',
                            style: ClosType.style(
                              fontSize: 12,
                              weight: FontWeight.w600,
                              color: colors.mid,
                            ),
                          ),
                        ],
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: mastery.unlocksNextTier
                            ? const ClosBadge(label: 'Unlocks next tier')
                            : Text(
                                '${mastery.percent} / ${mastery.threshold}',
                                style: ClosType.style(
                                  fontSize: 12,
                                  weight: FontWeight.w600,
                                  color: colors.dim1,
                                ),
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

/// Percent-toward-threshold readout with a small threshold-colored
/// bar (never accent).
class _MasteryProgress extends StatelessWidget {
  const _MasteryProgress({required this.mastery});

  final SkillMastery mastery;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: '${mastery.percent}%',
            style: ClosType.style(
              fontSize: 13,
              weight: FontWeight.w700,
              color: colors.hi1,
            ),
            children: [
              TextSpan(
                text: ' of ${mastery.threshold}%',
                style: ClosType.style(
                  fontSize: 11,
                  weight: FontWeight.w400,
                  color: colors.dim1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: sp.sp2),
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.closRadius.full),
            child: SizedBox(
              height: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: colors.border2),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        (mastery.percent / mastery.threshold).clamp(0.0, 1.0),
                    child: ColoredBox(
                      color: scoreThresholdColor(colors, mastery.percent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges});

  final List<AchievementBadge> badges;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        final rows = <Widget>[];
        for (var start = 0; start < badges.length; start += columns) {
          if (start > 0) rows.add(SizedBox(height: sp.sp3));
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = start; i < start + columns; i++) ...[
                  if (i > start) SizedBox(width: sp.sp5),
                  Expanded(
                    child: i < badges.length
                        ? _BadgeCard(badge: badges[i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClosCard(
      padding: EdgeInsets.symmetric(horizontal: sp.sp6, vertical: sp.sp4),
      child: Semantics(
        label: '${badge.name}, ${badge.requirement}, '
            '${badge.unlocked ? 'unlocked' : 'locked'}',
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.surface2,
                  border: Border.all(color: colors.border2),
                  shape: BoxShape.circle,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(
                    color: badge.unlocked ? colors.hi2 : colors.dim2,
                    size: 14,
                  ),
                  child: Center(
                    child: badge.unlocked
                        ? const CheckIcon()
                        : const LockIcon(),
                  ),
                ),
              ),
              SizedBox(width: sp.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      badge.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.closType.titleMedium,
                    ),
                    SizedBox(height: sp.sp1),
                    Text(
                      badge.requirement,
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
              if (badge.unlocked) ...[
                SizedBox(width: sp.sp3),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
