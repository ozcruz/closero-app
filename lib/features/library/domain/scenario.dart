import '../../../core/widgets/widgets.dart';

/// Which library a scenario belongs to. Free tier = B2C; B2B (and
/// Methodologies) are Closer content, rendered locked on free.
enum ScenarioTrack { b2c, b2b }

/// Library grouping. Curated by the catalog, not derived from status:
/// a scenario the rep has touched sits under 'Pick up where you left
/// off'; the rest are 'New scenarios'.
enum ScenarioBucket { pickUp, fresh }

/// One entry in the shared scenario catalog. The Library grid and the
/// Dashboard hero preview both render from this single source; any
/// screen disagreeing with it is a bug.
///
/// Card naming contract: [name] is who you call, [cardLine] compresses
/// who they are plus the tension into one line. Methodology tags live
/// ONLY in the Scenario Preview modal, never on cards.
class Scenario {
  const Scenario({
    required this.id,
    required this.track,
    required this.bucket,
    required this.name,
    required this.roleLine,
    required this.cardLine,
    required this.synopsis,
    required this.difficultyBadge,
    required this.difficultyLabel,
    required this.duration,
    required this.targets,
    required this.methodologyTags,
    required this.initials,
    required this.tint,
    this.bestScore,
    this.inProgress = false,
  });

  /// Stable id, shared with the dashboard hero and onboarding
  /// recommendation fixtures.
  final String id;

  final ScenarioTrack track;
  final ScenarioBucket bucket;

  /// Who you call, e.g. 'Denise' or 'The Coopers'.
  final String name;

  /// Who they are, shown under the name in the modal,
  /// e.g. 'EA / Front desk gatekeeper'.
  final String roleLine;

  /// The card's one line: who they are plus the tension,
  /// e.g. 'Skeptical homeowner, 3rd pitch today'.
  final String cardLine;

  /// The modal paragraph. Observable-behavior copy only.
  final String synopsis;

  /// Card badge copy, e.g. 'Hard'.
  final String difficultyBadge;

  /// Meta-row form, e.g. 'Demanding'.
  final String difficultyLabel;

  /// e.g. '~12 min'.
  final String duration;

  /// The skill this scenario targets, e.g. 'Objection handling'.
  final String targets;

  /// Modal-only tags, e.g. Sandler Method, Cold Call, B2B SaaS.
  final List<String> methodologyTags;

  /// Placeholder initials for the avatar art, e.g. 'DW'.
  final String initials;

  /// Decorative art gradient cast, per persona, never semantic.
  final AvatarArtTint tint;

  /// Server-written personal best; null when never completed.
  /// Completion shows this score or 'Start', never a checkmark.
  final int? bestScore;

  /// Attempted but unfinished: dot on the art, trailing 'Resume'.
  final bool inProgress;

  /// Card status, with the tier gate applied by the caller.
  ScenarioCardStatus status({required bool locked}) {
    if (locked) return ScenarioCardStatus.locked;
    if (inProgress) return ScenarioCardStatus.inProgress;
    if (bestScore != null) return ScenarioCardStatus.personalBest;
    return ScenarioCardStatus.start;
  }
}
