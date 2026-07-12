import '../../dashboard/domain/dashboard_data.dart';

/// One numbered card in the ranked plan ('Your fastest path up', or
/// 'Get started' at session zero). Every card's CTA routes to the
/// simulations library.
class PathStep {
  const PathStep({
    required this.title,
    required this.line,
    required this.cta,
  });

  /// e.g. 'Close the objection handling gap'.
  final String title;

  /// One supporting sentence, mechanically true of the fixtures.
  final String line;

  /// e.g. 'Find a scenario'.
  final String cta;
}

/// One skill-mastery achievement: progress toward a threshold on one
/// of the five locked scoring categories. Streaks never appear here;
/// they cannot influence a skill score or the income tier.
class SkillMastery {
  const SkillMastery({
    required this.name,
    required this.requirement,
    required this.percent,
    required this.threshold,
    this.unlocksNextTier = false,
  });

  /// Badge name, e.g. 'Rapport Builder'.
  final String name;

  /// e.g. 'Reach 70%+ in building rapport'.
  final String requirement;

  /// Current server-written skill score.
  final int percent;

  /// Unlock threshold, e.g. 70.
  final int threshold;

  /// Marks the one skill whose threshold moves the earning tier.
  final bool unlocksNextTier;

  bool get unlocked => percent >= threshold;
}

/// Badge categories behind the 'More badges' filter.
enum BadgeCategory {
  streaks('Streaks'),
  volume('Volume'),
  scenarios('Scenarios');

  const BadgeCategory(this.label);

  final String label;
}

/// One badge in the 'More badges' grid. Streak rewards stay
/// access-based recognition; no badge copy promises score or income
/// movement.
class AchievementBadge {
  const AchievementBadge({
    required this.name,
    required this.requirement,
    required this.category,
    required this.unlocked,
  });

  final String name;

  /// e.g. 'Complete your first session'.
  final String requirement;

  final BadgeCategory category;
  final bool unlocked;
}

/// Everything the achievements screen renders in one load.
class AchievementsData {
  const AchievementsData({
    required this.streakDays,
    required this.totalSessions,
    required this.earning,
    required this.earningNote,
    required this.milestoneNote,
    required this.pathTitle,
    required this.path,
    required this.mastery,
    required this.badges,
  });

  final int streakDays;
  final int totalSessions;

  /// Shared with the dashboard fixture. Its current-tier figure is
  /// the ONE dollar figure on the whole screen.
  final EarningPotential earning;

  /// The sourced line under the hero figure.
  final String earningNote;

  /// The next-tier milestone, phrased without a dollar figure.
  final String milestoneNote;

  /// 'Your fastest path up', or 'Get started' at session zero.
  final String pathTitle;

  final List<PathStep> path;

  /// Ranked by impact on the earning tier.
  final List<SkillMastery> mastery;

  final List<AchievementBadge> badges;

  int get unlockedCount =>
      mastery.where((m) => m.unlocked).length +
      badges.where((b) => b.unlocked).length;

  int get totalCount => mastery.length + badges.length;
}
