import 'package:closero_app/features/dashboard/data/dashboard_repository.dart';
import 'package:closero_app/features/progress/data/progress_repository.dart';
import 'package:closero_app/features/progress/domain/progress_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repository = FixtureProgressRepository();

  test('every range re-derives every section from the range', () async {
    final byRange = {
      for (final range in ProgressRange.values)
        range: await repository.load(range),
    };

    // Sessions in range grow with the range and drive the bars and
    // the overall-card copy together.
    final counts = [
      for (final range in ProgressRange.values)
        byRange[range]!.overall.sessionCount,
    ];
    expect(counts, [4, 14, 31, 47]);
    for (final data in byRange.values) {
      expect(data.sessionScores.length, data.overall.sessionCount);
      expect(data.history.length,
          data.overall.sessionCount < 6 ? data.overall.sessionCount : 6);
    }

    // Range-scoped sections genuinely differ between ranges.
    final d7 = byRange[ProgressRange.d7]!;
    final d30 = byRange[ProgressRange.d30]!;
    expect(d7.overall.score, isNot(d30.overall.score));
    expect(d7.practiceLabel, isNot(d30.practiceLabel));
    expect(d7.skills.first.delta, isNot(d30.skills.first.delta));
    expect(d7.earningSeries, isNot(d30.earningSeries));

    // The All range has no previous period to compare against.
    expect(byRange[ProgressRange.all]!.overall.delta, isNull);
    expect(byRange[ProgressRange.d30]!.overall.delta, 6);
  });

  test('canonical sheet: totals, skills weakest first, shared earning',
      () async {
    final data = await repository.load(ProgressRange.all);

    expect(data.totalSessions, 47);
    expect(data.streakDays, 9);
    expect(data.practiceLabel, '11.2 hrs');

    // The canonical five percents, sorted weakest first like the
    // dashboard breakdown.
    expect(
      [for (final skill in data.skills) skill.percent],
      [38, 46, 54, 63, 71],
    );
    expect(data.skills.first.label, 'Objection handling');

    // Single source for the earning figure.
    expect(data.earning.currentK, earningFixture.currentK);

    // Bars end on the canonical recent scores, most recent last.
    expect(data.sessionScores.sublist(data.sessionScores.length - 3),
        [77, 61, 84]);

    // History leads with the canonical dashboard recents.
    expect(data.history.first.title, 'Inbound Demo, Hesitant Buyer');
    expect(data.history.first.score, 84);
  });

  test('session zero serves the empty payload, never broken sections',
      () async {
    const empty = FixtureProgressRepository(empty: true);
    final data = await empty.load(ProgressRange.d30);

    expect(data.totalSessions, 0);
    expect(data.skills, isEmpty);
    expect(data.sessionScores, isEmpty);
    expect(data.history, isEmpty);
  });

  test('spark series are deterministic and end on the current value',
      () {
    final a = trendSeries(end: 64, delta: 3, points: 16, seed: 3);
    final b = trendSeries(end: 64, delta: 3, points: 16, seed: 3);
    expect(a, b);
    expect(a.last, 64);
    expect(sessionScoreSeries(14), sessionScoreSeries(14));
  });
}
