# Scoring rubric + stats contract (draft for review, not yet wired into the prompt pack)

This file defines what a session score IS: the categories, weights, hint taxonomy, the `sessions/{id}` schema, and the aggregate math. The scoring LLM (broker, Session 13), the score screens (Session 10), and the Dashboard Skill Breakdown must all agree with this file. Scores are server-written; the client only displays.

## Ground rules (inherited from CLAUDE.md, restated so this doc stands alone)

- Everything scored must be observable from audio/transcript only: words, pacing, filler words, talk ratio, questions asked, structure. Never body language, never "confidence" claims dressed up as CV.
- No live score mid-call. Momentum dots are the only in-call signal (one dot per logged `good` hint, max 5 shown).
- The client never computes-and-saves a score. Cloud Function writes `sessions/{id}`; the app reads.
- Aborted sessions (socket drop, mic failure) get `status: aborted`, no score object, no cap burn.

## The three scoring layers (how it all connects)

1. **Live layer (during the call):** good/warn/miss hint events only. Never a number. A number mid-call makes people play the meter instead of the conversation; dots reward momentum without grading.
2. **Session layer (after each call):** the 0-100 composite below, per category. This is the score users grind to improve.
3. **Trajectory layer (across calls):** rolling averages + consistency. THIS is what maps to earning potential, never a single hot session. One great call proves a moment; ten solid calls prove a skill, and skill tiers are what published comp data prices.

## Score categories (the Skill Breakdown)

Five categories, each 0-100, composite is the weighted total. Display names locked 2026-07-10 to match the prototype's Skill Breakdown. The KEYS are the schema and never change even if display copy is tweaked.

| Key | Display name (LOCKED) | Weight | Observable signals the scoring LLM uses |
|---|---|---|---|
| `objections` | Objection handling | 25% | Objections acknowledged vs dodged, reframe quality, staying calm on pushback, not caving on price instantly |
| `discovery` | Discovery questions | 25% | Open questions asked, follow-ups on pain points, listening before pitching, need summarized back |
| `closing` | Closing technique | 20% | Asked for something concrete, trial close attempts, summarized agreement, specific follow-up locked |
| `rapport` | Building rapport | 15% | Talk ratio (target ~40-45% rep), building on what the persona said, acknowledgment before redirecting, mirroring their language, interruptions (negative) |
| `tonality` | Tonality and pacing | 15% | Filler words per minute, words per minute and pace shifts, monologue length, pause discipline, concrete language vs jargon |

- Composite: `total = 0.25*objections + 0.25*discovery + 0.20*closing + 0.15*rapport + 0.15*tonality`, rounded to an integer.
- Honesty note on `tonality`: v1 judges it from transcript-derivable signals (pace, fillers, pauses, word choice). True acoustic tone (pitch, energy) needs audio-feature extraction in the broker; that is a v1.1 upgrade, and copy must not claim we hear tone until it exists.

## Extended signal set (background depth, simple UI)

The UI shows 5 numbers; the background records much more, per session, so scoring gets more accurate over time and the income mapping can be tuned on real evidence without a schema change:

- Each category gets sub-signals stored in `score.signals.{categoryKey}` as 0-100 subscores. Launch set: objections → {acknowledged, reframed, heldGround}; discovery → {openQuestionRate, followUpDepth, needSummarized}; closing → {askedForCommitment, trialCloses, nextStepLocked}; rapport → {talkRatioScore, buildingOnAnswers, interruptions}; tonality → {fillerScore, paceScore, monologueScore}.
- Sub-signals are LLM-graded but anchored to the deterministic `stats` block wherever a hard number exists (e.g. `talkRatioScore` is computed, not judged).
- Nothing in the UI depends on sub-signals in v1, so they can be refined freely. Later they power deeper coaching ("your discovery is strong but follow-up depth is the gap") and a smarter earning-potential model.
- Thresholds everywhere in the UI: 75+ strong (hi2 ring), 60-74 developing (mid), <60 focus area (dim1). Same bands for category scores and the composite.
- Methodology scenarios (Closer tier) may override weights and add methodology-specific signals (e.g. SPIN: weight discovery 35%, check for Situation/Problem/Implication/Need-payoff sequencing). Overrides live in the scenario definition, not in code: each scenario document carries an optional `rubricOverride` block with the same shape.

## Overall score + earning potential (the trajectory layer)

- **Overall score** = `rolling10` composite (mean of the last 10 completed sessions; all of them if <10). This is the number on the Dashboard, and the input to the income mapping. A single session never moves earning potential directly.
- **Consistency rule (plain version).** A skill tier requires proof, not one hot call. A tier is CONFIRMED when at least 5 of the user's last 7 completed sessions score inside that tier's band. Until then the UI shows the tier as "in reach", with copy like "2 more calls at this level and this is your tier". That line is the motivation loop: the path to the next income band is always a concrete number of good sessions, which is a practice prompt, not a grade.
- **Income mapping** (copy rules from CLAUDE.md apply: market bands at a skill tier, "per published comp data", never a personal prediction): rolling10 <60 → entry band, 60-74 → mid band ($64K canonical), 75+ confirmed per the consistency rule → next tier band ($85-95K canonical). The app NEVER says "you will earn X"; it says "reps who sell at this level typically earn X-Y, per published comp data".
- **Freshness decay (proposed, confirm):** if no completed session in 21 days, the tier shows as "needs a warm-up" (copy, not a score penalty). Skills fade; punishing the number feels unfair, nudging a session does not.
- Skill Breakdown on the Dashboard = category `rolling10` values, weakest first, each with its own threshold color. The weakest category is the "fastest path up" input for Achievements.

## Hint taxonomy (in-call coaching, off the turn path)

Every hint event carries `{ type: good|warn|miss, categoryKey, text, utteranceIndex }`.

- `good`: a strong move worth reinforcing ("Nice open question, she gave you a real pain point"). Fills a momentum dot.
- `warn`: drifting, recoverable ("You have been talking for 90 seconds straight").
- `miss`: a clear missed opportunity ("She hinted at budget pressure and it went past you").
- Hints must name the behavior, not the person. Low pressure, per copy voice.
- Post-call Key Moments are the same events re-ranked: Strong = the best `good`s, Watch = `warn`s, Missed = `miss`es, each deep-linking to its `utteranceIndex` in the transcript.
- Dots cap at 5; goods past 5 still log as Key Moment candidates.

## Hard stats (computed deterministically in the broker, not by the LLM)

`stats` block, written alongside the LLM rubric so numbers are reproducible: `talkRatioRep` (0-1), `fillerPerMin`, `questionsAsked`, `openQuestions`, `longestRepMonologueSec`, `interruptions`, `durationSec`, `wordsPerMinRep`. The scoring LLM receives these as input context; it never invents its own numbers.

## sessions/{id} schema (server-written; mock fixtures in Session 10 must match exactly)

```
sessions/{id}:
  uid, scenarioId, simType: 'cold_call'|'video', methodologyKey?: string
  status: 'complete'|'aborted', abortReason?: string
  startedAt, endedAt, durationSec
  score: { total: int, categories: { discovery, objections, clarity, listening, closing } }   // absent when aborted
  stats: { ...block above }
  keyMoments: [ { type, categoryKey, text, utteranceIndex } ]   // max 6: up to 2 per type
  transcript: [ { speaker: 'rep'|'persona', text, tsMs, annotation?: 'good'|'warn'|'miss' } ]
  delta: { value: int, basis: 'last_session'|'rolling_10' }     // computed at write time, see below
```

## Aggregates + deltas (Cloud Function updates on each completed session)

`users/{uid}/aggregates/current` (one doc, server-written):

- `sessionCount`, `lastSessionAt`, `streakDays` (calendar days with ≥1 streak-qualifying session, local to the user's tz offset captured at session start; aborted-for-technical-failure sessions never count).
- Per category and total: `rolling10`, `best` (personal best composite, and per scenario for the Library "personal best" chip), `tierConfirmed: bool` per the consistency rule above.
- Delta rule (already a CLAUDE.md rule, restated): sessions 1-9 compare vs the previous session (`basis: last_session`); sessions 10+ compare vs the rolling 10-session average excluding the current session (`basis: rolling_10`). The delta is computed and stored at write time so history never re-renders differently later.
- Progress screen 7D/30D/90D/All: query completed sessions by `endedAt` range and recompute section values from that result set; the aggregate doc is only the Dashboard fast path.

## Streaks (engagement metric, firewalled from skill)

Streaks measure showing up; skill scores measure selling. The two never mix: a streak must not inflate any category score or the income tier, or the earning-potential claim stops being defensible ("practiced daily" is not "sells at the $85-95K level"). Streaks reward the user through access and recognition instead:

- **What counts (the commit point):** a session counts toward the streak once it reaches the commit point, defined at launch as 3+ minutes of real conversation OR the first `good` hint on an objection exchange, whichever comes first. A full completed session is NOT required; requiring it makes streaks feel like homework. After launch, replace the 3-minute guess with the measured point of lowest mid-session exit (PostHog: sim_start vs sim_completed durations) and record the change here.
- Scores still require a completed session. Commit point = streak credit only.
- **Streak benefits (mechanically true, no score inflation):** 7-day streak = +1 bonus free session that month (free tier; costs us ~$0.25, buys a habit); 30-day streak = a Library scenario unlock. Both are server-granted through the same entitlement/cap machinery, never client-side.
- Freshness nudge stays copy-only ("needs a warm-up"), never a score penalty.

## Decisions log

- 2026-07-10: category names locked to the prototype's five (objections, discovery, closing, rapport, tonality); talk-ratio target 40-45% accepted; consistency rule reworded to "5 of last 7 in band"; streak commit-point model adopted with launch default of 3 min or first objection `good`, to be recalibrated from funnel data.

## Remaining open items

1. Confirm the streak benefits are wanted at launch (+1 session at 7 days, scenario unlock at 30) or v1.1.
2. Tonality acoustic analysis (pitch/energy) is v1.1; transcript-derived signals only in v1.
