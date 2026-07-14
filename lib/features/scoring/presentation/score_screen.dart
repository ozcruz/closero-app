import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/services/analytics_events.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/session_repository.dart';
import '../domain/session_doc.dart';
import 'scoring_shell.dart';

/// Post-call score (08-score-screen.png): completion badge, the
/// overall ring (number only, no letter grade, threshold colors),
/// scenario title, the write-time delta, the five locked category
/// cards in rubric order, the deterministic stat strip, and Key
/// Moments (Strong, Watch, Missed) deep-linking into the transcript.
///
/// Contract-beats-prototype notes: the prototype crop shows three
/// category cards; the rubric locks five, so all five render. The
/// prototype's exchanges / objections met / missed opens / day streak
/// strip is not in the `stats` schema block (and streaks stay
/// firewalled from score surfaces), so the strip shows schema-backed
/// stats instead.
///
/// Accent audit: the one accent fill is the primary CTA
/// ('Practice this call again'). Rings and bars stay threshold-colored.
class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fire score_viewed once, when a scored (non-aborted) session
    // resolves. Deep-link revisits re-fire; aborted sessions never do
    // (no score, no fake band). The band rides here because the score is
    // server-written and only known once the doc loads.
    ref.listen(sessionViewProvider(sessionId), (previous, next) {
      final view = next.value;
      if (view == null) return;
      final doc = view.doc;
      if (doc.status == SessionStatus.aborted || doc.score == null) return;
      ref.read(analyticsServiceProvider).capture(
        AnalyticsEvents.scoreViewed,
        properties: {
          AnalyticsProps.sessionId: sessionId,
          AnalyticsProps.simType: doc.simType.schemaValue,
          AnalyticsProps.scoreBand: scoreBandLabel(doc.score!.total),
        },
      );
    });

    final view = ref.watch(sessionViewProvider(sessionId));

    return view.when(
      loading: () =>
          const ScoringShell(title: 'Session score', maxWidth: 1160, child: SizedBox.shrink()),
      error: (error, stackTrace) => ScoringShell(
        title: 'Session score',
        maxWidth: 520,
        child: _ScoreMessage(
          title: 'Your score could not load.',
          body: 'Check your connection and try again.',
          action: GhostButton(
            label: 'Try again',
            size: ClosButtonSize.medium,
            onPressed: () => ref.invalidate(sessionViewProvider(sessionId)),
          ),
        ),
      ),
      data: (view) {
        if (view == null) {
          return ScoringShell(
            title: 'Session score',
            maxWidth: 520,
            child: _ScoreMessage(
              title: 'This session could not be found.',
              body: 'It may have been removed, or the link is out of date.',
              action: GhostButton(
                label: 'Back to dashboard',
                size: ClosButtonSize.medium,
                onPressed: () => const DashboardRoute().go(context),
              ),
            ),
          );
        }
        return view.doc.status == SessionStatus.aborted
            ? _AbortedScore(view: view)
            : _ScoreBody(view: view);
      },
    );
  }
}

/// Centered single-message states (load error, unknown id).
class _ScoreMessage extends StatelessWidget {
  const _ScoreMessage({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return Column(
      children: [
        SizedBox(height: sp.sp16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.closType.headlineSmall,
        ),
        SizedBox(height: sp.sp3),
        Text(
          body,
          textAlign: TextAlign.center,
          style: context.closType.bodyMedium,
        ),
        SizedBox(height: sp.sp6),
        action,
      ],
    );
  }
}

/// Honest aborted state: the call dropped, so there is no score object
/// and the session never counts against the cap. No fake partials.
class _AbortedScore extends StatelessWidget {
  const _AbortedScore({required this.view});

  final SessionView view;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return ScoringShell(
      title: 'Session ended early',
      meta: sessionMetaLine(view),
      maxWidth: 520,
      child: Column(
        children: [
          SizedBox(height: sp.sp16),
          Text(
            'This call ended before it could be scored.',
            textAlign: TextAlign.center,
            style: context.closType.headlineSmall,
          ),
          SizedBox(height: sp.sp3),
          Text(
            'The connection dropped mid-session, so there is no score '
            'and it does not count toward your monthly sessions.',
            textAlign: TextAlign.center,
            style: context.closType.bodyMedium.copyWith(height: 1.5),
          ),
          SizedBox(height: sp.sp6),
          Wrap(
            spacing: sp.sp3,
            runSpacing: sp.sp3,
            alignment: WrapAlignment.center,
            children: [
              PrimaryButton(
                label: 'Try the call again',
                onPressed: () => _practiceRoute(view).go(context),
              ),
              GhostButton(
                label: 'Back to dashboard',
                onPressed: () => const DashboardRoute().go(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBody extends StatelessWidget {
  const _ScoreBody({required this.view});

  final SessionView view;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    final doc = view.doc;
    final score = doc.score!;
    final delta = doc.delta;
    final stats = doc.stats;
    final moments = orderedKeyMoments(doc);

    return ScoringShell(
      title: 'Session complete',
      meta: sessionMetaLine(view),
      maxWidth: 1160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClosBadge(label: 'Session complete', dotColor: colors.green),
          ),
          SizedBox(height: sp.sp8),
          Center(
            child: ScoreRing(score: score.total, size: 170, label: 'Overall'),
          ),
          SizedBox(height: sp.sp8),
          Center(
            child: Text(
              view.scenarioTitle,
              textAlign: TextAlign.center,
              style: context.closType.displaySmall,
            ),
          ),
          if (delta != null) ...[
            SizedBox(height: sp.sp3),
            Center(
              child: DeltaPill(
                delta: delta.value,
                sessionNumber: view.sessionNumber,
                unit: 'pts',
                showComparisonLabel: true,
                // The stored write-time basis wins over the
                // session-number rule, so history never re-renders.
                comparisonLabelOverride: deltaBasisLabel(delta.basis),
              ),
            ),
          ],
          SizedBox(height: sp.sp12),
          _CategoryGrid(view: view, score: score),
          if (stats != null) ...[
            SizedBox(height: sp.sp6),
            StatStrip(
              items: [
                StatStripItem(
                  value: formatClock(stats.durationSec),
                  label: 'Duration',
                ),
                StatStripItem(
                  value: '${(stats.talkRatioRep * 100).round()}%',
                  label: 'Your talk time',
                ),
                StatStripItem(
                  value: '${stats.questionsAsked}',
                  label: 'Questions asked',
                ),
                StatStripItem(
                  value: stats.fillerPerMin.toStringAsFixed(1),
                  label: 'Fillers per min',
                ),
                StatStripItem(
                  value: '${stats.longestRepMonologueSec}s',
                  label: 'Longest monologue',
                ),
              ],
            ),
          ],
          if (moments.isNotEmpty) ...[
            SizedBox(height: sp.sp10),
            const SectionHeader(
              title: 'Key moments',
              variant: SectionHeaderVariant.label,
            ),
            SizedBox(height: sp.sp3),
            for (final (i, moment) in moments.indexed) ...[
              if (i > 0) SizedBox(height: sp.sp3),
              _KeyMomentCard(view: view, moment: moment, momentIndex: i),
            ],
          ],
          SizedBox(height: sp.sp10),
          Wrap(
            spacing: sp.sp3,
            runSpacing: sp.sp3,
            alignment: WrapAlignment.center,
            children: [
              PrimaryButton(
                label: 'Practice this call again',
                onPressed: () => _practiceRoute(view).go(context),
              ),
              GhostButton(
                label: 'View full transcript',
                onPressed: () =>
                    ScoreTranscriptRoute(sessionId: view.doc.id).go(context),
              ),
              GhostButton(
                label: 'Back to dashboard',
                onPressed: () => const DashboardRoute().go(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The five locked categories in rubric order, three across on wide
/// layouts, wrapping down to two and one column as the frame narrows.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.view, required this.score});

  final SessionView view;
  final SessionScore score;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 3
            : width >= 560
                ? 2
                : 1;
        final cardWidth = (width - sp.sp4 * (columns - 1)) / columns;

        return Wrap(
          spacing: sp.sp4,
          runSpacing: sp.sp4,
          children: [
            for (final category in scoringCategories)
              SizedBox(
                width: cardWidth,
                child: CategoryScoreCard(
                  label: category.displayName,
                  score: score.categories[category.key] ?? 0,
                  previousScore: view.previousCategories[category.key],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _KeyMomentCard extends StatelessWidget {
  const _KeyMomentCard({
    required this.view,
    required this.moment,
    required this.momentIndex,
  });

  final SessionView view;
  final KeyMoment moment;
  final int momentIndex;

  static const _labels = {
    MomentType.good: 'Strong',
    MomentType.warn: 'Watch',
    MomentType.miss: 'Missed',
  };

  @override
  Widget build(BuildContext context) {
    final doc = view.doc;
    // Fixture text convention: headline, newline, coaching note.
    final lines = moment.text.split('\n');
    final utterance = doc.transcript[moment.utteranceIndex];

    return HintCard(
      kind: momentHintKind(moment.type),
      label: _labels[moment.type]!,
      title: lines.first,
      body: lines.length > 1 ? lines.sublist(1).join(' ') : null,
      timestamp: formatClock(utterance.tsMs ~/ 1000),
      onTap: () => ScoreTranscriptRoute(
        sessionId: doc.id,
        moment: momentIndex,
      ).go(context),
    );
  }
}

/// Topbar meta: sim type, persona, duration.
String sessionMetaLine(SessionView view) {
  final type = switch (view.doc.simType) {
    SimType.coldCall => 'Cold call',
    SimType.video => 'Video call',
  };
  return '$type · ${view.personaName} · '
      '${formatClock(view.doc.durationSec)}';
}

/// The display copy for a stored delta basis; mirrors
/// [DeltaPill.comparisonLabel] under the write-time rule.
String deltaBasisLabel(DeltaBasis basis) => switch (basis) {
      DeltaBasis.lastSession => 'vs last session',
      DeltaBasis.rolling10 => 'vs 10-session avg',
    };

/// Schema moment type to the shared hint kind.
HintKind momentHintKind(MomentType type) => switch (type) {
      MomentType.good => HintKind.good,
      MomentType.warn => HintKind.warn,
      MomentType.miss => HintKind.miss,
    };

AppRoute _practiceRoute(SessionView view) => switch (view.doc.simType) {
      SimType.coldCall => ColdCallSimRoute(scenarioId: view.doc.scenarioId),
      SimType.video => VideoSimRoute(scenarioId: view.doc.scenarioId),
    };
