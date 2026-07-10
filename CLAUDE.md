 CLAUDE.md: closero-app

> Copy this file to the ROOT of the new `closero-app/` repo as `CLAUDE.md`. Every Claude Code session reads it automatically. It is the condensed law; the full spec lives in Notion ("Closero Design System & Screen Notes" + "Development Notes") and `context/`.

## What this is

Closero: AI sales-training SaaS. Reps practice sales calls against AI personas, get live coaching + post-call scoring. This repo is the Flutter app. **v1 target is WEB** (deployed to Cloudflare Pages at app.closero.app); iOS is second, Android third. Same Firebase + RevenueCat backend as the live site (closero.app). Separate repo from the site; shared backend, never shared code.

The Closero site repo path is /Users/osmansiddiqi/Desktop/Closero/UI/Current Work. includes prototypes of the site and app, however closer-site is what is actually deployed live as my official site.

## Design token sync (single source of truth)

- The source of truth for design tokens is the closero-site copy: `/Users/osmansiddiqi/Desktop/Closero/UI/Current Work/closero-site/design-tokens.json`.
- `context/design-tokens.json` in this repo is a checked-in copy. Never edit it directly. To change a token: edit the site file, then run `bash tool/sync_tokens.sh` here. The script copies the site file in, reruns `dart run tool/gen_tokens.dart`, and runs the token contract tests. If the site repo ever moves, set `CLOSERO_SITE_TOKENS` to the new path.
- Commit `context/design-tokens.json` and `lib/core/theme/tokens.g.dart` together. CI's `gen_tokens --check` step fails the build if the generated file is stale.
- Both repos keep real checked-in copies because GitHub Actions and Cloudflare Pages build off this machine. Never symlink the two files.

## Hard rules (violating any of these is a bug, not a style choice)

### Tokens and theme
- NEVER hardcode a color, size, radius, or font. Everything comes from the ThemeExtensions in `lib/core/theme/tokens.g.dart`, generated from `context/design-tokens.json`. If a value you need is missing, stop and say so; do not inline a hex.
- `Color(0x...)` may appear ONLY in `tokens.g.dart`. CI greps for this.
- Type rule enforced in the type scale: 18px+ AND bold = Bricolage Grotesque; everything else = Figtree. Never override per-widget.
- Spacing only from the 4px scale (sp1..sp24). Headline→subtext = sp3 (12px), section→next section = sp6 (24px), always.
- Radii: cards 5-6px, buttons 5px. Full rounding only on circles + progress end-caps.
- Grain overlay (2.5% noise) is applied by the app shell. Do not add per-screen.

### Accent discipline
- ONE accent-filled element per view, maximum. Permitted uses ONLY: primary CTA fill, live-call mic-on control, pricing recommended-tier highlight, app icon, income-track gradient (accentDim→accent).
- Score/progress rings are NEVER accent, anywhere. Rings color by threshold: hi2 ≥75, mid 60-74, dim1 <60.
- No tinted-chip containers: never fill a badge/pill/tag/callout with a semantic color-wash + matching translucent border. Neutral surface + neutral border; state is a solid dot, solid icon badge, colored text, or a 3px colored left edge.
- Destructive buttons: solid #B85F5F fill (the `destructive` role), white text. Never a red-tinted wash.
- Ghost buttons: transparent, border2 border, mid text. Never accent.
- Toggles: grayscale only.
- dim1/dim2 are chrome only, NEVER body copy. Real sentences use the `body` token.

### Copy voice (applies to every user-facing string)
- **No em dashes, ever.** Use a period, comma, or colon. CI greps lib/ strings for `—`.
- Sentence case (short inline badges excepted). No ALL CAPS headings.
- No combat/fighter/locker-room metaphors.
- Low-pressure coaching voice. Every promise mechanically true: if copy says an email is sent, a system sends it.
- Membership naming: "Day One" (never "founding member/founding price").
- Value prop: "Where reps become closers." Tagline pair: "Practice the call before it costs you the deal."
- Earnings figures: market medians/ranges at a skill tier, never personal predictions; always sourced ("per published comp data"); deltas are skill-tier movement, never personal $ deltas; ranges beat point claims.

### Sim + scoring rules
- NO live score mid-call. Momentum dots only: 5-dot footer, solid green fills for strong moves, latest dot pulses, caption in mid. A dot animates in per logged 'good' coaching hint.
- Coaching hints must be observable from audio/transcript only (voice, pacing, filler words, talk ratio). No body-language/CV claims.
- Post-call delta: sessions 1-9 compare "vs last session"; 10+ use the 10-session rolling average.
- Cold Call: no sidebar, audio-only avatar, Coaching tab is the default (not Transcript), accent = mic-on only.
- Video Sim: same coaching panel, full-screen stage, frosted topbar, blurred office bg, accent = none.

### Backend contracts
- Same Firebase project as web. `users/{uid}`: email, displayName, entitlement 'free'|'closer', rcAppUserId=uid, usageMonth 'YYYY-MM', sessionsUsed, createdAt, updatedAt.
- The client NEVER writes entitlement, sessionsUsed, or usageMonth. Reads only. Those flip via the RevenueCat webhook / Cloud Functions.
- Every sim start goes through the `startSimSession` callable, from day one, even while it only increments. The client never decides the cap.
- Session scores are server-written. The client displays; it never computes-and-saves a score.
- Billing on web: RevenueCat Web Purchase Links (URL carries app_user_id = Firebase uid) + Firestore entitlement watch. purchases_flutter arrives only with the iOS target, behind the existing BillingService interface.
- Analytics: every product event goes through the single `AnalyticsService`; event names are consts in one file (`lib/core/services/analytics_events.dart`), never inline strings. Identify by Firebase uid only; no email, displayName, or transcript content in any event payload. `purchase_succeeded` fires from the entitlement flip in Firestore, never from the checkout click.
- Failed/aborted sim sessions (socket drop, mic failure) never count against the free cap and never produce a score. Honest copy, no fake partial score.

### Components and screens
- Screens assemble `lib/core/widgets/` components; do not fork one-off variants. If a screen needs a new state, add it to the component with a golden test.
- Rive avatars sit on a permanent gradient placeholder Stack. The placeholder is the loading state AND the fallback; it is never removed.
- Rive rig contract (`context/rive-contract.md`) is binding. State machine name is LOCKED: `LipSync`. Input names are LOCKED and case-sensitive: `viseme` (Number, 8 mouth groups), `Blink` / `HalfBlink` / `Breath` (Triggers, independent of mouth state), plus the production idle inputs once locked there. Any replacement .riv must conform; app code never renames inputs to fit an asset.
- Rive assets load via `StateMachineController` + SMI input handles. Never the plain `RiveAnimation.asset` widget (no input handles). Missing state machine or input = fall back to the placeholder, never crash.
- The Azure-viseme-ID to mouth-group mapping lives ONLY in `lib/core/services/viseme_mapping.dart`. No inline viseme maps anywhere else.
- Viseme input updates are scheduled against audio playback position (just_audio position stream, per utterance), NEVER against event-arrival time. Blink/breath/idle run on their own timers, decoupled from the viseme stream.
- Library: free tier = B2C library, Closer = B2B + Methodologies. Locked cards route to the upgrade screen. Methodology tags appear ONLY in the Scenario Preview Modal, never on cards. Completion = personal-best score or "Start", never a checkmark.
- Accessibility is not optional: Semantics on every icon-only control, 44px minimum tap targets (enforced in the primitives), body copy contrast per token rules.
- Icon signature: every custom icon has exactly ONE -60° element (gap or shear), 15x15 viewBox, 1.2-1.5 stroke, round caps, grayscale dim2→hi2 (streak flame excepted). Circles under r≈2.5 stay closed. Rings exempt (functional).
- Wordmark/icon geometry is LOCKED. Recolor or add container chrome only; never redraw. Wordmark appears only in onboarding (hero 400px, topbar 60px). Icon (ring alone, accentDim, 18px) on no-sidebar screens. Sidebar has no logo.

## Canonical mock data (fixtures; any screen disagreeing is a bug)

Sandra Voss · 9-day streak · $64K current, $40K-$150K range, $85-95K next tier ("per published comp data") · ~12 min scenario · 47 sessions.

## Verification (run before declaring any task done)

1. `flutter analyze` clean.
2. `flutter test` including goldens; new/changed widgets get goldens per state, compared against `context/prototype-screens/` crops.
3. `dart run tool/gen_tokens.dart --check` (token hash matches; regen was not skipped).
4. Greps: no `Color(0x` outside tokens.g.dart; no `—` in lib/; no "founding"; no retired gold hexes (E8D5A3, A89060, and rgba forms 232,213,163 / 168,144,96).
5. Accent audit on any touched screen: count accent-filled elements, must be ≤1 and on the permitted list.
6. If copy changed: sentence case, no combat metaphors, promises mechanically true.

## Session protocol

One feature per session. Read `context/` before writing code. State which prototype screen(s) you are matching. Do not start the next feature in the same session. If a spec question is not answered by this file or `context/`, ask; do not invent.
