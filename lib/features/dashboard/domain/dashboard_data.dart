import '../../../core/widgets/widgets.dart';

/// One skill row on the dashboard breakdown. Percentages are
/// server-computed scores; the client only displays them.
class SkillScore {
  const SkillScore({required this.label, required this.percent});

  /// e.g. 'Objection handling'.
  final String label;

  /// 0 to 100.
  final int percent;
}

/// Earning potential figures. All copy stays market medians/ranges at a
/// skill tier, sourced "per published comp data"; movement is skill-tier
/// movement, never a personal dollar delta.
class EarningPotential {
  const EarningPotential({
    required this.currentK,
    required this.entryK,
    required this.topK,
    required this.tierDelta,
    required this.nextTierNote,
  });

  /// Market median at the current skill tier, in $K.
  final int currentK;

  /// Bottom of the published range, in $K.
  final int entryK;

  /// Top of the published range, in $K.
  final int topK;

  /// Skill-tier movement, e.g. '1 skill tier this quarter'.
  final String tierDelta;

  /// The next-tier range note, sourced per published comp data.
  final String nextTierNote;

  /// Position of the current figure along the market range.
  double get progress =>
      ((currentK - entryK) / (topK - entryK)).clamp(0.0, 1.0);

  String get currentLabel => '\$${currentK}K';
  String get entryLabel => '\$${entryK}K entry';
  String get topLabel => '\$${topK}K top performer';
}

/// A completed session in the recent list. Scores are server-written;
/// the client never computes one.
class RecentSession {
  const RecentSession({
    required this.id,
    required this.title,
    required this.methodology,
    required this.timeAgo,
    required this.score,
  });

  final String id;

  /// e.g. 'Inbound Demo, Hesitant Buyer'.
  final String title;

  /// e.g. 'Sandler'.
  final String methodology;

  /// e.g. '2h ago'.
  final String timeAgo;

  /// 0 to 100.
  final int score;
}

/// The next-session hero. Pre-loaded by onboarding so it is never
/// empty at session zero.
class FeaturedScenario {
  const FeaturedScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.personaLine,
    required this.initials,
    required this.tint,
    required this.duration,
    required this.targets,
    required this.difficultyLabel,
    required this.difficulty,
    this.difficultyMax = 5,
  });

  /// Stable scenario id, shared with the onboarding fixtures and the
  /// future library catalog.
  final String id;

  /// e.g. 'Cold Call, SaaS Gatekeeper'.
  final String title;

  /// Two or three sentences on who they are and the tension.
  final String description;

  /// Hero tags, e.g. Sandler Method, Cold Call, B2B SaaS.
  final List<String> tags;

  /// e.g. 'Sandra, EA'.
  final String personaLine;

  /// Placeholder initials for the avatar art, e.g. 'SV'.
  final String initials;

  /// Decorative art gradient cast, never semantic.
  final AvatarArtTint tint;

  /// e.g. '~12 min'.
  final String duration;

  /// The skill this scenario targets, e.g. 'Objection handling'.
  final String targets;

  /// e.g. 'Moderate'.
  final String difficultyLabel;

  /// Filled dots out of [difficultyMax].
  final int difficulty;
  final int difficultyMax;
}

/// Everything the dashboard renders in one load.
class DashboardData {
  const DashboardData({
    required this.streakDays,
    required this.featured,
    required this.skills,
    required this.earning,
    required this.recentSessions,
  });

  final int streakDays;
  final FeaturedScenario featured;

  /// Sorted weakest first (the repository contract).
  final List<SkillScore> skills;

  final EarningPotential earning;
  final List<RecentSession> recentSessions;
}
