import '../../../core/widgets/widgets.dart';
import 'onboarding_answers.dart';

/// A scenario the reveal step pre-loads for the Dashboard hero, so the
/// hero is never empty at session zero. Fixture content until the
/// library ships real scenario data; the ids are stable so the
/// Dashboard and Library can resolve them later.
class RecommendedScenario {
  const RecommendedScenario({
    required this.id,
    required this.personaName,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.initials,
    required this.tint,
  });

  final String id;

  /// e.g. 'Sandra'.
  final String personaName;

  /// One line: who they are, the tension.
  final String description;

  /// e.g. '~12 min'.
  final String duration;

  /// Badge copy, e.g. 'Medium'.
  final String difficulty;

  final String initials;
  final AvatarArtTint tint;
}

/// The canonical gatekeeper scenario (canonical-mock-data.md): the
/// business-track recommendation.
const gatekeeperScenario = RecommendedScenario(
  id: 'cold-call-saas-gatekeeper',
  personaName: 'Sandra',
  description: 'EA and gatekeeper, screens every cold call',
  duration: '~12 min',
  difficulty: 'Medium',
  initials: 'SV',
  tint: AvatarArtTint.slate,
);

/// The consumer-track recommendation.
const homeownerScenario = RecommendedScenario(
  id: 'cold-call-skeptical-homeowner',
  personaName: 'Denise',
  description: 'Skeptical homeowner, 3rd pitch today',
  duration: '~10 min',
  difficulty: 'Medium',
  initials: 'DW',
  tint: AvatarArtTint.umber,
);

/// Picks the first scenario from the answers. Track decides the
/// persona for now; the focus area is stored alongside so a richer
/// catalog can use it once the library has real content.
RecommendedScenario recommendScenario(OnboardingAnswers answers) =>
    switch (answers.track) {
      SellTrack.business => gatekeeperScenario,
      SellTrack.consumer => homeownerScenario,
    };

/// Resolves a stored id back to its fixture (e.g. for the Dashboard
/// hero at session zero). Null when the id is unknown.
RecommendedScenario? recommendedScenarioById(String? id) => switch (id) {
      'cold-call-saas-gatekeeper' => gatekeeperScenario,
      'cold-call-skeptical-homeowner' => homeownerScenario,
      _ => null,
    };
