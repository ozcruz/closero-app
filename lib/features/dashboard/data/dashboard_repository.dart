import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../../onboarding/data/onboarding_store.dart';
import '../domain/dashboard_data.dart';

/// Read side of the dashboard. Fixture-backed today; the Firestore
/// implementation swaps in behind this same interface (session scores,
/// skills, and streaks are all server-written, so the client only ever
/// reads).
abstract interface class DashboardRepository {
  /// Loads everything the dashboard renders. Skills come back sorted
  /// weakest first.
  Future<DashboardData> load();
}

/// Canonical mock fixtures (context/canonical-mock-data.md, the Sandra
/// Voss sheet). Any screen disagreeing with these values is a bug.
class FixtureDashboardRepository implements DashboardRepository {
  const FixtureDashboardRepository(this._onboardingStore);

  /// The hero source at session zero: onboarding saves a recommended
  /// scenario id so the hero is never empty.
  final OnboardingStore _onboardingStore;

  @override
  Future<DashboardData> load() async {
    final scenarioId = await _onboardingStore.recommendedScenarioId();
    return DashboardData(
      streakDays: 9,
      featured: featuredScenarioById(scenarioId) ?? gatekeeperFeatured,
      skills: [...skillFixtures]
        ..sort((a, b) => a.percent.compareTo(b.percent)),
      earning: earningFixture,
      recentSessions: recentSessionFixtures,
    );
  }
}

/// Canonical skill breakdown, in sheet order; the repository sorts
/// weakest first before handing it out.
const skillFixtures = [
  SkillScore(label: 'Objection handling', percent: 38),
  SkillScore(label: 'Discovery questions', percent: 54),
  SkillScore(label: 'Building rapport', percent: 71),
  SkillScore(label: 'Closing technique', percent: 46),
  SkillScore(label: 'Tonality and pacing', percent: 63),
];

const earningFixture = EarningPotential(
  currentK: 64,
  entryK: 40,
  topK: 150,
  tierDelta: '1 skill tier this quarter',
  nextTierNote: 'Improve objection handling to unlock the next tier. '
      'Reps at 60%+ average \$85 to 95K in your target market, '
      'per published comp data.',
);

const recentSessionFixtures = [
  RecentSession(
    id: 'inbound-demo-hesitant-buyer',
    title: 'Inbound Demo, Hesitant Buyer',
    methodology: 'Sandler',
    timeAgo: '2h ago',
    score: 84,
  ),
  RecentSession(
    id: 'cold-call-price-objection',
    title: 'Cold Call, Price Objection',
    methodology: '7th Level',
    timeAgo: 'Yesterday',
    score: 61,
  ),
  RecentSession(
    id: 'follow-up-deal-going-cold',
    title: 'Follow-Up, Deal Going Cold',
    methodology: 'Straight Line',
    timeAgo: '2d ago',
    score: 77,
  ),
];

/// The canonical gatekeeper hero (business track and the default).
const gatekeeperFeatured = FeaturedScenario(
  id: 'cold-call-saas-gatekeeper',
  title: 'Cold Call, SaaS Gatekeeper',
  description: 'Your weakest skill right now is getting past gatekeepers. '
      'This scenario puts you in a cold call where the assistant is '
      'screening you hard. No warm intro, no context, just you and the '
      'dial tone.',
  tags: ['Sandler Method', 'Cold Call', 'B2B SaaS'],
  personaLine: 'Sandra, EA',
  initials: 'SV',
  tint: AvatarArtTint.slate,
  duration: '~12 min',
  targets: 'Objection handling',
  difficultyLabel: 'Moderate',
  difficulty: 3,
);

/// The consumer-track hero, matching the onboarding recommendation.
const homeownerFeatured = FeaturedScenario(
  id: 'cold-call-skeptical-homeowner',
  title: 'Cold Call, Skeptical Homeowner',
  description: 'Denise has already heard three pitches today. This '
      'scenario drops you into a cold call where patience is thin and '
      'trust is not given. Your job is to earn the next minute.',
  tags: ['Straight Line', 'Cold Call', 'B2C'],
  personaLine: 'Denise, homeowner',
  initials: 'DW',
  tint: AvatarArtTint.umber,
  duration: '~12 min',
  targets: 'Objection handling',
  difficultyLabel: 'Demanding',
  difficulty: 4,
);

/// Resolves the onboarding-saved scenario id to its hero fixture.
/// Null when the id is unknown (callers fall back to the canonical
/// gatekeeper).
FeaturedScenario? featuredScenarioById(String? id) => switch (id) {
      'cold-call-saas-gatekeeper' => gatekeeperFeatured,
      'cold-call-skeptical-homeowner' => homeownerFeatured,
      _ => null,
    };

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => FixtureDashboardRepository(ref.watch(onboardingStoreProvider)),
);

final dashboardDataProvider = FutureProvider<DashboardData>(
  (ref) => ref.watch(dashboardRepositoryProvider).load(),
);

/// The clock behind the topbar greeting, overridable in tests so
/// goldens are deterministic.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
