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

Five categories, each 0-100, composite is the weighted total. Confirm the display names against the Dashboard prototype crop before Session 10 locks copy; the KEYS below are the schema and do not change even if display names do.

| Key | Display name (proposed) | Weight | Observable signals the scoring LLM uses |
|---|---|---|---|
| `discovery` | Discovery | 25% | Open questions asked, follow-ups on pain points, listening before pitching, need summarized back |
| `objections` | Objection handling | 25% | Objections acknowledged vs dodged, reframe quality, staying calm on pushback, not caving on price instantly |
| `clarity` | Clarity & pacing | 15% | Filler words per minute, run-on rambling, pace changes, concrete language vs jargon |
| `listening` | Talk balance | 15% | Talk ratio (target ~40-45% rep), interruptions, dead-air recovery, building on what the persona said |
| `closing` | Next steps | 20% | Asked for something concrete, trial close attempts, summarized agreement, specific follow-up locked |

- Composite: `total = 0.25*discovery + 0.25*objections + 0.15*clarity + 0.15*listening + 0.20*closing`, rounded to an integer.
- Thresholds everywhere in the UI: 75+ strong (hi2 ring), 60-74 developing (mid), <60 focus area (dim1). Same bands for category scores and the composite.
- Methodology scenarios (Closer tier) may override weights and add methodology-specific signals (e.g. SPIN: weight discovery 35%, check for Situation/Problem/Implication/Need-payoff sequencing). Overrides live in the scenario definition, not in code: each scenario document carries an optional `rubricOverride` block with the same shape.

## Overall score + earning potential (the trajectory layer)

- **Overall score** = `rolling10` composite (mean of the last 10 completed sessions; all of them if <10). This is the number on the Dashboard, and the input to the income mapping. A single session never moves earning potential directly.
- **Consistency modifier.** A skill tier requires proof, not a spike. `tierScore = rolling10`, but a tier is only CONFIRMED when both hold: at least 5 completed sessions inside the band, and standard deviation of the last 10 composites ≤ 12. Until confirmed, the UI shows the tier as "in reach" rather than reached. This is the honest version of "consistency counts", and it is also the motivation loop: the path to the next income band is always "N more sessions at this level", which is a practice prompt, not a grade.
- **Income mapping** (copy rules from CLAUDE.md apply: market bands at a skill tier, "per published comp data", never a personal prediction): rolling10 <60 → entry band, 60-74 → mid band ($64K canonical), 75+ confirmed → next tier band ($85-95K canonical). The app NEVER says "you will earn X"; it says "reps who sell at this level typically earn X-Y, per published comp data".
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

- `sessionCount`, `lastSessionAt`, `streakDays` (calendar days with ≥1 completed session, local to the user's tz offset captured at session start; aborted sessions never count).
- Per category and total: `rolling10`, `stdDev10`, `best` (personal best composite, and per scenario for the Library "personal best" chip), `tierConfirmed: bool` per the consistency rule above.
- Delta rule (already a CLAUDE.md rule, restated): sessions 1-9 compare vs the previous session (`basis: last_session`); sessions 10+ compare vs the rolling 10-session average excluding the current session (`basis: rolling_10`). The delta is computed and stored at write time so history never re-renders differently later.
- Progress screen 7D/30D/90D/All: query completed sessions by `endedAt` range and recompute section values from that result set; the aggregate doc is only the Dashboard fast path.

## Open questions for Osman before this is wired into the prompt pack

1. Do the five category names match the prototype's Skill Breakdown labels? If the prototype shows different skills, the display names change and the keys stay.
2. Happy with 40-45% as the target rep talk ratio? (Common coaching guidance for discovery-heavy calls; cold-call opens can run higher.)
3. Confirm the consistency rule (5 sessions in band + stdDev ≤ 12 to confirm a tier) and the 21-day freshness nudge.
4. Streak definition uses completed sessions only. Confirm.
