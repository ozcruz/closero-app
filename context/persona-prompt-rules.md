# Persona reply-length policy (global roleplay behavior)

Injected by the broker (Session 13) into the roleplay system prompt for EVERY persona, ahead of the per-persona brief (written in the Part 4 #13 content pass). This is a GLOBAL rule; do not duplicate it inside individual persona briefs.

## Why this exists (two aligned reasons)

1. **Cost.** Azure TTS is billed per character and is the single largest per-session cost line. Session cost rides on the AVERAGE persona reply length, not any one turn. A ~150-character average across ~15 outputs holds a session at ~$0.10 (model below).
2. **Realism + training value.** Real prospects are terse and make the rep work for information. A prospect who monologues their pain points lets a lazy rep off the hook; a terse one forces good discovery questions, which is exactly what Closero scores. Short-by-default is both cheaper AND better training.

## The rule (put this BEHAVIOR in the system prompt, not a hard character counter)

> "Keep most of your replies to a single sentence. Speak like a real prospect who is busy and a little guarded. Only expand to two or three sentences when you are revealing a pain point, explaining what your business does, or giving context the rep earned with a good question. Never monologue, never over-explain."

Guideline lengths (targets, not hard cutoffs, a rigid per-character cap chops replies mid-thought):

| Turn type | Length | Frequency |
|---|---|---|
| Reactive (objection, brushoff, yes/no, pushback) | ~40-120 chars, 1 sentence | Most turns |
| Normal conversational | ~120-180 chars, 1-2 sentences | Default |
| Substantive (pain points, explaining their business, opening up) | ~200-320 chars, 2-3 sentences | Sparingly, ~2-4 per session |

Target: session AVERAGE ~150 chars across ~15 outputs (~2,250 chars total). Let the long turns happen; balance them with short ones.

## Cost model this assumes (verify against Part 4 #9 broker cost logging)

15 outputs, ~150-char average replies, GPT-5.4-mini (caching on), Deepgram Nova-3 STT, Azure Standard Neural TTS. Pricing as of 2026-07:

- TTS: ~2,250 chars → ~$0.036
- STT: ~6 min → ~$0.03-0.05
- LLM (roleplay turns + hint checks + 1 scoring pass): ~$0.02-0.035
- **Total: ~$0.10/session**

If the real logged cost drifts above ~$0.15, tighten the average toward ~120 chars or drop the output cap before changing the model choice. Output cap and ~150-char average are PROVISIONAL defaults pending week-4 funnel/COGS data.
