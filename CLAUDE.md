# CLAUDE.md: closero-app

> The condensed law for this repo. Fuller specs live in `context/` (binding: scoring-rubric.md, rive-contract.md, design-tokens.json, canonical-mock-data.md) and Notion. `context/archive/` is history only; never treat it as current. Open work: LAUNCH_TODO.md and `context/open-findings.md`.

## What this is

Closero: AI sales-training SaaS. Reps practice sales calls against AI personas, get live coaching + post-call scoring. This repo is the Flutter app. **v1 target is WEB** (deployed to Cloudflare Pages at app.closero.app); iOS is second, Android third. Same Firebase + RevenueCat backend as the live site (closero.app). Separate repo from the site; shared backend, never shared code.

Sibling repos (this repo lives, or is about to live, next to them in `.../Desktop/Closero/All Work July 2026/Current Work/`): `closero-site` (the live marketing site, source of truth for design tokens), `closero-backend` (Cloud Functions + firestore.rules), `closero-broker` (the live-call Worker). Other folders there are old prototypes; ignore them. `tool/sync_tokens.sh` finds the site as a sibling first, then by absolute path, then `CLOSERO_SITE_TOKENS`.

## Design token sync (single source of truth)

- The source of truth for design tokens is the closero-site copy: `/Users/osmansiddiqi/Desktop/Closero/All Work July 2026/Current Work/closero-site/design-tokens.json`.
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
- The grain overlay was REMOVED 2026-07-16 (looked bad, cost latency). Do not re-add noise anywhere; whether any texture returns is a UI-overhaul decision.

### Accent discipline
- ONE accent-filled element per view, maximum. Permitted uses ONLY: primary CTA fill, live-call mic-on control, pricing recommended-tier highlight, app icon, income-track gradient (accentDim→accent).
- Score/progress rings are NEVER accent, anywhere. Rings and bars color by threshold: hi2 ≥75, mid 60-74, dim1 <60. Score TEXT on cards/lists uses the scoreText ramp instead: green ≥75, hi2 60-74, mid <60 (helpers: `scoreThresholdColor` / `scoreTextColor` in score_ring.dart; never inline the thresholds).
- Green is for: positive deltas, coaching good state, momentum dots, live/complete status, and personal-best score text at 75+. Nothing else.
- Small-caps section labels are dim2 (SectionHeader label variant), not dim3/dim1.
- Persona avatar art: vertical gradient from an artX token (artViolet/artUmber/artMoss/artSlate, or surface2 for neutral) to base, faint dim3 initials on top. Tints are decorative only, chosen per persona, never semantic.
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
- Scoring contract (`context/scoring-rubric.md`) is binding: five locked category keys (objections, discovery, closing, rapport, tonality), hard stats computed server-side and never invented by the LLM, income tiers confirmed by the 5-of-last-7 consistency rule. Streaks NEVER influence a skill score or the income tier; streak rewards are access-based (bonus session, unlock) and server-granted.
- Cold Call: no sidebar, audio-only avatar, Coaching tab is the default (not Transcript), accent = mic-on only.
- Video Sim: same coaching panel, full-screen stage, frosted topbar, blurred office bg, accent = none.

### Backend contracts
- Same Firebase project as the site. `users/{uid}`: email, displayName, entitlement 'free'|'closer', rcAppUserId=uid, trialEndsAt, usageMonth 'YYYY-MM', sessionsUsed, usageDay 'YYYY-MM-DD', sessionsUsedDay, capEmailMonth, createdAt, updatedAt.
- The client NEVER writes entitlement, trialEndsAt, sessionsUsed, usageMonth, usageDay, or sessionsUsedDay. Reads only. Those flip via the RevenueCat webhook / Cloud Functions, and firestore.rules enforce it.
- Reverse trial (pricing doc 2026-07-11): `entitlement` stays the PAID state; access is the derived tier (closer if paid OR now < trialEndsAt) via `effectiveTierProvider` / `planPhaseProvider`. Gates read the derived tier; purchase-flip listeners and purchase analytics read raw entitlement. Plan facts (caps, prices) live only in `plan_catalog.dart` and must match `limits.js` in closero-backend.
- Every sim start goes through the `startSimSession` callable, from day one. It BLOCKS at the per-phase cap (verified live 2026-07-16); the client never decides the cap.
- Session scores are server-written. The client displays; it never computes-and-saves a score.
- Billing on web: RevenueCat Web Purchase Links (URL carries app_user_id = Firebase uid) + Firestore entitlement watch. purchases_flutter arrives only with the iOS target, behind the existing BillingService interface.
- Analytics: every product event goes through the single `AnalyticsService`; event names are consts in one file (`lib/core/services/analytics_events.dart`), never inline strings. Identify by Firebase uid only; no email, displayName, or transcript content in any event payload. `purchase_succeeded` fires from the entitlement flip in Firestore, never from the checkout click.
- Failed/aborted sim sessions (socket drop, mic failure) never count against the free cap and never produce a score. Honest copy, no fake partial score.

### Components and screens
- Screens assemble `lib/core/widgets/` components; do not fork one-off variants. If a screen needs a new state, add it to the component with a golden test.
- Rive avatars sit on a permanent gradient placeholder Stack. The placeholder is the loading state AND the fallback; it is never removed.
- Rive rig contract (`context/rive-contract.md`) is binding (amended 2026-07-13 to the verified rig). State machine name is LOCKED: `LipSync`. The mouth is data-binding-driven: view model `AvatarVM`, Number property `viseme` (8 mouth groups: 0 rest, 1 AA, 2 EE, 3 MM, 4 FF, 5 OO, 6 LL, 7 SS). Blinks are LOCKED lowercase inputs: `blink` (Trigger), `halfBlink` (Number hold: 1 held, 0 released). Breathing is autonomous in the rig, no input. Any replacement .riv must conform; app code never renames handles to fit an asset.
- Rive assets load via `RiveWidgetController` + `dataBind(DataBind.auto())`, holding the `AvatarVM.viseme` property and input handles. Never the plain `RiveAnimation.asset` widget. Missing file, state machine, view model, or handle = fall back to the placeholder, never crash.
- The Azure-viseme-ID to mouth-group mapping lives ONLY in `lib/core/services/viseme_mapping.dart`. No inline viseme maps anywhere else.
- Viseme input updates are scheduled against audio playback position (just_audio position stream, per utterance), NEVER against event-arrival time. Blink/breath/idle run on their own timers, decoupled from the viseme stream.
- Library: effective free tier = B2C only; trial and Closer get B2B + Methodologies (gates read `effectiveTierProvider`, never raw entitlement). Locked cards route to the upgrade screen. Methodology tags appear ONLY in the Scenario Preview Modal, never on cards. Completion = personal-best score or "Start", never a checkmark.
- Accessibility is not optional: Semantics on every icon-only control, 44px minimum tap targets (enforced in the primitives), body copy contrast per token rules.
- Icons are OUT OF SCOPE until the UI overhaul: do not add, redraw, or "fix" icon glyphs, and do not enforce or flag the old "-60° signature" rule (it was struck 2026-07-16; it never matched the mark's real geometry and will be rewritten with the overhaul). Still binding meanwhile: 15x15 viewBox, 1.2-1.5 stroke, round caps, grayscale dim2→hi2 (streak flame excepted), rings exempt (functional).
- Wordmark/icon geometry is LOCKED. Recolor or add container chrome only; never redraw. Wordmark appears only in onboarding (hero 400px, topbar 60px). Icon (ring alone, accentDim, 18px) on no-sidebar screens. Sidebar has no logo.

## Secrets and API keys

- Never paste keys into chat, code, CLAUDE.md, or `.gitignore` itself. `.gitignore` only lists the FILES that hold secrets; it is committed.
- Server-side secrets (RESEND_API_KEY, RC_WEBHOOK_SECRET) live in Google Secret Manager only: `firebase functions:secrets:set <NAME>` in closero-backend. Never on disk.
- Local build-time keys (e.g. the PostHog key) go in `.env` (gitignored; `.env.example` documents the expected names). Reference them by name; read values from the file at build/run time.
- Anything compiled into the web client (`--dart-define`) is readable by end users. Only publishable keys client-side; real secrets stay server-side.

## Canonical mock data (fixtures; any screen disagreeing is a bug)

Sandra Voss · 9-day streak · $64K current, $40K-$150K range, $85-95K next tier ("per published comp data") · ~12 min scenario · 47 sessions.

## Verification (run before declaring any task done)

1. `flutter analyze` clean.
2. `flutter test` including goldens (locally goldens run by default; CI push/PR runs `flutter test --exclude-tags golden` since golden pixel comparison is platform-sensitive and only reliable on the OS that generated the reference images). New/changed widgets get goldens per state, compared against `context/prototype-screens/` crops. Run goldens manually via the "Golden tests" GitHub Actions workflow (`workflow_dispatch`, with an `update` option to regenerate the CI-variant PNGs on Linux) whenever you want to check them against the actual CI environment.
3. `dart run tool/gen_tokens.dart --check` (token hash matches; regen was not skipped).
4. Greps: no `Color(0x` outside tokens.g.dart; no `—` in lib/; no "founding"; no retired gold hexes (E8D5A3, A89060, and rgba forms 232,213,163 / 168,144,96).
5. Accent audit on any touched screen: count accent-filled elements, must be ≤1 and on the permitted list.
6. If copy changed: sentence case, no combat metaphors, promises mechanically true.

## Session protocol

One feature per session. Read the relevant `context/` docs before writing code (skip `context/archive/`). State which prototype screen(s) you are matching. Do not start the next feature in the same session. If a spec question is not answered by this file or `context/`, ask; do not invent.

When necessary, always use Context7 when I need library/API documentation, code generation, setup, or configuration steps without me having to explicitly ask.