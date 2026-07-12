import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/domain/dashboard_data.dart';
import '../domain/achievements_data.dart';

/// Read side of the achievements screen. Fixture-backed today; badge
/// unlocks and skill scores are server-written, so the Firestore
/// implementation swaps in behind this interface and the client only
/// ever displays.
abstract interface class AchievementsRepository {
  Future<AchievementsData> load();
}

/// Canonical mock fixtures (context/canonical-mock-data.md): 9-day
/// streak, 47 sessions, the canonical skill percents, and the shared
/// $64K earning figure. 7 of 16 unlocked falls out of the fixtures
/// below, never a hardcoded counter.
class FixtureAchievementsRepository implements AchievementsRepository {
  const FixtureAchievementsRepository({this.empty = false});

  /// Serves the session-zero variant (14-achievements-empty.png).
  final bool empty;

  @override
  Future<AchievementsData> load() async =>
      empty ? emptyAchievementsData : achievementsFixture;
}

/// The populated sheet. Mastery percents are the canonical skill
/// breakdown; badge unlocks follow mechanically from 47 sessions, a
/// 9-day streak, and an 84 personal best.
final achievementsFixture = AchievementsData(
  streakDays: 9,
  totalSessions: 47,
  earning: earningFixture,
  earningNote:
      'Market median at your current skill tier, per published comp data.',
  milestoneNote: 'Next tier at objection handling 70%+.',
  pathTitle: 'Your fastest path up',
  path: const [
    PathStep(
      title: 'Close the objection handling gap',
      line: '38% to 70% unlocks the next skill tier.',
      cta: 'Find a scenario',
    ),
    PathStep(
      title: 'Push discovery past 70%',
      line: 'Discovery sits at 54%, only 16 points out.',
      cta: 'Find a scenario',
    ),
    PathStep(
      title: 'Protect your streak',
      line: '9 of 30 days. Consistency compounds.',
      cta: 'Practice today',
    ),
  ],
  mastery: masteryFor(skillPercents),
  badges: const [
    AchievementBadge(
      name: 'Three in a row',
      requirement: 'Practice 3 days in a row',
      category: BadgeCategory.streaks,
      unlocked: true,
    ),
    AchievementBadge(
      name: 'Full week',
      requirement: 'Practice 7 days in a row',
      category: BadgeCategory.streaks,
      unlocked: true,
    ),
    AchievementBadge(
      name: 'Two weeks straight',
      requirement: 'Practice 14 days in a row',
      category: BadgeCategory.streaks,
      unlocked: false,
    ),
    AchievementBadge(
      name: 'Thirty days',
      requirement: 'Practice 30 days in a row',
      category: BadgeCategory.streaks,
      unlocked: false,
    ),
    AchievementBadge(
      name: 'First rep',
      requirement: 'Complete your first session',
      category: BadgeCategory.volume,
      unlocked: true,
    ),
    AchievementBadge(
      name: 'Ten calls in',
      requirement: 'Complete 10 sessions',
      category: BadgeCategory.volume,
      unlocked: true,
    ),
    AchievementBadge(
      name: 'Quarter century',
      requirement: 'Complete 25 sessions',
      category: BadgeCategory.volume,
      unlocked: true,
    ),
    AchievementBadge(
      name: 'Fifty sessions',
      requirement: 'Complete 50 sessions',
      category: BadgeCategory.volume,
      unlocked: false,
    ),
    AchievementBadge(
      name: 'Both tracks',
      requirement: 'Complete a B2C and a B2B scenario',
      category: BadgeCategory.scenarios,
      unlocked: false,
    ),
    AchievementBadge(
      name: 'Five personas',
      requirement: 'Complete 5 different scenarios',
      category: BadgeCategory.scenarios,
      unlocked: false,
    ),
    AchievementBadge(
      name: 'Top form',
      requirement: 'Score 85 or higher in any session',
      category: BadgeCategory.scenarios,
      unlocked: false,
    ),
  ],
);

/// The session-zero sheet: same structure, everything at its starting
/// point, 'Get started' plan.
final emptyAchievementsData = AchievementsData(
  streakDays: 0,
  totalSessions: 0,
  earning: emptyEarningFixture,
  earningNote: 'Your starting point. This climbs as you practice.',
  milestoneNote: 'Next tier at objection handling 70%+.',
  pathTitle: 'Get started',
  path: const [
    PathStep(
      title: 'Complete your first session',
      line: 'Every stat on this page starts here.',
      cta: 'Start a session',
    ),
    PathStep(
      title: 'Try both B2B and B2C scenarios',
      line: 'See which side of selling suits you.',
      cta: 'Browse the library',
    ),
    PathStep(
      title: 'Start a streak',
      line: 'Consistency compounds faster than any one great call.',
      cta: 'Practice today',
    ),
  ],
  mastery: masteryFor(const {
    'objections': 0,
    'discovery': 0,
    'closing': 0,
    'rapport': 0,
    'tonality': 0,
  }),
  badges: [
    for (final badge in achievementsFixture.badges)
      AchievementBadge(
        name: badge.name,
        requirement: badge.requirement,
        category: badge.category,
        unlocked: false,
      ),
  ],
);

/// A brand-new rep's earning hero: the entry figure, before any
/// sessions move it.
final emptyEarningFixture = EarningPotential(
  currentK: earningFixture.entryK,
  entryK: earningFixture.entryK,
  topK: earningFixture.topK,
  tierDelta: earningFixture.tierDelta,
  nextTierNote: earningFixture.nextTierNote,
);

/// Canonical current percents by scoring-contract key.
const skillPercents = {
  'objections': 38,
  'discovery': 54,
  'closing': 46,
  'rapport': 71,
  'tonality': 63,
};

/// The five mastery rows, one per locked scoring category, ranked by
/// impact on the earning tier: the tier-gating gap first, then by
/// distance to the unlock threshold.
List<SkillMastery> masteryFor(Map<String, int> percents) => [
      SkillMastery(
        name: 'Objection Handler',
        requirement: 'Reach 70%+ in objection handling',
        percent: percents['objections']!,
        threshold: 70,
        unlocksNextTier: true,
      ),
      SkillMastery(
        name: 'Sharp Discovery',
        requirement: 'Reach 70%+ in discovery questions',
        percent: percents['discovery']!,
        threshold: 70,
      ),
      SkillMastery(
        name: 'Clean Closer',
        requirement: 'Reach 70%+ in closing technique',
        percent: percents['closing']!,
        threshold: 70,
      ),
      SkillMastery(
        name: 'Rapport Builder',
        requirement: 'Reach 70%+ in building rapport',
        percent: percents['rapport']!,
        threshold: 70,
      ),
      SkillMastery(
        name: 'Smooth Talker',
        requirement: 'Reach 60%+ in tonality and pacing',
        percent: percents['tonality']!,
        threshold: 60,
      ),
    ];

final achievementsRepositoryProvider = Provider<AchievementsRepository>(
  (ref) => const FixtureAchievementsRepository(),
);

final achievementsDataProvider = FutureProvider<AchievementsData>(
  (ref) => ref.watch(achievementsRepositoryProvider).load(),
);
