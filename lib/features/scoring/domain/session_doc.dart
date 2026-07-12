/// Client-side mirror of the server-written `sessions/{id}` document
/// (context/scoring-rubric.md, the binding scoring contract). The app
/// only ever displays these values; it never computes-and-saves a
/// score. Field and key names match the schema exactly so the
/// Firestore mapper is a straight decode.
library;

/// One score category from the locked rubric. The keys are the schema
/// and never change; display names were locked 2026-07-10 to match the
/// prototype's Skill Breakdown.
class ScoringCategory {
  const ScoringCategory({
    required this.key,
    required this.displayName,
    required this.weight,
  });

  final String key;
  final String displayName;
  final double weight;
}

/// The five locked categories, in rubric (weight) order. Screens
/// take display names from here, never invent them.
const scoringCategories = [
  ScoringCategory(
    key: 'objections',
    displayName: 'Objection handling',
    weight: 0.25,
  ),
  ScoringCategory(
    key: 'discovery',
    displayName: 'Discovery questions',
    weight: 0.25,
  ),
  ScoringCategory(
    key: 'closing',
    displayName: 'Closing technique',
    weight: 0.20,
  ),
  ScoringCategory(
    key: 'rapport',
    displayName: 'Building rapport',
    weight: 0.15,
  ),
  ScoringCategory(
    key: 'tonality',
    displayName: 'Tonality and pacing',
    weight: 0.15,
  ),
];

/// The rubric composite: weighted total rounded to an integer. Used by
/// tests to prove fixtures agree with their stored total; the real
/// number is always server-written.
int rubricComposite(Map<String, int> categories) {
  var total = 0.0;
  for (final category in scoringCategories) {
    total += category.weight * (categories[category.key] ?? 0);
  }
  return total.round();
}

enum SimType {
  coldCall('cold_call'),
  video('video');

  const SimType(this.schemaValue);

  final String schemaValue;
}

enum SessionStatus {
  complete('complete'),
  aborted('aborted');

  const SessionStatus(this.schemaValue);

  final String schemaValue;
}

/// Hint / key-moment / annotation kind, shared by the three places the
/// schema uses the same string set.
enum MomentType {
  good('good'),
  warn('warn'),
  miss('miss');

  const MomentType(this.schemaValue);

  final String schemaValue;
}

enum DeltaBasis {
  lastSession('last_session'),
  rolling10('rolling_10');

  const DeltaBasis(this.schemaValue);

  final String schemaValue;
}

/// `score` block: absent entirely when the session aborted.
class SessionScore {
  const SessionScore({required this.total, required this.categories});

  final int total;

  /// Keyed by the locked category keys.
  final Map<String, int> categories;
}

/// `stats` block: computed deterministically in the broker, never by
/// the LLM.
class SessionStats {
  const SessionStats({
    required this.talkRatioRep,
    required this.fillerPerMin,
    required this.questionsAsked,
    required this.openQuestions,
    required this.longestRepMonologueSec,
    required this.interruptions,
    required this.durationSec,
    required this.wordsPerMinRep,
  });

  final double talkRatioRep;
  final double fillerPerMin;
  final int questionsAsked;
  final int openQuestions;
  final int longestRepMonologueSec;
  final int interruptions;
  final int durationSec;
  final int wordsPerMinRep;
}

/// One `keyMoments` entry: a re-ranked in-call hint event, deep-linking
/// to its utterance in the transcript.
class KeyMoment {
  const KeyMoment({
    required this.type,
    required this.categoryKey,
    required this.text,
    required this.utteranceIndex,
  });

  final MomentType type;
  final String categoryKey;
  final String text;
  final int utteranceIndex;
}

enum Speaker { rep, persona }

/// One `transcript` entry. The annotation is the kind only; the note
/// shown under an annotated line is the matching key moment's text.
class Utterance {
  const Utterance({
    required this.speaker,
    required this.text,
    required this.tsMs,
    this.annotation,
  });

  final Speaker speaker;
  final String text;
  final int tsMs;
  final MomentType? annotation;
}

/// `delta` block: computed and stored at write time so history never
/// re-renders differently later. Sessions 1-9 compare vs the previous
/// session; 10+ vs the 10-session rolling average.
class SessionDelta {
  const SessionDelta({required this.value, required this.basis});

  final int value;
  final DeltaBasis basis;
}

/// The full session document.
class SessionDoc {
  const SessionDoc({
    required this.id,
    required this.uid,
    required this.scenarioId,
    required this.simType,
    this.methodologyKey,
    required this.status,
    this.abortReason,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    this.score,
    this.stats,
    this.keyMoments = const [],
    this.transcript = const [],
    this.delta,
  });

  final String id;
  final String uid;
  final String scenarioId;
  final SimType simType;
  final String? methodologyKey;
  final SessionStatus status;
  final String? abortReason;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;

  /// Null when the session aborted: no score object, honest copy.
  final SessionScore? score;
  final SessionStats? stats;

  /// Max 6, up to 2 per type.
  final List<KeyMoment> keyMoments;
  final List<Utterance> transcript;
  final SessionDelta? delta;
}

/// Key moments in display and deep-link order: Strong, then Watch,
/// then Missed, stable by utterance order within a type. The `moment`
/// query parameter on the transcript route indexes THIS list, so the
/// score screen and the transcript screen must both order through
/// here.
List<KeyMoment> orderedKeyMoments(SessionDoc doc) {
  final moments = [...doc.keyMoments];
  moments.sort((a, b) {
    final byType = a.type.index.compareTo(b.type.index);
    return byType != 0
        ? byType
        : a.utteranceIndex.compareTo(b.utteranceIndex);
  });
  return moments;
}
