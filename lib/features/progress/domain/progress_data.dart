import '../../dashboard/domain/dashboard_data.dart';

/// The topbar range filter. Every section of the progress screen is
/// derived from the selected range; the repository takes the range so
/// switching it re-queries everything, never just relabels.
enum ProgressRange {
  d7('7D', 'in the last 7 days'),
  d30('30D', 'in the last 30 days'),
  d90('90D', 'in the last 90 days'),
  all('All', 'across all your sessions');

  const ProgressRange(this.label, this.periodPhrase);

  /// Segment copy, e.g. '30D'.
  final String label;

  /// Sentence fragment for the overall-score copy,
  /// e.g. 'in the last 30 days'.
  final String periodPhrase;
}

/// One skill in the range-filtered breakdown. The percent is the
/// current server-written score; delta and series describe movement
/// over the selected range.
class ProgressSkill {
  const ProgressSkill({
    required this.label,
    required this.percent,
    required this.delta,
    required this.series,
  });

  /// e.g. 'Objection handling'.
  final String label;

  /// Current score, 0 to 100.
  final int percent;

  /// Signed change over the range.
  final int delta;

  /// Trend over the range, oldest first, for the row's spark line.
  final List<double> series;
}

/// The overall-score card: average session score over the range.
class ProgressOverall {
  const ProgressOverall({
    required this.score,
    required this.delta,
    required this.sessionCount,
    required this.strongest,
    required this.weakest,
  });

  /// Average session score over the range, 0 to 100.
  final int score;

  /// Change vs the previous period of the same length; null when
  /// there is no previous period to compare (the All range).
  final int? delta;

  /// Sessions inside the range.
  final int sessionCount;

  /// e.g. 'building rapport'.
  final String strongest;

  /// e.g. 'objection handling'.
  final String weakest;
}

/// Everything the progress screen renders for one range, in one load.
class ProgressData {
  const ProgressData({
    required this.range,
    required this.totalSessions,
    required this.overall,
    required this.earning,
    required this.earningSeries,
    required this.streakDays,
    required this.practiceLabel,
    required this.skills,
    required this.sessionScores,
    required this.history,
  });

  final ProgressRange range;

  /// All-time count; zero renders the single centered empty state.
  final int totalSessions;

  final ProgressOverall overall;

  /// Shared with the dashboard fixture; the current-tier figure must
  /// match across screens.
  final EarningPotential earning;

  /// Earning-tier trend over the range for the card's spark line.
  final List<double> earningSeries;

  final int streakDays;

  /// Practice time inside the range, e.g. '3.4 hrs'.
  final String practiceLabel;

  /// Sorted weakest first, like the dashboard breakdown.
  final List<ProgressSkill> skills;

  /// Every session score inside the range, oldest first (the bars).
  final List<int> sessionScores;

  /// Latest sessions inside the range, newest first (capped by the
  /// repository; the section is titled 'Latest sessions' so the cap
  /// never misreads as the full period).
  final List<RecentSession> history;
}
