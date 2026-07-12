import '../../../core/widgets/widgets.dart' show AvatarArtTint;
import '../../scoring/domain/session_doc.dart';
import 'sim_session.dart';

/// One scripted utterance on the session timeline.
class ScriptedTurn {
  const ScriptedTurn({
    required this.speaker,
    required this.text,
    required this.atMs,
    required this.durMs,
  });

  final Speaker speaker;
  final String text;

  /// When the line lands (transcript entry + speaking envelope start),
  /// milliseconds from call start.
  final int atMs;

  /// How long the speaker "talks" (envelope stays live).
  final int durMs;
}

/// One scripted coaching event on the timeline.
class ScriptedCoaching {
  const ScriptedCoaching({required this.atMs, required this.event});

  final int atMs;
  final SimCoachingEvent event;
}

/// A canned conversation: the persona identity for the stage, the
/// timeline, and the session id the post-call score screen loads.
/// Content is canonical mock data; the timings are compressed so a
/// demo run shows the full arc in a couple of minutes.
class SimScript {
  const SimScript({
    required this.resultSessionId,
    required this.scenarioLabel,
    required this.personaName,
    required this.personaShortName,
    required this.personaRole,
    required this.personaInitials,
    required this.tint,
    required this.estimatedMinutes,
    required this.turns,
    required this.coaching,
  });

  final String resultSessionId;

  /// Topbar context, e.g. 'SaaS gatekeeper'.
  final String scenarioLabel;

  /// Stage name, e.g. 'Sandra Voss'.
  final String personaName;

  /// Transcript speaker label, e.g. 'Sandra'.
  final String personaShortName;

  /// Stage line under the name, e.g. 'Front desk gatekeeper'.
  final String personaRole;

  final String personaInitials;
  final AvatarArtTint tint;

  /// Drives the topbar progress stripe and the exit-confirm copy.
  final int estimatedMinutes;

  final List<ScriptedTurn> turns;
  final List<ScriptedCoaching> coaching;
}

/// Cold Call demo script: Sandra Voss, the canonical gatekeeper
/// (context/canonical-mock-data.md), lines drawn from the canonical
/// transcript with compressed timings.
const coldCallScript = SimScript(
  resultSessionId: 'scripted-cold-call',
  scenarioLabel: 'SaaS gatekeeper',
  personaName: 'Sandra Voss',
  personaShortName: 'Sandra',
  personaRole: 'Front desk gatekeeper',
  personaInitials: 'SV',
  tint: AvatarArtTint.slate,
  estimatedMinutes: 12,
  turns: [
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 2000,
      durMs: 4500,
      text: 'Meridian Software, this is Sandra. How can I direct your '
          'call?',
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 8000,
      durMs: 4000,
      text: "Hey Sandra, this is Osman. Hope your morning's going "
          'alright over there.',
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 13500,
      durMs: 3000,
      text: "It's going, thanks. What can I help you with?",
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 18000,
      durMs: 7500,
      text: 'I work with a few SaaS companies here in Chicago helping '
          'their sales teams cut ramp time. Had a quick one for David '
          'about how you all onboard new reps. Two minutes, tops.',
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 27000,
      durMs: 4500,
      text: "Can I ask what this is regarding? David's schedule is "
          'pretty full this week.',
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 33500,
      durMs: 5500,
      text: 'Totally fair question. It is about ramp time for the new '
          'reps, and whether that is even a problem worth his ten '
          'minutes. If not, I am gone.',
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 41000,
      durMs: 3500,
      text: "(laughs) Okay, that's a new one. Let me see if he's free.",
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 48000,
      durMs: 4500,
      text: 'Actually, hold on one second. He might be between '
          'meetings. Can you hold?',
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 53500,
      durMs: 2000,
      text: 'Of course, take your time.',
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 60000,
      durMs: 5000,
      text: "Thanks for holding. He's tied up until this afternoon "
          'after all. Want me to have him call you back?',
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 66500,
      durMs: 5000,
      text: "Yeah, whenever's easiest for him. I don't want to be a "
          "bother, so no pressure if today doesn't work.",
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 73000,
      durMs: 3500,
      text: 'Alright, I can pass a message along. Does he have your '
          'number?',
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 78000,
      durMs: 5000,
      text: "He doesn't yet. It's 312-555-0184. I'm around all "
          "afternoon if that's easier.",
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 84500,
      durMs: 3000,
      text: 'Got it. And which company did you say you were with?',
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 89000,
      durMs: 5500,
      text: 'Closero. We work with sales teams at SaaS companies about '
          'your size, mostly on how fast new reps get productive.',
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 96000,
      durMs: 4000,
      text: 'Six years in March. I was the fourth hire, believe it or '
          'not.',
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 101500,
      durMs: 5000,
      text: "So you've watched the whole sales team get built. That's "
          'exactly the kind of story I was hoping to walk into.',
    ),
  ],
  coaching: [
    ScriptedCoaching(
      atMs: 3000,
      event: SimNextMove(
        title: 'Give your name and one clear reason for the call',
        body: 'Sandra screens every cold call. A name, a reason, and a '
            'reason to believe you, all in under fifteen seconds.',
      ),
    ),
    ScriptedCoaching(
      atMs: 12500,
      event: SimHint(
        kind: MomentType.good,
        label: 'Rapport',
        note: 'Used her name, good start',
      ),
    ),
    ScriptedCoaching(
      atMs: 26000,
      event: SimHint(
        kind: MomentType.good,
        label: 'Framing',
        note: 'Led with outcome, not product',
      ),
    ),
    ScriptedCoaching(
      atMs: 29000,
      event: SimNextMove(
        title: 'Answer her name question, then redirect immediately',
        body: "Don't let her pause reset the momentum. Name your "
            'company, then bridge straight back to David.',
      ),
    ),
    ScriptedCoaching(
      atMs: 44000,
      event: SimHint(
        kind: MomentType.warn,
        label: 'Tonality',
        note: 'Sentences ending on an uptick',
      ),
    ),
    ScriptedCoaching(
      atMs: 72000,
      event: SimHint(
        kind: MomentType.miss,
        label: 'Discovery',
        note: 'Skipped a qualifying question',
      ),
    ),
    ScriptedCoaching(
      atMs: 76000,
      event: SimNextMove(
        title: 'Trade the callback for a specific time',
        body: 'A message gets buried. Offer Thursday morning yourself '
            'and let her confirm it.',
      ),
    ),
    ScriptedCoaching(
      atMs: 104000,
      event: SimHint(
        kind: MomentType.good,
        label: 'Rapport',
        note: 'Turned her tenure into the conversation',
      ),
    ),
  ],
);

/// Video Sim demo script: Marcus Reed, the ROI-first VP of Sales
/// (prototype-screens/06-live-video.png). Hints stay audio-observable
/// only; the prototype's eye-contact and body-language lines are
/// deliberately replaced (no CV claims).
const videoSimScript = SimScript(
  resultSessionId: 'scripted-video',
  scenarioLabel: 'Discovery call',
  personaName: 'Marcus Reed',
  personaShortName: 'Marcus',
  personaRole: 'VP of Sales, Apex Systems',
  personaInitials: 'MR',
  tint: AvatarArtTint.violet,
  estimatedMinutes: 15,
  turns: [
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 2000,
      durMs: 4500,
      text: "Alright, you're on. Fair warning, you have ten minutes "
          'and I have a hard stop.',
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 8000,
      durMs: 5000,
      text: "Then I'll spend them on you, not on slides. What does "
          'ramp look like for a new rep on your team today?',
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 14500,
      durMs: 6000,
      text: 'Longer than I want. Realistically five, six months before '
          "they're carrying a full number. Why?",
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 22000,
      durMs: 5500,
      text: 'Because that number is usually where the money hides. '
          'What have you already tried to shorten it?',
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 29500,
      durMs: 6500,
      text: 'Shadowing, call libraries, a coach for the first month. '
          "We've looked at options. Honestly none of it moved the "
          'needle much.',
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 38000,
      durMs: 6000,
      text: 'That matches what I hear from most VPs your size. When a '
          'rep finally does ramp fast, what did they do differently?',
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 46000,
      durMs: 6000,
      text: 'Reps. More at-bats, earlier. The fast ones burned through '
          'bad calls quicker than everyone else.',
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 54000,
      durMs: 6000,
      text: 'So the bottleneck is safe at-bats. If your new reps could '
          'run twenty hard calls before the first real one, what would '
          'that be worth against a six month ramp?',
    ),
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 62000,
      durMs: 5000,
      text: "Now that's a question I can take to a spreadsheet. Keep "
          'going.',
    ),
  ],
  coaching: [
    ScriptedCoaching(
      atMs: 3000,
      event: SimNextMove(
        title: "Ask about current onboarding, don't pitch yet",
        body: "He's still sizing you up. A discovery question keeps "
            'him talking and builds trust first.',
      ),
    ),
    ScriptedCoaching(
      atMs: 13500,
      event: SimHint(
        kind: MomentType.good,
        label: 'Discovery',
        note: 'Opened with his process, not your pitch',
      ),
    ),
    ScriptedCoaching(
      atMs: 28000,
      event: SimHint(
        kind: MomentType.good,
        label: 'Pacing',
        note: 'Letting silence land, not rushing to fill',
      ),
    ),
    ScriptedCoaching(
      atMs: 36000,
      event: SimNextMove(
        title: 'Dig into what "looked at options" means',
        body: 'He named three fixes that failed. Ask which one came '
            'closest before you offer a fourth.',
      ),
    ),
    ScriptedCoaching(
      atMs: 43000,
      event: SimHint(
        kind: MomentType.warn,
        label: 'Talk ratio',
        note: 'Creeping past half, tighten your turns',
      ),
    ),
    ScriptedCoaching(
      atMs: 50000,
      event: SimHint(
        kind: MomentType.miss,
        label: 'Discovery',
        note: 'Missed a budget signal, "looked at options"',
      ),
    ),
    ScriptedCoaching(
      atMs: 58000,
      event: SimHint(
        kind: MomentType.good,
        label: 'Framing',
        note: 'Tied the ask to his ramp number',
      ),
    ),
  ],
);
