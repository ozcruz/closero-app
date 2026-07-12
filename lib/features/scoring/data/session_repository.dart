import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/session_doc.dart';

/// A session document joined with the display context the score and
/// transcript screens need but the `sessions/{id}` schema does not
/// carry: scenario and persona naming from the catalog, the previous
/// session's category scores (the "Last session" captions), and the
/// user's completed-session count. The Firestore implementation
/// resolves these joins server-side data; the fixture bakes them in.
class SessionView {
  const SessionView({
    required this.doc,
    required this.scenarioTitle,
    required this.personaName,
    required this.personaShortName,
    required this.personaRole,
    this.methodologyLabel,
    required this.sessionNumber,
    this.previousCategories = const {},
  });

  final SessionDoc doc;

  /// e.g. 'Gatekeeper bypass, SaaS AE'.
  final String scenarioTitle;

  /// e.g. 'Sandra Voss'.
  final String personaName;

  /// Transcript speaker label, e.g. 'Sandra'.
  final String personaShortName;

  /// e.g. 'Front desk gatekeeper'.
  final String personaRole;

  /// Short framework label for the transcript meta, e.g. 'Sandler'.
  /// Null when the session ran without a methodology overlay.
  final String? methodologyLabel;

  /// 1-based count of the user's completed sessions including this
  /// one; consistent with `doc.delta.basis` by the write-time rule.
  final int sessionNumber;

  /// Previous session's category scores for the per-category "Last
  /// session" captions; empty for a first session.
  final Map<String, int> previousCategories;
}

/// Read side of the score and transcript screens. Fixture-backed
/// today; the Firestore implementation (server-written session docs)
/// swaps in behind this interface.
abstract interface class SessionRepository {
  /// Null when the id resolves to nothing the user can see.
  Future<SessionView?> load(String sessionId);
}

/// Serves the canonical mock session (context/canonical-mock-data.md,
/// score screen sheet) for any requested id, so every session row and
/// deep link lands on real content during the mock-data phase. The
/// reserved id 'aborted' serves the no-score variant for the honest
/// aborted-session state.
class FixtureSessionRepository implements SessionRepository {
  const FixtureSessionRepository();

  @override
  Future<SessionView?> load(String sessionId) async =>
      sessionId == 'aborted'
          ? abortedSessionFixture
          : sessionViewFixture(sessionId);
}

/// Canonical completed session: Gatekeeper bypass, SaaS AE, overall
/// 78, the 84/71/61 sub-scores from the mock-data sheet on rapport,
/// objections, and tonality, +6 pts vs the 10-session average
/// (session 47, so basis rolling_10). Category scores satisfy the
/// rubric composite exactly: 0.25*71 + 0.25*86 + 0.20*85 + 0.15*84 +
/// 0.15*61 = 78.
SessionView sessionViewFixture(String sessionId) => SessionView(
      doc: SessionDoc(
        id: sessionId,
        uid: 'uid-1',
        scenarioId: 'cold-call-saas-gatekeeper',
        simType: SimType.coldCall,
        methodologyKey: 'sandler',
        status: SessionStatus.complete,
        startedAt: DateTime(2026, 7, 11, 9, 12),
        endedAt: DateTime(2026, 7, 11, 9, 26, 32),
        durationSec: 872,
        score: const SessionScore(
          total: 78,
          categories: {
            'objections': 71,
            'discovery': 86,
            'closing': 85,
            'rapport': 84,
            'tonality': 61,
          },
        ),
        stats: const SessionStats(
          talkRatioRep: 0.43,
          fillerPerMin: 2.1,
          questionsAsked: 9,
          openQuestions: 6,
          longestRepMonologueSec: 48,
          interruptions: 1,
          durationSec: 872,
          wordsPerMinRep: 148,
        ),
        keyMoments: _keyMoments,
        transcript: _transcript,
        delta: const SessionDelta(value: 6, basis: DeltaBasis.rolling10),
      ),
      scenarioTitle: 'Gatekeeper bypass, SaaS AE',
      personaName: 'Sandra Voss',
      personaShortName: 'Sandra',
      personaRole: 'Front desk gatekeeper',
      methodologyLabel: 'Sandler',
      sessionNumber: 47,
      previousCategories: const {
        'objections': 69,
        'discovery': 81,
        'closing': 76,
        'rapport': 76,
        'tonality': 64,
      },
    );

/// The honest no-score variant: mic dropped mid-call, no score object,
/// no cap burn.
final abortedSessionFixture = SessionView(
  doc: SessionDoc(
    id: 'aborted',
    uid: 'uid-1',
    scenarioId: 'cold-call-saas-gatekeeper',
    simType: SimType.coldCall,
    status: SessionStatus.aborted,
    abortReason: 'mic_failure',
    startedAt: DateTime(2026, 7, 11, 8, 40),
    endedAt: DateTime(2026, 7, 11, 8, 42, 10),
    durationSec: 130,
  ),
  scenarioTitle: 'Gatekeeper bypass, SaaS AE',
  personaName: 'Sandra Voss',
  personaShortName: 'Sandra',
  personaRole: 'Front desk gatekeeper',
  sessionNumber: 47,
);

/// Key moments: the in-call hint events re-ranked. The text convention
/// is 'headline.\n' followed by the coaching note; the score screen
/// splits on the
/// first newline, the transcript renders the note under the linked
/// utterance. Max 6, up to 2 per type.
const _keyMoments = [
  KeyMoment(
    type: MomentType.good,
    categoryKey: 'rapport',
    text: 'Disarmed the gatekeeper in under 30 seconds.\n'
        'You matched her pace, dropped the formal register, and got the '
        'opening without friction. That is the pattern, keep it.',
    utteranceIndex: 5,
  ),
  KeyMoment(
    type: MomentType.warn,
    categoryKey: 'closing',
    text: 'Gave away too much when she offered a callback.\n'
        'You volunteered "no pressure" before she had pushed back at all. '
        'That signals low leverage. Hold your position one beat longer, '
        'she had not actually said no.',
    utteranceIndex: 10,
  ),
  KeyMoment(
    type: MomentType.miss,
    categoryKey: 'tonality',
    text: 'Dropped tonality on the budget objection.\n'
        'Your pitch rose at "is that a concern?" It sounds like asking '
        'for permission. Same words, flatter delivery changes the frame '
        'entirely.',
    utteranceIndex: 19,
  ),
];

/// The call, 14:32 end to end (prototype-screens/09-transcript.png
/// above the fold; the later exchanges follow the same call arc since
/// the prototype crop ends at 5:00).
const _transcript = [
  Utterance(
    speaker: Speaker.persona,
    tsMs: 4000,
    text: 'Meridian Software, this is Sandra. How can I direct your call?',
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 11000,
    text: "Hey Sandra, this is Osman. Hope your morning's going alright "
        'over there.',
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 18000,
    text: "It's going, thanks. What can I help you with?",
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 26000,
    text: "I'm trying to reach David Chen. Is he around today?",
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 34000,
    text: "Can I ask what this is regarding? David's schedule is pretty "
        'full this week.',
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 74000,
    annotation: MomentType.good,
    text: 'Totally fair question. I work with a few SaaS companies here '
        'in Chicago helping their sales teams cut ramp time. Had a quick '
        'one for David about how you all onboard new reps. Two minutes, '
        'tops.',
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 82000,
    text: "(laughs) Okay, that's a new one. Let me see if he's free.",
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 136000,
    text: 'Actually, hold on one second. He might be between meetings. '
        'Can you hold?',
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 140000,
    text: 'Of course, take your time.',
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 285000,
    text: "Thanks for holding. He's tied up until this afternoon after "
        'all. Want me to have him call you back?',
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 292000,
    annotation: MomentType.warn,
    text: "Yeah, whenever's easiest for him. I don't want to be a "
        "bother, so no pressure if today doesn't work.",
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 303000,
    text: 'Alright, I can pass a message along. Does he have your number?',
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 312000,
    text: "He doesn't yet. It's 312-555-0184. I'm around all afternoon "
        "if that's easier.",
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 326000,
    text: 'Got it. And which company did you say you were with?',
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 338000,
    text: 'Closero. We work with sales teams at SaaS companies about '
        'your size, mostly on how fast new reps get productive.',
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 365000,
    text: 'How long have you been with Meridian, if you do not mind me '
        'asking?',
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 378000,
    text: 'Six years in March. I was the fourth hire, believe it or not.',
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 391000,
    text: "So you've watched the whole sales team get built. That's "
        'exactly the kind of story I was hoping to walk into.',
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 527000,
    text: 'I should mention, I keep hearing them talk about the budget '
        'review. I think new software spend is frozen this quarter.',
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 547000,
    annotation: MomentType.miss,
    text: 'That makes sense, I hear that a lot this time of year. We '
        'could still do a short intro call before anything formal. Is '
        'that a concern?',
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 564000,
    text: "Hard to say. Honestly, that's David's call, not mine.",
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 576000,
    text: "Understood. Then here's what I'll do: a two-line note he can "
        "read in thirty seconds, and I'll try him Thursday morning.",
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 591000,
    text: "That works. I'll flag it so it doesn't get buried.",
  ),
  Utterance(
    speaker: Speaker.rep,
    tsMs: 838000,
    text: 'Appreciate the help, Sandra. You made this the easiest call '
        'of my morning.',
  ),
  Utterance(
    speaker: Speaker.persona,
    tsMs: 852000,
    text: '(laughs) Good luck with David. Have a good one.',
  ),
];

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => const FixtureSessionRepository(),
);

final sessionViewProvider = FutureProvider.family<SessionView?, String>(
  (ref, sessionId) => ref.watch(sessionRepositoryProvider).load(sessionId),
);
