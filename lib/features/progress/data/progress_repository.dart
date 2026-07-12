import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/domain/dashboard_data.dart';
import '../domain/progress_data.dart';

/// Read side of the progress screen. The range is a repository
/// parameter, not a screen-side relabel: every section of
/// [ProgressData] is derived from it, so switching the topbar filter
/// re-queries everything. Fixture-backed today; the Firestore
/// implementation (server-written session scores and aggregates)
/// swaps in behind this interface.
abstract interface class ProgressRepository {
  Future<ProgressData> load(ProgressRange range);
}

/// Canonical mock fixtures (context/canonical-mock-data.md, the Sandra
/// Voss sheet): 47 sessions and 11.2 hrs all time, 9-day streak, the
/// canonical skill percents, and the shared $64K earning figure.
class FixtureProgressRepository implements ProgressRepository {
  const FixtureProgressRepository({this.empty = false});

  /// Serves the session-zero variant (one centered empty state).
  final bool empty;

  @override
  Future<ProgressData> load(ProgressRange range) async {
    if (empty) return emptyProgressData(range);

    final sessions = _sessionsInRange[range]!;
    return ProgressData(
      range: range,
      totalSessions: 47,
      overall: ProgressOverall(
        score: _overallScore[range]!,
        delta: range == ProgressRange.all ? null : _overallDelta[range]!,
        sessionCount: sessions,
        strongest: 'building rapport',
        weakest: 'objection handling',
      ),
      earning: earningFixture,
      earningSeries: trendSeries(
        end: earningFixture.currentK.toDouble(),
        delta: _earningDeltaK[range]!,
        points: 16,
        seed: 3,
      ),
      streakDays: 9,
      practiceLabel: _practiceLabel[range]!,
      skills: [
        for (final (i, skill) in skillFixtures.indexed)
          ProgressSkill(
            label: skill.label,
            percent: skill.percent,
            delta: _skillDeltas[range]![i],
            series: trendSeries(
              end: skill.percent.toDouble(),
              delta: _skillDeltas[range]![i].toDouble(),
              points: 14,
              seed: i + 1,
            ),
          ),
      ]..sort((a, b) => a.percent.compareTo(b.percent)),
      sessionScores: sessionScoreSeries(sessions),
      history: historyFixtures.take(sessions < 6 ? sessions : 6).toList(),
    );
  }
}

/// The session-zero payload: every section empty, one honest state.
ProgressData emptyProgressData(ProgressRange range) => ProgressData(
      range: range,
      totalSessions: 0,
      overall: const ProgressOverall(
        score: 0,
        delta: null,
        sessionCount: 0,
        strongest: '',
        weakest: '',
      ),
      earning: earningFixture,
      earningSeries: const [],
      streakDays: 0,
      practiceLabel: '0 hrs',
      skills: const [],
      sessionScores: const [],
      history: const [],
    );

const _sessionsInRange = {
  ProgressRange.d7: 4,
  ProgressRange.d30: 14,
  ProgressRange.d90: 31,
  ProgressRange.all: 47,
};

const _practiceLabel = {
  ProgressRange.d7: '1.1 hrs',
  ProgressRange.d30: '3.4 hrs',
  ProgressRange.d90: '7.6 hrs',
  ProgressRange.all: '11.2 hrs',
};

const _overallScore = {
  ProgressRange.d7: 78,
  ProgressRange.d30: 76,
  ProgressRange.d90: 72,
  ProgressRange.all: 69,
};

const _overallDelta = {
  ProgressRange.d7: 4,
  ProgressRange.d30: 6,
  ProgressRange.d90: 5,
};

/// Skill deltas over the range, in [skillFixtures] sheet order
/// (objection handling, discovery, rapport, closing, tonality).
const _skillDeltas = {
  ProgressRange.d7: [2, 1, 1, 1, -1],
  ProgressRange.d30: [5, 3, 4, 2, -2],
  ProgressRange.d90: [9, 6, 7, 5, 3],
  ProgressRange.all: [21, 15, 18, 12, 9],
};

/// Skill-tier movement of the earning figure over the range, in $K.
const _earningDeltaK = {
  ProgressRange.d7: 1,
  ProgressRange.d30: 3,
  ProgressRange.d90: 6,
  ProgressRange.all: 24,
};

/// Latest sessions, newest first. The top three are the canonical
/// dashboard recents (single source); older rows extend the fixture
/// back through the wider ranges.
final historyFixtures = [
  ...recentSessionFixtures,
  const RecentSession(
    id: 'cold-call-saas-gatekeeper',
    title: 'Cold Call, SaaS Gatekeeper',
    methodology: 'Sandler',
    timeAgo: '4d ago',
    score: 58,
  ),
  const RecentSession(
    id: 'discovery-call-new-territory',
    title: 'Discovery Call, New Territory',
    methodology: 'SPIN',
    timeAgo: '1w ago',
    score: 66,
  ),
  const RecentSession(
    id: 'renewal-unhappy-customer',
    title: 'Renewal, Unhappy Customer',
    methodology: 'Challenger',
    timeAgo: '2w ago',
    score: 71,
  ),
];

/// Deterministic trend for spark lines: a linear climb from
/// end minus delta to end, with a small stable wiggle so the line
/// reads as real data. Pure, so goldens never flake.
List<double> trendSeries({
  required double end,
  required num delta,
  required int points,
  required int seed,
}) =>
    List.generate(points, (i) {
      final t = i / (points - 1);
      final wiggle = (((i + seed) * 7) % 5 - 2) * 0.35;
      return end - delta * (1 - t) + wiggle * (1 - t);
    });

/// Deterministic per-session scores, oldest first, ending on the
/// canonical recent three (77, 61, then 84 most recent).
List<int> sessionScoreSeries(int count) {
  final scores = List.generate(count, (i) {
    final climb = 20 * i ~/ (count < 2 ? 1 : count - 1);
    return (42 + climb + ((i * 13) % 17)).clamp(0, 95);
  });
  const tail = [77, 61, 84];
  final n = tail.length < count ? tail.length : count;
  for (var i = 0; i < n; i++) {
    scores[count - n + i] = tail[tail.length - n + i];
  }
  return scores;
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => const FixtureProgressRepository(),
);

final progressDataProvider =
    FutureProvider.family<ProgressData, ProgressRange>(
  (ref, range) => ref.watch(progressRepositoryProvider).load(range),
);
