# Session 17a: Release audit (read-only)

Run 2026-07-14/15. Read-only: nothing was edited. This is the input to 17b.

## SUPERSEDED IN PART. Read this before actioning anything below (2026-07-16)

Three corrections, in order of importance:

1. **Every icon finding in this document is VOID.** They enforce CLAUDE.md's icon-signature
   rule, and that rule is wrong: it demands "exactly ONE -60° element" per icon, but the
   wordmark cuts a strip through the ring's centre (two PARALLEL gaps), and the signature was
   only ever meant for the simulation icon. The audit was faithful to a miswritten rule. The
   rule is now suspended in CLAUDE.md and will be rewritten during the UI overhaul. Do not act
   on any icon finding here.

2. **A UI overhaul is coming (colors, typography, icons).** Every cosmetic finding below is
   deferred until after it: the accent block, the token block, all 16 nits, and must-fix 12
   (dim1 contrast). Fixing them now means fixing them twice. The FUNCTIONAL and HONESTY
   findings still stand: must-fix 1-11.

3. **`startSimSession` BLOCKS at the cap.** Confirmed by live test 2026-07-16 (5/5 sessions
   then the paywall). CLAUDE.md's "even while it only increments" is stale. The cost model
   holds and the trial phases extend a gate that provably works.

Also revised: must-fix 7 no longer means "derive scenarioCount from fixtures". DELETE
`scenarioCount` from the methodology cards outright. Custom scenarios are planned, which makes
any count a lie with a shelf life, and deleting it kills the SPIN-has-zero problem with no
content authoring. Reword the link to "Browse the library" until a real filter exists.

## Method

8 screen-clusters x 6 dimensions = 48 finder agents, reusing the `.claude/agents/` reviewers
(accent-auditor, copy-voice, token-cop) as the per-dimension lenses. Every deduplicated finding was
then attacked by 3 independent refuters (does the code say this / is the rule actually broken / is it
already handled upstream), surviving only on a 2-of-3 majority failure to refute. Findings that could
not be proven from a file:line were dropped. 344 agents, 0 errors.

Funnel: 117 raw -> 94 unique (by file:line) -> 58 survived, 36 refuted -> +2 from the completeness
critic = **60 final**. All 94 received a full 3-lens panel; 0 unverified. Route coverage 22/22.

Known limit of the method: dedup keyed on file:line and kept the first framing, discarding 8
same-line restatements. All 8 were traced; 7 were same-rule duplicates and the 8th
(`upgrade_success_screen.dart:73`, green vs icon-signature framing) survives under
`upgrade_success_screen.dart:39`. Nothing material was lost.

## Mechanical gate: PASS (4/4)

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 352/352 passed, goldens included |
| `dart run tool/gen_tokens.dart --check` | `tokens.g.dart` current |
| `bash tool/ci_greps.sh` | clean |

## What is already clean

Accent discipline, tokens, and the backend/privacy contracts. The client never writes `entitlement`,
`sessionsUsed`, or `usageMonth` outside the sanctioned `ensureUserDoc` create (create-only, server-
mandated defaults, enforced by firestore.rules). No score is computed client-side. No analytics
payload carries email, displayName, or transcript content. One near-miss is listed under v1.1
(`upgrade_screen.dart:45`, raw `?source=` into the PostHog payload).

The launch blockers are all mechanical truth: copy written ahead of the wiring.

---

**VERDICT: Not launch-ready. The purchase wall makes claims the code does not back — the Free column sells "live coaching hints" and a "7-day history" as Closer-only, and neither is gated anywhere. Fix `plan_catalog.dart` first: you are taking money for differentiators that do not exist.**

Spot-checked before finalizing: `plan_catalog.dart:22/27`, `upgrade_success_screen.dart:103`, `billing_config.dart:28-29`, `scenario_card.dart:228`, `scenario_preview_modal.dart:127` — all quoted evidence verbatim at the cited lines. Nothing dropped.

---

## MUST FIX BEFORE LAUNCH

**1. Purchase wall sells live coaching hints that Free already gets**
`lib/features/billing/domain/plan_catalog.dart:27` (also `:36`, `:47`, `session_limit_screen.dart:131`) · *Every promise mechanically true*
The Free column renders "Live coaching hints during calls" with a cross icon, but no entitlement gate exists anywhere in `lib/features/sim/` — `CoachingPanel` takes no entitlement param, and `LIVE_SCENARIOS` is empty by default so every session runs `ScriptedSimSession`, which emits coaching to everyone.
**Fix:** gate coaching server-side and document it, or delete the line from `kFreePlanExcludes` and drop the differentiator from `:36`, `:47`, and `session_limit_screen.dart:131`.

**2. Purchase wall invents a 7-day free history cap that nothing enforces**
`lib/features/billing/domain/plan_catalog.dart:22` (sold against by `:38`) · *Every promise mechanically true*
"7-day session history" is the only Free "include" that is a restriction, and no code truncates history by age — `progress_repository.dart:65` caps by session count, and `historyFixtures` serves rows labelled "1w ago"/"2w ago" to every tier.
**Fix:** replace with something true ("Post-call scoring and transcript") and drop the implied ceiling from `:38`, or implement the window server-side.

**3. "Manage or cancel anytime in Settings" — Settings cannot cancel**
`lib/features/billing/presentation/upgrade_success_screen.dart:103`; `lib/features/settings/presentation/delete_account_screen.dart:100`; (`settings_screen.dart:390` per critic) · *Every promise mechanically true*
`kRcManageBillingUrl` is a `String.fromEnvironment` with no default and is dart-defined nowhere in the repo, so `manageBillingConfigured` is false in every shipped build and Manage billing only prints "go find your receipt email."
**Fix:** point the copy at the receipt email until `RC_MANAGE_BILLING_URL` actually ships in the production build.

**4. "Resume" restarts from zero and burns a second free session**
`lib/core/widgets/scenario_card.dart:228`; `lib/features/library/presentation/scenario_preview_modal.dart:127` · *Every promise mechanically true*
The shipped fixture `door-knock-the-coopers` sets `inProgress: true`, but the tap routes to `SimController.start()`, which mints a fresh `requestId` and a new `startSimSession` grant — no resume path exists in `lib/features/sim/`, and the broker has no mid-call resume.
**Fix:** relabel both to "Start again" (or drop `inProgress: true` from the fixture) and let the dot carry the "you've been here" signal.

**5. Exit-confirm modal promises a score and a save that no code performs**
`lib/features/sim/presentation/sim_widgets.dart:748` · *Every promise mechanically true*
"It'll be scored against the shorter transcript and saved to My progress" is false on the default build: `ScriptedSimSession.end()` ignores the transcript and returns a hardcoded fixture id, and `sessionRepositoryProvider` is pinned to `FixtureSessionRepository`, which serves the same 78-overall doc for any id.
**Fix:** keep only what is backed ("This still counts as a session.") until live scenarios and the Firestore session repository are both wired.

**6. Practice preferences are write-only — the toggles change nothing**
`lib/features/settings/presentation/settings_screen.dart:275`, `:286`, `:299` · *Every promise mechanically true*
`settingsPrefsProvider` is read only inside `settings_screen.dart`; `app_router.dart:151` builds `const LibraryScreen()` so the audience default never applies, and every start path hardcodes `ColdCallSimRoute`, so selecting "Video" can never produce a video sim.
**Fix:** wire the prefs into `LibraryScreen(initialTrack:)` and the start paths, or remove the card — the Notifications card 50 lines below already models the honest "saved now, live later" copy.

**7. Methodology cards advertise scenarios that do not exist and a filter that does not filter**
`lib/features/methodologies/domain/methodology.dart:70` (counts also `:62/:78/:86/:94`); `lib/features/methodologies/presentation/methodologies_screen.dart:385` (+ Semantics `:372`) · *Every promise mechanically true*
The catalog claims 24 scenarios against a 10-scenario library (SPIN advertises 5 and has **zero** tagged), and "See scenarios using this →" calls `SimulationsRoute()`, which takes no params and lands on the unfiltered B2C grid.
**Fix:** derive `scenarioCount` from `scenarioFixtures` by tag (hide at 0) and either add a methodology filter param or downgrade the link to "Browse the library →".

**8. Aborted score screen asserts an unverified refund and the wrong cause**
`lib/features/scoring/presentation/score_screen.dart:156-157` · *Every promise mechanically true / aborted sessions never count*
One `Text` hardcodes "The connection dropped mid-session" for every abort (the only aborted fixture is `mic_failure`) and unconditionally claims "it does not count toward your monthly sessions" — while `SessionDoc` carries no refund field and the sibling `SimAborted` deliberately gates that exact sentence on `refundConfirmed == true`.
**Fix:** make the cause neutral ("This call ended before it could be scored") or branch on `doc.abortReason`, and add a server-written `refunded` flag before re-asserting the cap claim.

**9. Dashboard earnings figure drops the market-median framing and the source**
`lib/features/dashboard/presentation/dashboard_screen.dart:528` · *Earnings: market medians, always sourced*
"At your current skill level / $64K" personalizes the figure with no attribution; the card's only "per published comp data" string is scoped to the $85-95K next-tier claim, and both siblings (`progress_screen.dart:416`, `achievements_repository.dart:38`) source it correctly.
**Fix:** match the siblings — "Market median at your current skill tier, per published comp data."

**10. Dashboard hero asserts a computed "weakest skill" that nothing computes**
`lib/features/dashboard/data/dashboard_repository.dart:88` · *Every promise mechanically true*
"Your weakest skill right now is getting past gatekeepers" is a const string on a scenario selected by `recommendScenario()`, which switches on `answers.track` alone — and it is the `?? gatekeeperFeatured` fallback, so a user who skipped onboarding gets the claim with zero data behind it.
**Fix:** drop the analytic sentence (match `homeownerFeatured`, which makes no such claim) or compute it from the sorted skills.

**11. "Link sent." asserts a send that provably may not happen**
`lib/features/auth/presentation/reset_password_screen.dart:132` and `:49` · *Every promise mechanically true*
`AuthService.sendPasswordReset` deliberately swallows `user-not-found` for anti-enumeration, so an unregistered email reaches the sent state with no email sent — the body copy at `:136` hedges correctly ("If an account exists for…"), proving the headline and the resend notice drifted off it.
**Fix:** "Check your email." for the headline and "If that email has an account, the link is on its way." for the resend notice — both stay enumeration-safe.

**12. The sourced earnings sentence renders at 2.3:1 contrast**
`lib/features/progress/presentation/progress_screen.dart:421` · *dim1/dim2 are chrome only, never body copy*
A full sourced sentence ("Market median… per published comp data.") is styled `colors.dim1`, whose own token doc says "NOT body copy (2.37:1)" — and it is the one legally-required sourcing line on the screen.
**Fix:** `colors.dim1` → `colors.body`, matching `achievements_screen.dart:303` and `dashboard_screen.dart:575`.

---

## V1.1

**Icons — one decision, seven sites.** The root cause is quotable: `clos_icons.dart:9-11` states the signature as *"Any primary circle carries a single ~55 degree gap"*, narrower than CLAUDE.md's *"every custom icon"*. Fix the header first or the next circle-less icon inherits it.

- **v1.1** | `clos_icons.dart:125` (ProgressIcon), `:140` (MethodologiesIcon), `:190` (MailIcon), `side_nav.dart:399` (_ChevronPainter, renders on all 9 in-shell screens) | *exactly ONE -60° element* | All four are circle-less and measure **zero** -60° elements (bars at -90°, rules at 0°, envelope flap at ±36.3°, chevron at ±45°); the chevron is also on a 12x12 grid. | Shear one element onto the -60° axis per glyph and reconcile the file header with CLAUDE.md.
- **v1.1** | `clos_modal.dart:151` | *ONE -60° element, 15x15 viewBox, no one-off forks* | `_CrossPainter` draws a symmetric +45°/+135° X on a 12x12 grid, forking the compliant `CloseIcon` (measured -60.07°) that `billing_shell.dart:117` already uses for the same job. | Delete `_CrossPainter`; render `CloseIcon` inside the existing 44x44 Semantics wrapper.
- **v1.1** | `scenario_card.dart:125` | *15x15 viewBox; do not fork* | `_LockPainter` paints a 13x14 grid duplicating `LockIcon`, whose own doc comment names the duplication out loud. | Replace with `IconTheme.merge(…, child: const LockIcon())` and delete `_LockPainter` (golden regen needed).
- **v1.1** | `upgrade_success_screen.dart:39` and `:73` | *icons grayscale dim2→hi2 (streak flame excepted)* | `CheckIcon` painted `colors.green` — the only chromatic icon glyph in the codebase; the sibling badge at `session_limit_screen.dart:79` uses `hi2` on an identical 72x72 neutral container. | Paint `hi2`; carry complete-state green as a dot or text if needed.

**Accent + color**

- **v1.1** | `dashboard_screen.dart:220` | *ONE accent-filled element; accentDim = favicon / selection-state left borders / gradient start* | A 5x5 solid `accentDim` circle beside "Next session" is on none of the token's three permitted uses — it is the only accentDim *fill* in the codebase, and the file's own accent-audit comment doesn't account for it. | Recolor to `dim2`/`hi2`, or add the use to the token note in the site `design-tokens.json` and re-sync.
- **v1.1** | `progress_screen.dart:534` and `:312` | *Green only for positive deltas* | `delta >= 0` paints a zero delta green while the adjacent sign logic uses `> 0`, so a flat skill would render an unsigned green "0"; latent only because fixtures contain no zeros. | Route both through `DeltaPill`, which already does the correct tri-state (`> 0` green / `< 0` red / else `mid`).
- **v1.1** | `achievements_screen.dart:318` | *dim1/dim2 never body copy* | `milestoneNote` ("Next tier at objection handling 70%+.") renders `dim1` fifteen lines below `earningNote`, which correctly uses `body` — two annotation sentences, one card, two ramps. | `colors.dim1` → `colors.body`.

**Tokens**

- **v1.1** | `library_screen.dart:72` (+ `progress_screen.dart:81`, `achievements_screen.dart:91`, `methodologies_screen.dart:112`) | *NEVER hardcode a size* | `minHeight: 57` is a hand-measured snapshot of the Dashboard topbar's *intrinsic* height, duplicated in four screens; if the Dashboard type scale moves, the sidebar reflows and these silently do not. | Add a `topbar` height to `ClosLayout`, `bash tool/sync_tokens.sh`, read `context.closLayout.topbar`.
- **v1.1** | `sim_widgets.dart:14` and `:15` | *NEVER hardcode a size* | `kSimPanelWidth = 300` / `kSimPanelBreakpoint = 1100` re-declare `ClosLayout.coachingPanel` / `collapseBelow` — the same two fields the token JSON namespaces under `coachingPanel`, i.e. this exact widget. | Read `context.closLayout.*` at `sim_widgets.dart:450`, `cold_call_screen.dart:88`, `video_sim_screen.dart:98`.
- **v1.1** | `methodologies_screen.dart:47` and `:267` | *NEVER hardcode a size* | `maxWidth: 640` inlined twice, duplicating `ClosLayout.heroColumnMaxWidth` (640), which has zero call sites anywhere in `lib/`. | Use `context.closLayout.heroColumnMaxWidth` at both sites.
- **v1.1** | `session_limit_screen.dart:93` and `dashboard_screen.dart:352` | *Spacing only from the 4px scale* | Dot-strip gaps hardcoded to 6px and 3px; the analogous `MomentumDots` and `ClosBadge` both use `sp.sp2` for the identical construct. | Use `sp.sp1`/`sp.sp2` via the `if (i > 0) SizedBox(width: sp.sp2)` pattern.
- **v1.1** | `transcript_line.dart:78` | *Spacing only from the 4px scale* | The annotation badge's `vertical: 2` is the only raw spacing literal in `lib/core/widgets/`; `ClosBadge:22` and `DeltaPill:55` both use `sp.sp1`. | `vertical: sp.sp1` (regen the transcript_line golden).
- **v1.1** | `signup_screen.dart:237` | *token contract: minBodySize 12px; micro-labels ≥10px* | The terms/privacy sentence renders at 11.5px in the `body` token — the only sub-12px body-colored text in the repo; every other sub-12px site is an uppercase micro-label. | Raise both spans to 12px (`type.bodySmall`) or add an explicit fineprint role to the token source.
- **v1.1** | `upgrade_screen.dart:45` and `:60` | *Analytics: no free-form user content in a payload* | `?source=` is read raw from the URL (`app_router.dart:99`) and lands verbatim in the PostHog payload — `/upgrade?source=me@x.com` ships an email; the router already sanitizes its sibling `?from` param via `sanitizeFrom`. | Add an allowlist parse on `UpgradeSource` falling back to `direct`; all four in-app callers already pass consts, so nothing else changes.

**Components + copy**

- **v1.1** | `achievements_screen.dart:44` | *Screens assemble core widgets; do not fork* | Lines 44-66 hand-roll an error state (no AlertIcon, `headlineSmall` instead of `headlineMedium`) duplicating `DataLoadError` — the sole outlier among four data screens, and it bypasses the component's golden. | Replace with `DataLoadError(title: …, onRetry: () => ref.invalidate(achievementsDataProvider))`, mirroring `progress_screen.dart:50`.
- **v1.1** | `progress_screen.dart:389` | *Earnings copy / mechanically true* | `_TrendChip(text: '↑ 1 skill tier')` is a const inside a `const Row`, identical at 7D and All, while the card around it is range-filtered ($1K vs $24K) — and the model already carries the self-scoping `earning.tierDelta` ("1 skill tier this quarter"). | Drive it from `earning.tierDelta` or hide it for ranges where tier movement is undefined.
- **v1.1** | `achievements_repository.dart:135` | *Earnings: never personal predictions; always sourced* | The session-zero earning note ("Your starting point. This climbs as you practice.") predicts the user's own figure and drops the source, under an unsourced $40K market median. | "Entry-level market median, per published comp data." (test-only path today; ships the moment Firestore lands).
- **v1.1** | `upgrade_screen.dart:156` | *Low-pressure coaching voice* | "For reps actually trying to close their skill gaps" implies anyone on Free isn't trying — the only string on the billing surface that characterizes the reader rather than the product. | Drop the adverb: "For reps working on their skill gaps."

**Nits** (cosmetic or arguable; batch whenever the surrounding file is touched)

- `clos_icons.dart:217` — CheckIcon's rise stroke measures **-54.8°**, 5.2° off the axis its own docstring claims; every compliant sibling lands within 0.4°. Move the endpoint to `10.02 * u`, or correct the docstring.
- `streak_pill.dart:31` — flame paints a 12x14 grid, not 15x15; the flame exception is color-only. Re-cut onto the shared `_ClosIcon` host.
- `streak_pill.dart:92` — `strokeWidth = 1.3` is raw px and never scaled by the grid unit, so at `StatTile`'s size 16 it renders 1.14 units — under the 1.2 floor. Use `1.3 * w`.
- `progress_screen.dart:254` — `_TrendChip` is a pixel-level fork of `DeltaPill`; the fork is what let the zero-delta bug diverge. Extend `DeltaPill` and delete it.
- `library_screen.dart:150` — track caption in `dim1` (2.37:1) where every comparable description uses `body`. Borderline: verbless noun phrase.
- `auth_widgets.dart:138` — "OR" divider tracked at `0.04em`, below the 0.05-0.1em uppercase-label band; every other uppercase label uses 0.08. 0.11px of visual delta.
- `delete_account_screen.dart:213` — `EdgeInsets.only(top: 6)` optical nudge, off the 4px scale and uncommented. Add the comment or snap to `sp.sp1`.
- `category_score_card.dart:87` — `BorderRadius.circular(2)` inlines full rounding where `dashboard_screen.dart:469` uses `context.closRadius.full` for the identical 4px bar. Pixel-identical today.
- `clos_toggle.dart:60` — 36x20 toggle track takes the `full` radius; the value is tokenized, but a stadium is neither a circle nor a progress end-cap. Either bless it in the token note or accept it (it matches the prototype).
- `score_ring.dart:88` — caption floor is `math.max(size * 0.075, 9)`; the component's own default size (120) lands exactly on 9px, one under the 10px micro-label minimum. Unreachable in production (both callers pass 170 or omit the label). Raise the floor to 10.
- `onboarding_screen.dart:660` — "We picked your first scenario from your answers" is 1/3 backed: `recommendScenario` switches on `track` alone; `experience` and `focus` are persisted and never read. Narrow to "from what you sell."
- `achievements_repository.dart:197` — five mastery names are Title Case ("Objection Handler") while every sibling badge on the same screen is sentence case. Pick one.

---

**Sequencing note:** items 1-3 and 7 are all "the billing/catalog copy was written ahead of the wiring" — fix the copy or the wiring together, not one screen at a time. The v1.1 icon block is one design decision applied to seven sites; start with the `clos_icons.dart:9-11` header. Route coverage is complete (22 routes, all audited); `PlaceholderScreen` is confirmed dead code and can be deleted post-launch.

---

## Appendix: the 60 findings, unmerged

The ranked list above merges same-root-cause sites (the four `plan_catalog.dart` reference points
collapse into item 1). Per-site granularity, for fixing one file at a time:

| Severity | Site | Dimensions |
|---|---|---|
| must-fix | `lib/core/widgets/scenario_card.dart:228` | copy |
| must-fix | `lib/features/auth/presentation/reset_password_screen.dart:132` | copy |
| must-fix | `lib/features/billing/domain/plan_catalog.dart:22` | copy |
| must-fix | `lib/features/billing/domain/plan_catalog.dart:27` | copy |
| must-fix | `lib/features/billing/presentation/upgrade_success_screen.dart:103` | copy |
| must-fix | `lib/features/dashboard/data/dashboard_repository.dart:88` | copy |
| must-fix | `lib/features/dashboard/presentation/dashboard_screen.dart:528` | copy |
| must-fix | `lib/features/library/presentation/scenario_preview_modal.dart:127` | copy |
| must-fix | `lib/features/methodologies/domain/methodology.dart:70` | copy |
| must-fix | `lib/features/methodologies/presentation/methodologies_screen.dart:385` | copy |
| must-fix | `lib/features/progress/presentation/progress_screen.dart:421` | accent,containers,backend |
| must-fix | `lib/features/scoring/presentation/score_screen.dart:156` | copy |
| must-fix | `lib/features/scoring/presentation/score_screen.dart:157` | copy |
| must-fix | `lib/features/settings/presentation/delete_account_screen.dart:100` | copy |
| must-fix | `lib/features/settings/presentation/settings_screen.dart:275` | copy |
| must-fix | `lib/features/settings/presentation/settings_screen.dart:286` | copy |
| must-fix | `lib/features/settings/presentation/settings_screen.dart:299` | copy |
| must-fix | `lib/features/sim/presentation/sim_widgets.dart:748` | copy |
| v1.1 | `lib/core/widgets/clos_icons.dart:125` | icons |
| v1.1 | `lib/core/widgets/clos_icons.dart:140` | icons |
| v1.1 | `lib/core/widgets/clos_icons.dart:190` | critic |
| v1.1 | `lib/core/widgets/clos_modal.dart:151` | icons |
| v1.1 | `lib/core/widgets/scenario_card.dart:125` | icons |
| v1.1 | `lib/core/widgets/side_nav.dart:399` | critic |
| v1.1 | `lib/core/widgets/streak_pill.dart:95` | icons |
| v1.1 | `lib/core/widgets/transcript_line.dart:78` | containers,tokens |
| v1.1 | `lib/features/achievements/data/achievements_repository.dart:135` | copy |
| v1.1 | `lib/features/achievements/presentation/achievements_screen.dart:318` | accent,containers,backend |
| v1.1 | `lib/features/achievements/presentation/achievements_screen.dart:44` | accent,containers,backend |
| v1.1 | `lib/features/billing/presentation/session_limit_screen.dart:93` | accent,tokens |
| v1.1 | `lib/features/billing/presentation/upgrade_screen.dart:156` | copy |
| v1.1 | `lib/features/billing/presentation/upgrade_screen.dart:45` | backend |
| v1.1 | `lib/features/billing/presentation/upgrade_success_screen.dart:39` | icons |
| v1.1 | `lib/features/dashboard/presentation/dashboard_screen.dart:220` | accent,containers |
| v1.1 | `lib/features/dashboard/presentation/dashboard_screen.dart:352` | tokens |
| v1.1 | `lib/features/library/presentation/library_screen.dart:72` | tokens |
| v1.1 | `lib/features/methodologies/presentation/methodologies_screen.dart:267` | tokens |
| v1.1 | `lib/features/progress/presentation/progress_screen.dart:312` | accent,containers |
| v1.1 | `lib/features/progress/presentation/progress_screen.dart:389` | containers,copy,backend |
| v1.1 | `lib/features/progress/presentation/progress_screen.dart:534` | accent,containers |
| v1.1 | `lib/features/sim/presentation/sim_widgets.dart:1003` | copy |
| v1.1 | `lib/features/sim/presentation/sim_widgets.dart:14` | tokens |
| v1.1 | `lib/features/sim/presentation/sim_widgets.dart:15` | tokens |
| v1.1 | `lib/features/sim/presentation/sim_widgets.dart:955` | copy |
| nit | `lib/core/widgets/category_score_card.dart:87` | accent |
| nit | `lib/core/widgets/clos_icons.dart:217` | icons |
| nit | `lib/core/widgets/clos_toggle.dart:60` | tokens |
| nit | `lib/core/widgets/score_ring.dart:88` | tokens |
| nit | `lib/core/widgets/streak_pill.dart:31` | icons |
| nit | `lib/core/widgets/streak_pill.dart:92` | icons |
| nit | `lib/features/achievements/data/achievements_repository.dart:197` | copy |
| nit | `lib/features/auth/presentation/reset_password_screen.dart:49` | copy |
| nit | `lib/features/auth/presentation/signup_screen.dart:237` | tokens |
| nit | `lib/features/auth/presentation/widgets/auth_widgets.dart:138` | tokens |
| nit | `lib/features/library/presentation/library_screen.dart:150` | accent,containers |
| nit | `lib/features/methodologies/presentation/methodologies_screen.dart:47` | tokens |
| nit | `lib/features/onboarding/presentation/onboarding_screen.dart:660` | copy |
| nit | `lib/features/progress/presentation/progress_screen.dart:254` | containers |
| nit | `lib/features/settings/presentation/delete_account_screen.dart:213` | tokens |
| nit | `lib/features/sim/presentation/sim_widgets.dart:597` | copy |
