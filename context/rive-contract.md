# Rive rig contract (avatar lipsync + idle life)

This file is the binding contract between the Rive avatar asset (.riv) and app code. Any rig replacement (test rig, production rig, future personas) must conform to these names exactly so app code never changes when the asset is swapped. Names are case-sensitive. If a name here must change, change it here first, then in code, in the same commit.

## Asset + loading rules

- Asset path: `assets/rive/avatar.riv` (test rig now, production rig later, same filename so the swap is a file drop).
- Load via `RiveFile` + `StateMachineController` and hold SMI input handles. NEVER the plain `RiveAnimation.asset` widget; it does not expose input handles.
- The Rive layer always sits on the permanent gradient placeholder Stack (see CLAUDE.md). Placeholder is the loading state and the fallback if the state machine or any required input fails to resolve. Fail soft to placeholder, log, never crash the sim.
- State machine name: **`LipSync`** (confirmed from the test rig, 2026-07-09). Code references it through a single const (`kAvatarStateMachine = 'LipSync'`) next to the input consts.
- Test rig layers inside `LipSync`: `Viseme`, `Viseme 2`, `Breath`, `Blink`. `Viseme 2` is a leftover test copy: code never references layers by name (only inputs), but the production rig should delete it so it cannot double-drive the mouth. The production rig keeps the state machine name `LipSync` and adds the idle-life layers below.

## Required inputs (validated on the test rig)

| Input | Type | Behavior |
|---|---|---|
| `viseme` | Number | Drives blends across the 8 mouth groups below. Set from the mapping table, scheduled against audio playback position. |
| `Blink` | Trigger | Full blink. Fired by the app on a randomized natural interval (~2 to 6 s), independent of mouth state. |
| `HalfBlink` | Trigger | Partial blink, fired occasionally in place of a full blink. Independent of mouth state. |
| `Breath` | Trigger | Slow steady breathing loop (~4 to 5 s cadence). Independent of mouth state. |

## Mouth groups (viseme Number values)

| Value | Group | Covers |
|---|---|---|
| 0 | rest | silence / neutral |
| 1 | AA | open vowels |
| 2 | EE | spread vowels |
| 3 | FF | f, v (teeth on lip) |
| 4 | LL | l, and tongue-forward d/t/n/th |
| 5 | MM | p, b, m (closed) |
| 6 | OO | rounded vowels, w |
| 7 | SS | s, z, sh, ch, j |

Confirm the exact Number value each blend expects against the test rig before Session 12 and correct this table if the rig's ordering differs. The production rig must keep the same values.

## Azure viseme ID → mouth group mapping

Azure Speech emits viseme IDs 0 to 21 with an audio offset per event. The full mapping lives in ONE file: `lib/core/services/viseme_mapping.dart`. It is built once and referenced by LiveSimSession. Proposed table (tune by eye during the lipsync spike; keep the file as the single source):

| Azure ID | Sound class | Group |
|---|---|---|
| 0 | silence | rest |
| 1, 2, 9, 11 | open vowels (ae, ah, aw, ay) | AA |
| 4, 5, 6 | mid/spread vowels (eh, er, iy) | EE |
| 3, 7, 8, 10 | rounded (ao, w/uw, ow, oy) | OO |
| 12 | h | AA |
| 13 | r | OO |
| 14, 19 | l, d/t/n/th | LL |
| 15, 16 | s/z, sh/ch/jh | SS |
| 17 | dh | LL |
| 18 | f/v | FF |
| 20 | k/g/ng | AA |
| 21 | p/b/m | MM |

## Sync rule (hard rule, also in CLAUDE.md)

Viseme events for a sentence arrive over the socket well before that audio is heard (TTS streams ahead of playback). Therefore: every viseme input update is scheduled against just_audio's playback position stream for that utterance's audio, NEVER against message-arrival time. Broker events must carry (utteranceId, visemeId, offsetMs from utterance audio start); the client keeps a per-utterance playback clock and fires `viseme` updates when position crosses offsetMs.

## Idle life (production rig additions)

The current test rig has no idle head sway and no eye saccades, so the character looks stiff between lines. The production rig must add both as new inputs, independent of mouth state, driven (or at least gated) by the app:

| Input (proposed, confirm at rig handoff) | Type | Behavior |
|---|---|---|
| `Sway` | Number (0 to 1) | Idle head sway intensity. Rig loops the sway internally; app can dampen to 0 while the persona is mid-sentence if it fights the lipsync. |
| `Saccade` | Trigger | Small eye dart. App fires on a randomized ~1 to 4 s interval, more frequent while listening. |

Once the production rig locks these names, update this table to remove "proposed" and treat them as required. The four inputs in the required table above must keep their exact names in the production rig.
