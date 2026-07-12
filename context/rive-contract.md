# Rive rig contract (avatar lipsync + idle life)

This file is the binding contract between the Rive avatar asset (.riv) and app code. Any rig replacement (test rig, production rig, future personas) must conform to these names exactly so app code never changes when the asset is swapped. Names are case-sensitive. If a name here must change, change it here first, then in code, in the same commit.

> Amended 2026-07-13 after verifying the test rig live (editor MCP + in-app probe). The rig is data-binding-first: the mouth is driven by the `AvatarVM` view model, NOT by a state machine input. The earlier draft's `Blink`/`HalfBlink`/`Breath` trigger-input trio described a rig that never existed; this version documents the real, verified surface. The app adapts to the rig here, once, deliberately.

## Asset + loading rules

- Asset path: `assets/rive/avatar.riv` (test rig now, production rig later, same filename so the swap is a file drop).
- Load via `rive.File.asset` + `RiveWidgetController` (never the plain `RiveAnimation.asset` widget). Bind data with `controller.dataBind(DataBind.auto())`, which instantiates the artboard's default `AvatarVM` instance; keep the returned `ViewModelInstance` and the `viseme` property handle.
- The Rive layer always sits on the permanent gradient placeholder Stack (see CLAUDE.md). Placeholder is the loading state and the fallback if the file, state machine, view model, or any required handle below fails to resolve. Fail soft to placeholder, log, never crash the sim.
- State machine name: **`LipSync`** (verified in the test rig, 2026-07-13). Code references it through a single const (`kAvatarStateMachine = 'LipSync'`) next to the name consts below.
- Layers inside `LipSync`: `Viseme`, `Viseme 2`, `Breath`, `Blink`. `Viseme 2` is an exact duplicate of `Viseme` (same animations, same conditions), so it currently changes nothing visibly; delete it in the next rig pass so the two can never drift apart. Code never references layers by name.

## Required runtime surface (verified on the test rig 2026-07-13)

| Handle | Kind | Behavior |
|---|---|---|
| `AvatarVM` | View model (auto-bind default instance) | Owns the mouth. Resolved via `dataBind(DataBind.auto())`. |
| `viseme` | Number property on `AvatarVM` | Mouth group selector, values 0 to 7 below, compared by equality. Set from the mapping table, scheduled against audio playback position. |
| `blink` | Trigger INPUT on `LipSync` (lowercase) | Full blink. Fired by the app on a randomized natural interval (~2 to 6 s), independent of mouth state. |
| `halfBlink` | Number INPUT on `LipSync` (lowercase) | Half-blink HOLD, not a trigger: set to 1 to enter the half-closed blend, back to 0 to release. App pulses 1 then 0 occasionally in place of a full blink. |

The legacy `viseme` Number INPUT still exists on the state machine but is wired to nothing. Do not use it; the mouth only listens to `AvatarVM.viseme`.

**Breathing needs no app code.** The `Breath` layer auto-plays its loop from the entry state, always on. There is no breath input to fire.

## Mouth groups (AvatarVM.viseme values)

Verified against the state machine transitions and visually in-app (2026-07-13): 1 opens (AA), 3 presses closed (MM), 5 rounds (OO).

| Value | Group | Covers |
|---|---|---|
| 0 | rest | silence / neutral |
| 1 | AA | open vowels |
| 2 | EE | spread vowels |
| 3 | MM | p, b, m (closed) |
| 4 | FF | f, v (teeth on lip) |
| 5 | OO | rounded vowels, w |
| 6 | LL | l, and tongue-forward d/t/n/th |
| 7 | SS | s, z, sh, ch, j |

The production rig must keep these values. (This ordering supersedes the earlier draft's 3=FF/4=LL/5=MM/6=OO table, which never matched the rig.)

## Azure viseme ID → mouth group mapping

Azure Speech emits viseme IDs 0 to 21 with an audio offset per event. The full mapping lives in ONE file: `lib/core/services/viseme_mapping.dart` (Azure ID → group → `AvatarVM.viseme` value). It is built once and referenced by LiveSimSession. Proposed table (tune by eye during the lipsync spike; keep the file as the single source):

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

Viseme events for a sentence arrive over the socket well before that audio is heard (TTS streams ahead of playback). Therefore: every `AvatarVM.viseme` update is scheduled against just_audio's playback position stream for that utterance's audio, NEVER against message-arrival time. Broker events must carry (utteranceId, visemeId, offsetMs from utterance audio start); the client keeps a per-utterance playback clock and fires viseme updates when position crosses offsetMs.

## Idle life (production rig additions)

The current test rig has no idle head sway and no eye saccades, so the character looks stiff between lines. The production rig must add both, independent of mouth state, driven (or at least gated) by the app. Prefer `AvatarVM` view model properties over new state machine inputs (inputs are deprecated in Rive):

| Handle (proposed, confirm at rig handoff) | Kind | Behavior |
|---|---|---|
| `sway` | Number property (0 to 1) | Idle head sway intensity. Rig loops the sway internally; app can dampen to 0 while the persona is mid-sentence if it fights the lipsync. |
| `saccade` | Trigger (property or input) | Small eye dart. App fires on a randomized ~1 to 4 s interval, more frequent while listening. |

Once the production rig locks these names, update this table to remove "proposed" and treat them as required. The verified handles in the required table above must keep their exact names in the production rig.
