import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../domain/scenario.dart';

/// The one shared scenario source. The Library grid, the Scenario
/// Preview modal, and the Dashboard hero preview all read from here.
/// Fixture-backed today; the Firestore catalog swaps in behind this
/// same interface (personal bests are server-written, so the client
/// only ever reads).
abstract interface class ScenarioRepository {
  /// The full catalog, both tracks, in display order.
  Future<List<Scenario>> list();

  /// Resolves one scenario, e.g. from the dashboard hero id.
  /// Null when the id is unknown.
  Future<Scenario?> byId(String id);
}

/// Canonical fixtures (context/canonical-mock-data.md: the Simulations
/// grid initials DW, TC, RH, MG, WB, TS, and Sandra Voss as the
/// gatekeeper persona shared with the dashboard and modal).
class FixtureScenarioRepository implements ScenarioRepository {
  const FixtureScenarioRepository();

  @override
  Future<List<Scenario>> list() async => scenarioFixtures;

  @override
  Future<Scenario?> byId(String id) async {
    for (final scenario in scenarioFixtures) {
      if (scenario.id == id) return scenario;
    }
    return null;
  }
}

/// The catalog, B2C first (prototype-screens/04-simulations.png), then
/// the B2B track (locked on free).
const scenarioFixtures = [
  // ── B2C: pick up where you left off ─────────────────────────────
  Scenario(
    id: 'cold-call-skeptical-homeowner',
    track: ScenarioTrack.b2c,
    bucket: ScenarioBucket.pickUp,
    name: 'Denise',
    roleLine: 'Homeowner / Screens the door',
    cardLine: 'Skeptical homeowner, 3rd pitch today',
    synopsis: 'Denise has already heard three pitches today and yours '
        'sounds like the other two. She answers the door with a hand on '
        'the frame and a timer in her head. Your job is to earn the next '
        'minute, not the sale.',
    difficultyBadge: 'Hard',
    difficultyLabel: 'Demanding',
    duration: '~12 min',
    targets: 'Objection handling',
    methodologyTags: ['Straight Line', 'Cold Call', 'B2C'],
    initials: 'DW',
    tint: AvatarArtTint.umber,
    bestScore: 58,
  ),
  Scenario(
    id: 'door-knock-the-coopers',
    track: ScenarioTrack.b2c,
    bucket: ScenarioBucket.pickUp,
    name: 'The Coopers',
    roleLine: 'Married homeowners / Mid-dinner',
    cardLine: 'Just sat down to dinner, door knock',
    synopsis: 'You caught the Coopers at the worst possible moment and '
        'they will tell you so. One of them wants to close the door, the '
        'other is politely curious. Read the room fast and decide who '
        'you are really talking to.',
    difficultyBadge: 'Medium',
    difficultyLabel: 'Moderate',
    duration: '~14 min',
    targets: 'Building rapport',
    methodologyTags: ['Sandler Method', 'Door to door', 'B2C'],
    initials: 'TC',
    tint: AvatarArtTint.moss,
    inProgress: true,
  ),

  // ── B2C: new scenarios ───────────────────────────────────────────
  Scenario(
    id: 'showroom-just-looking-ray',
    track: ScenarioTrack.b2c,
    bucket: ScenarioBucket.fresh,
    name: 'Ray',
    roleLine: 'Showroom browser / Guarding his budget',
    cardLine: '"Just looking," won\'t commit to a number',
    synopsis: 'Ray wandered in on his lunch break and swears he is just '
        'looking. He has a number in his head and no intention of '
        'sharing it. Every direct question about budget gets a shrug, '
        'so you will have to earn it sideways.',
    difficultyBadge: 'Easy',
    difficultyLabel: 'Gentle',
    duration: '~8 min',
    targets: 'Discovery questions',
    methodologyTags: ['7th Level', 'Retail', 'B2C'],
    initials: 'RH',
    tint: AvatarArtTint.moss,
    bestScore: 72,
  ),
  Scenario(
    id: 'phone-quote-shopper-marisol',
    track: ScenarioTrack.b2c,
    bucket: ScenarioBucket.fresh,
    name: 'Marisol',
    roleLine: 'Phone shopper / Three quotes open',
    cardLine: 'Price-shopping three quotes side by side',
    synopsis: 'Marisol has three quotes open in three tabs and reads '
        'yours back to you line by line. She is organized, polite, and '
        'entirely focused on the bottom number. Hold your value without '
        'talking her out of the call.',
    difficultyBadge: 'Hard',
    difficultyLabel: 'Demanding',
    duration: '~16 min',
    targets: 'Closing technique',
    methodologyTags: ['Straight Line', 'Phone sale', 'B2C'],
    initials: 'MG',
    tint: AvatarArtTint.violet,
  ),
  Scenario(
    id: 'warm-lead-wanderer-walter',
    track: ScenarioTrack.b2c,
    bucket: ScenarioBucket.fresh,
    name: 'Walter',
    roleLine: 'Retired homeowner / Loves to chat',
    cardLine: 'Warm but wanders, hard to bring to close',
    synopsis: 'Walter likes you, likes the product, and likes telling '
        'stories about his grandkids. Every time you steer toward a '
        'decision the conversation drifts somewhere warmer. Keep the '
        'rapport and still land the close.',
    difficultyBadge: 'Medium',
    difficultyLabel: 'Moderate',
    duration: '~11 min',
    targets: 'Closing technique',
    methodologyTags: ['Sandler Method', 'In home', 'B2C'],
    initials: 'WB',
    tint: AvatarArtTint.umber,
    bestScore: 81,
  ),
  Scenario(
    id: 'gone-quiet-after-demo-trevor',
    track: ScenarioTrack.b2c,
    bucket: ScenarioBucket.fresh,
    name: 'Trevor',
    roleLine: 'High-ticket buyer / Gone quiet',
    cardLine: 'Ghosted after the demo, won\'t call back',
    synopsis: 'Trevor loved the walkthrough two weeks ago and has '
        'ignored every message since. Today he finally picks up. '
        'Something changed on his side and he is not volunteering what. '
        'Find the real objection without making him defend the silence.',
    difficultyBadge: 'Hard',
    difficultyLabel: 'Demanding',
    duration: '~13 min',
    targets: 'Objection handling',
    methodologyTags: ['7th Level', 'Follow up', 'B2C'],
    initials: 'TS',
    tint: AvatarArtTint.slate,
  ),

  // ── B2B: pick up where you left off ──────────────────────────────
  Scenario(
    id: 'cold-call-saas-gatekeeper',
    track: ScenarioTrack.b2b,
    bucket: ScenarioBucket.pickUp,
    name: 'Sandra',
    roleLine: 'EA / Front desk gatekeeper',
    cardLine: 'Front desk gatekeeper, screens every cold call',
    synopsis: 'Sandra runs the front desk for a 40-person SaaS company '
        'and treats every unscheduled call as a solicitor until proven '
        'otherwise. No warm intro, no context. She wants a name, a '
        'reason, and a reason to believe you, all in under fifteen '
        'seconds.',
    difficultyBadge: 'Medium',
    difficultyLabel: 'Moderate',
    duration: '~12 min',
    targets: 'Objection handling',
    methodologyTags: ['Sandler Method', 'Cold Call', 'B2B SaaS'],
    initials: 'SV',
    tint: AvatarArtTint.slate,
    bestScore: 78,
  ),

  // ── B2B: new scenarios ───────────────────────────────────────────
  Scenario(
    id: 'discovery-roi-first-marcus',
    track: ScenarioTrack.b2b,
    bucket: ScenarioBucket.fresh,
    name: 'Marcus',
    roleLine: 'VP of Sales / Numbers first',
    cardLine: 'Wants ROI proof before a second call',
    synopsis: 'Marcus took the meeting as a favor to a colleague and '
        'opens with "you have ten minutes." He interrupts anything that '
        'sounds like a pitch and perks up at anything that sounds like '
        'a number. Earn the second call with evidence, not enthusiasm.',
    difficultyBadge: 'Hard',
    difficultyLabel: 'Demanding',
    duration: '~15 min',
    targets: 'Discovery questions',
    methodologyTags: ['Challenger', 'Discovery call', 'B2B SaaS'],
    initials: 'MR',
    tint: AvatarArtTint.violet,
  ),
  Scenario(
    id: 'procurement-price-push-priya',
    track: ScenarioTrack.b2b,
    bucket: ScenarioBucket.fresh,
    name: 'Priya',
    roleLine: 'Procurement lead / Final gate',
    cardLine: 'Loves the product, pushing hard on price',
    synopsis: 'The team already said yes; Priya is the last signature. '
        'She opens with a competitor quote and a discount expectation, '
        'and she has done this a hundred times. Protect the number '
        'without losing the deal the team already wants.',
    difficultyBadge: 'Medium',
    difficultyLabel: 'Moderate',
    duration: '~14 min',
    targets: 'Closing technique',
    methodologyTags: ['Sandler Method', 'Negotiation', 'B2B'],
    initials: 'PN',
    tint: AvatarArtTint.moss,
  ),
  Scenario(
    id: 'stalled-champion-devon',
    track: ScenarioTrack.b2b,
    bucket: ScenarioBucket.fresh,
    name: 'Devon',
    roleLine: 'Ops manager / Your champion, stalled',
    cardLine: 'Champion went quiet, deal stuck in committee',
    synopsis: 'Devon championed you for months and now answers in one '
        'line. The deal is parked in a committee he does not control '
        'and he is embarrassed about it. Rebuild his confidence and '
        'give him something he can carry into that room.',
    difficultyBadge: 'Hard',
    difficultyLabel: 'Demanding',
    duration: '~13 min',
    targets: 'Building rapport',
    methodologyTags: ['Challenger', 'Follow up', 'B2B'],
    initials: 'DK',
    tint: AvatarArtTint.umber,
  ),
];

final scenarioRepositoryProvider = Provider<ScenarioRepository>(
  (ref) => const FixtureScenarioRepository(),
);

final scenarioCatalogProvider = FutureProvider<List<Scenario>>(
  (ref) => ref.watch(scenarioRepositoryProvider).list(),
);
