import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../dashboard/domain/dashboard_data.dart';
import '../data/progress_repository.dart';
import '../domain/progress_data.dart';

/// My progress (context/prototype-screens/10-my-progress.png and
/// 11-progress-empty.png): a range toggle in the topbar feeding the
/// repository, so 7D/30D/90D/All genuinely re-queries the overall
/// score, earning trend, stat tiles, skill breakdown, session bars,
/// and history. At session zero the whole body is one centered empty
/// state, never broken charts.
///
/// Accent audit: zero accent-filled elements when populated; the empty
/// state's Start CTA is the view's one accent fill (primary CTA).
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  ProgressRange _range = ProgressRange.d30;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(progressDataProvider(_range));
    final empty = data.value?.totalSessions == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          range: _range,
          // The toggle disappears at session zero: there is nothing
          // to filter yet.
          showRange: !empty,
          onRangeChanged: (range) => setState(() => _range = range),
        ),
        Expanded(
          child: data.when(
            // The fixture load resolves within a frame; no skeleton
            // flash.
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => DataLoadError(
              title: 'Your progress could not load.',
              onRetry: () => ref.invalidate(progressDataProvider(_range)),
            ),
            data: (data) => data.totalSessions == 0
                ? const _EmptyProgress()
                : _ProgressBody(data: data),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.range,
    required this.showRange,
    required this.onRangeChanged,
  });

  final ProgressRange range;
  final bool showRange;
  final ValueChanged<ProgressRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return Container(
      constraints: const BoxConstraints(minHeight: 57),
      padding: EdgeInsets.symmetric(horizontal: sp.sp10, vertical: sp.sp2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'My progress',
              style: ClosType.style(
                fontSize: 15,
                weight: FontWeight.w700,
                color: colors.hi1,
                letterSpacingEm: -0.01,
              ),
            ),
          ),
          if (showRange)
            ClosSegmented(
              segments: [
                for (final range in ProgressRange.values) range.label,
              ],
              selectedIndex: range.index,
              onChanged: (i) => onRangeChanged(ProgressRange.values[i]),
            ),
        ],
      ),
    );
  }
}

/// The session-zero variant: one centered empty state, no charts.
class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.sp.sp10),
        child: EmptyState(
          icon: const ProgressIcon(),
          title: 'Your progress will show up here',
          body: 'Complete a session and this page turns into your '
              'dashboard for tracking skill growth, scores, and session '
              'history over time.',
          action: PrimaryButton(
            label: 'Start a session',
            onPressed: () => const SimulationsRoute().go(context),
          ),
        ),
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.data});

  final ProgressData data;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

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
              LayoutBuilder(
                builder: (context, constraints) {
                  final overall = _OverallScoreCard(
                    overall: data.overall,
                    range: data.range,
                  );
                  final earning = _EarningTrendCard(
                    earning: data.earning,
                    series: data.earningSeries,
                    range: data.range,
                  );
                  if (constraints.maxWidth < 860) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        overall,
                        SizedBox(height: sp.sectionGap),
                        earning,
                      ],
                    );
                  }
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: overall),
                        SizedBox(width: sp.sectionGap),
                        Expanded(child: earning),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: sp.sectionGap),
              _StatsRow(data: data),
              SizedBox(height: sp.sectionGap),
              const SectionHeader(
                title: 'Skill breakdown',
                variant: SectionHeaderVariant.label,
              ),
              SizedBox(height: sp.sp4),
              for (final (i, skill) in data.skills.indexed) ...[
                if (i > 0) SizedBox(height: sp.sp3),
                _SkillTrendCard(skill: skill),
              ],
              SizedBox(height: sp.sectionGap),
              const SectionHeader(
                title: 'Score by session',
                variant: SectionHeaderVariant.label,
              ),
              SizedBox(height: sp.sp4),
              ClosCard(
                child: SizedBox(
                  height: 140,
                  child: ScoreBars(
                    scores: data.sessionScores,
                    semanticLabel:
                        '${data.sessionScores.length} session scores '
                        '${data.range.periodPhrase}, latest '
                        '${data.sessionScores.last} percent',
                  ),
                ),
              ),
              SizedBox(height: sp.sectionGap),
              const SectionHeader(
                title: 'Latest sessions',
                variant: SectionHeaderVariant.label,
              ),
              SizedBox(height: sp.sp4),
              ClosCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, session) in data.history.indexed)
                      SessionRow(
                        title: session.title,
                        methodology: session.methodology,
                        timeAgo: session.timeAgo,
                        score: session.score,
                        divided: i > 0,
                        onTap: () =>
                            ScoreRoute(sessionId: session.id).go(context),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neutral chip with trend text: green up, red down (colored text on a
/// neutral surface, never a tinted wash).
class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.text, required this.positive});

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sp.sp2, vertical: sp.sp1),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border2),
        borderRadius: context.closRadius.buttonRadius,
      ),
      child: Text(
        text,
        style: ClosType.style(
          fontSize: 12,
          weight: FontWeight.w600,
          color: positive ? colors.green : colors.red,
        ),
      ),
    );
  }
}

/// Average session score over the range: threshold-colored ring plus
/// the period summary.
class _OverallScoreCard extends StatelessWidget {
  const _OverallScoreCard({required this.overall, required this.range});

  final ProgressOverall overall;
  final ProgressRange range;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final delta = overall.delta;

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Overall score',
                  variant: SectionHeaderVariant.label,
                ),
              ),
              if (delta != null)
                _TrendChip(
                  text: '${delta > 0 ? '+' : ''}$delta vs last period',
                  positive: delta >= 0,
                ),
            ],
          ),
          SizedBox(height: sp.sp5),
          Row(
            children: [
              ScoreRing(score: overall.score, size: 96, strokeWidth: 5),
              SizedBox(width: sp.sp6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Averaged across ',
                    style: ClosType.style(
                      fontSize: 13,
                      weight: FontWeight.w400,
                      color: colors.body,
                    ).copyWith(height: 1.55),
                    children: [
                      TextSpan(
                        text: '${overall.sessionCount} sessions',
                        style: ClosType.style(
                          fontSize: 13,
                          weight: FontWeight.w700,
                          color: colors.hi2,
                        ),
                      ),
                      TextSpan(
                        text: ' ${range.periodPhrase}. Strongest in '
                            '${overall.strongest}, weakest in '
                            '${overall.weakest}.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The earning figure with its range trend. Figures stay market
/// medians at a skill tier; movement is skill-tier movement, never a
/// personal dollar delta.
class _EarningTrendCard extends StatelessWidget {
  const _EarningTrendCard({
    required this.earning,
    required this.series,
    required this.range,
  });

  final EarningPotential earning;
  final List<double> series;
  final ProgressRange range;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: 'Earning potential',
                  variant: SectionHeaderVariant.label,
                ),
              ),
              // Skill-tier movement is a positive delta: green text on
              // a neutral chip.
              _TrendChip(text: '↑ 1 skill tier', positive: true),
            ],
          ),
          SizedBox(height: sp.sp4),
          Text(
            // The full form of the shared $64K figure.
            '\$${earning.currentK},000',
            style: ClosType.style(
              fontSize: 34,
              weight: FontWeight.w700,
              color: colors.hi1,
              letterSpacingEm: -0.02,
            ),
          ),
          SizedBox(height: sp.sp4),
          SizedBox(
            height: 72,
            width: double.infinity,
            child: SparkLine(
              values: series,
              color: colors.hi2,
              fill: true,
              semanticLabel: 'Earning trend ${range.periodPhrase}',
            ),
          ),
          SizedBox(height: sp.sp4),
          Text(
            'Market median at your current skill tier, against the '
            '${earning.topLabel} ceiling, per published comp data.',
            style: ClosType.style(
              fontSize: 12,
              weight: FontWeight.w400,
              color: colors.dim1,
            ).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data});

  final ProgressData data;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    final tiles = [
      StatTile(
        value: '${data.streakDays} days',
        label: 'Current streak',
        icon: const FlameGlyph(),
      ),
      StatTile(
        value: '${data.overall.sessionCount}',
        label: 'Sessions',
        icon: const SimulationsIcon(),
      ),
      StatTile(
        value: data.practiceLabel,
        label: 'Practice time',
        icon: const ProgressIcon(),
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

/// One skill row: current score and range delta on the left, the
/// range trend line filling the rest. Bars/lines follow the threshold
/// rule; the score text follows the scoreText ramp.
class _SkillTrendCard extends StatelessWidget {
  const _SkillTrendCard({required this.skill});

  final ProgressSkill skill;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;

    return ClosCard(
      padding: EdgeInsets.symmetric(horizontal: sp.sp6, vertical: sp.sp4),
      child: Semantics(
        label: '${skill.label}, ${skill.percent} percent, '
            '${skill.delta >= 0 ? 'up' : 'down'} ${skill.delta.abs()} '
            'this period',
        child: ExcludeSemantics(
          child: Row(
            children: [
              SizedBox(
                width: 190,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.closType.titleMedium,
                    ),
                    SizedBox(height: sp.sp1),
                    Text.rich(
                      TextSpan(
                        text: '${skill.percent}',
                        style: ClosType.style(
                          fontSize: 20,
                          weight: FontWeight.w700,
                          color: scoreTextColor(colors, skill.percent),
                          letterSpacingEm: -0.02,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '  ${skill.delta > 0 ? '+' : ''}${skill.delta}',
                            style: ClosType.style(
                              fontSize: 12,
                              weight: FontWeight.w600,
                              color: skill.delta >= 0
                                  ? colors.green
                                  : colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: sp.sp6),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: SparkLine(values: skill.series),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
