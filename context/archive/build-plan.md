# Closero Flutter Build Plan (2026-07-07)

Planning session output. Companion docs: `Closero — closero-app CLAUDE.md (2026-07-07).md` (drop into the new repo) and `Closero — Flutter Prompt Pack (2026-07-07).md` (session-by-session prompts + backend to-do).

## 0. Decisions locked today (supersede the handoff where they differ)

- **Flutter Web is v1.** iOS is second, Android third. Same codebase, three deploy targets. (Handoff said iOS-first; corrected by Osman 2026-07-07.)
- **Both sims ship in v1** (Cold Call + Video Sim). Manageable because Video Sim is a presentation swap on the same audio pipeline, not a second pipeline (see section 6).
- **Capacity:** full-time, ~35-40 hrs/wk.
- **Target:** first live build ~4 weeks out (early August). Since v1 is web, "TestFlight" becomes "deployed at app.closero.app behind EARLY_ACCESS."
- Repo: new `closero-app/` repo, separate from Current-Work. Shared backend (same Firebase project, same RevenueCat project), zero shared code.

## 1. Platform + package decisions

| Concern | Decision | Rationale |
|---|---|---|
| State management | **Riverpod 3** (flutter_riverpod + riverpod_annotation) | The app is mostly Firestore streams + derived state (entitlement, usage, session history). StreamProvider/AsyncNotifier map to that directly with far less ceremony than Bloc. Bloc's event rigor only pays off on the sim state machine, and a plain state-machine class inside a Notifier covers that. Solo dev: fewer files per feature wins. |
| Navigation | **go_router** (typed routes) | Declarative guards for auth + entitlement redirects. Deep links needed: `/score/:sessionId` and `/score/:sessionId/transcript?moment=<n>` (Key Moments deep-link into Transcript). Web URLs come free, which matters since v1 is web. |
| Firebase | firebase_core, firebase_auth, cloud_firestore, cloud_functions | Same project as the site. Same `users/{uid}` schema. App NEVER writes entitlement/sessionsUsed/usageMonth. |
| Billing (web v1) | **RevenueCat Web Purchase Links + Firestore entitlement reads. No purchases SDK in the web build.** | purchases_flutter does not support Flutter Web. The clean workaround: "Upgrade" opens the RC-hosted checkout URL with `app_user_id = Firebase uid`; the existing `revenuecatWebhook` function flips `users/{uid}.entitlement`; the app just watches that doc. Server truth was already the design, so the client SDK is optional anyway. |
| Billing (iOS later) | purchases_flutter (v9+), same RC project, `appUserID = uid` | Per the Auth/Billing plan. Wrap billing behind a `BillingService` interface now so the iOS build swaps implementations without touching screens. |
| Mic capture | **record** package (web-supported, streams PCM) | Streams 16kHz PCM chunks suitable for Deepgram. **Spike: Safari** mic permissions + AudioContext autoplay policy. |
| Audio playback | just_audio (web-supported) + a small streaming-audio shim for TTS chunks | TTS arrives as streamed audio; buffer-and-play with barge-in cancel. |
| Transport | web_socket_channel (WSS to the session broker) | One socket per live session. |
| STT | **Deepgram streaming** (nova family) | Already the named vendor: filler-word detection + endpointing are planned features. Confirm vendor name before it appears in Privacy. |
| TTS | **Azure Speech, standard neural voices** ($16/1M chars, 500K free/mo). Runs server-side in the broker | Cheaper than Deepgram Aura-2 ($30/1M) and emits **viseme events** (mouth-pose IDs + timestamps) that drive the Rive lipsync directly. Visemes are SDK-only (not REST), hence server-side TTS with the viseme timeline forwarded over the session socket. US-English-only visemes for now, fine for launch. |
| Roleplay LLM | **GPT-5.4 mini** ($0.75/M in, $4.50/M out) for turns, hints, and stats, with prompt caching on (persona prompt + growing transcript) | First-token speed + cost. Post-call scoring: test mini's rubric quality first; upgrading scoring alone to a stronger model is one pass per session and costs pennies. |
| Managed-pipeline alternative | **2-3 day spike, week 4, before hand-rolling**: OpenAI Realtime / Gemini Live, or LiveKit Agents / Pipecat | A managed realtime stack could delete most of the turn-taking code. Risks: less control over coaching-hint hooks, filler-word data, and cost. Timebox the spike; fall back to the hand-rolled sketch in section 6. |
| Avatars | rive (web ok via CanvasKit) | Rive layer sits on a PERMANENT gradient placeholder Stack (loading state + fallback, never replaced). |
| Local persistence | shared_preferences only (prefs, last-viewed filters) | Firestore is the source of truth; no offline-first complexity in v1. |
| Codegen/testing | build_runner, freezed, json_serializable; **alchemist** (or golden_toolkit) for golden tests; integration_test | Goldens are the drift guard against the prototype screenshots. |
| Web renderer/hosting | Default CanvasKit; deploy `build/web` to **Cloudflare Pages as a separate project → app.closero.app** | Keeps closero-site untouched. Grain, rings, and custom paint want CanvasKit. Initial load is a few MB; acceptable behind a login, add a branded loading shell. |

**Flagged spikes:** (1) Safari/Chrome mic + autoplay on Flutter Web, week 1, half a day. (2) Managed realtime vs hand-rolled pipeline, week 4, 2-3 days. (3) Rive lipsync driven by Azure viseme events, week 4, half a day: validate the `context/rive-contract.md` mapping table by eye against real Azure viseme output and tune `viseme_mapping.dart`.

## 2. Project structure (feature-first)

```
closero-app/
  CLAUDE.md                  ← the companion doc, repo root
  context/                   ← design-tokens.json copy, prototype screenshots,
                               canonical-mock-data.md (given to every session)
  tool/gen_tokens.dart       ← tokens JSON → Dart codegen (section 3)
  lib/
    core/
      theme/                 ← tokens.g.dart, ClosColors/ClosSpacing/ClosType/ClosRadius
      widgets/               ← the component library (section 4)
      services/              ← firebase, billing (interface + web impl), sim transport
      routing/               ← go_router config, guards (auth, entitlement)
      utils/
    features/
      auth/                  ← login, signup, reset, verify
      onboarding/            ← 6 steps + reveal
      dashboard/
      library/               ← grid, scenario preview modal (shared w/ dashboard)
      sim/                   ← session state machine, cold-call stage, video stage
      scoring/               ← post-call score, transcript view
      progress/
      achievements/
      methodologies/
      settings/
      billing/               ← upgrade screen, session_limit, upgrade_success
    main.dart
  test/goldens/              ← one golden per widget state + per screen
```

Each feature folder: `presentation/` (screens, feature widgets), `application/` (providers/notifiers), `domain/` (models), `data/` (repos) only where the feature actually has data.

## 3. ThemeExtension token foundation (build this first, nothing ships before it)

- `context/design-tokens.json` is a checked-in copy of `closero-site/design-tokens.json`. **Sync policy:** the site file is the source of truth; copy it over manually on change, then run codegen. A CI step hashes the checked-in copy against the generated Dart file so the two can never silently drift (fails the build if regen is needed). Web and app share the same JSON, so cross-platform drift is structurally impossible.
- `dart run tool/gen_tokens.dart` emits `lib/core/theme/tokens.g.dart`:
  - `ClosColors` ThemeExtension: every color token by name (base, surface, border, dim3-1, body, mid, hi2, hi1, accent, accentDim, green, warn, red, flame).
  - `ClosSpacing`: sp1..sp24 off the 4px scale. Rule helpers: `headlineToSubtext = sp3`, `sectionGap = sp6`.
  - `ClosRadius`: card 6, button 5, full (circles/end-caps only).
  - `ClosType`: full TextTheme enforcing **18px+ AND bold → Bricolage Grotesque, else Figtree** in the scale itself, so the 13-screen prototype drift can't recur. Letter-spacing: -0.02em titles, -0.01em buttons, 0.05-0.1em uppercase labels. Sentence case is a copy rule, not a code rule, but goldens catch it.
- Fonts self-hosted in `assets/fonts/` (copy the woff2/ttf from closero-site; Flutter wants ttf/otf, so export ttf once).
- GrainOverlay (2.5% noise) implemented once in core/widgets and applied by the app shell scaffold, not per-screen.
- Lint-level guard: a custom `avoid_hardcoded_colors` check (or a grep in CI: no `Color(0x` outside `tokens.g.dart`).

## 4. Widget library (~17 core components)

Build order within the library: primitives first (1-6), then data displays (7-13), then composites (14-19). Every component gets golden tests per state against prototype crops.

| # | Widget | States | Consumed by |
|---|---|---|---|
| 1 | ClosCard | default, inset (surface2) | every screen |
| 2 | PrimaryButton | default, hover-lift, pressed, disabled, loading | CTAs (the one accent fill per view) |
| 3 | GhostButton | default, hover, disabled | secondary actions everywhere |
| 4 | DestructiveButton | solid #B85F5F fill, white text (never a tinted wash) | settings danger zone |
| 5 | SideNav + UserCard | active (hi2 + 2px accentDim left border + faint tint), inactive (dim2→mid rest), hover; collapses on narrow web | app shell (no logo in sidebar) |
| 6 | ClosToggle | on/off, grayscale only, never accent | settings, library filter |
| 7 | StreakPill | count + flame (#C4915A, only place flame exists) | dashboard, progress |
| 8 | **MomentumDots** | 0-5 filled solid green, latest dot pulses, caption in mid ("3 strong moves this call. Full score at the reveal.") | both sims (footer). NEVER a live score mid-call |
| 9 | ScoreRing | animated sweep, color by threshold hi2 ≥75 / mid 60-74 / dim1 <60. **Never accent, anywhere** | post-call, progress, library best-score |
| 10 | HintCard | good/warn/miss = 3px green/warn/red left border, surface bg | sim coaching panel, post-call key moments |
| 11 | IncomeTrack | accentDim→accent gradient (the SOLE accent gradient in the system) | dashboard, progress, achievements |
| 12 | DeltaPill | up (green) / down (red); label logic: sessions 1-9 "vs last session", 10+ "vs 10-session avg" | post-call, progress |
| 13 | StatTile + SectionHeader | default, loading skeleton | dashboard, progress |
| 14 | EmptyState | icon + copy + optional ghost CTA | progress (one centered state, not 5 broken charts), library filters |
| 15 | ClosModal → ScenarioPreviewModal | open/close, methodology tags live HERE (never on cards) | library + dashboard, one shared scenario source |
| 16 | ScenarioCard | start, personal-best (accent only at "strong"), in-progress dot, **locked** (B2B/Methodologies on free) | library grid |
| 17 | TranscriptLine | rep/persona bubble, annotation green/warn/red text (no tinted chips) | transcript view, sim transcript tab |
| 18 | AvatarStack | gradient placeholder (art-1..N) base layer + optional Rive layer (mounted per `context/rive-contract.md`; the widget only hosts the layer, the state machine driver is its own session); placeholder is permanent | library cards, both sim stages |
| 19 | GrainOverlay | static 2.5% noise | shell |

Accessibility baked into the library, not retrofitted: `Semantics` labels on every icon-only control, 44px minimum tap targets enforced in the button/nav primitives, contrast per token usage rules (body copy = `body` token, never dim1/dim2).

## 5. Screen build order (sim pipeline last)

1. **Theme foundation** (section 3) — everything depends on it.
2. **Widget library** (section 4) — screens become assembly, goldens lock the visual contract early.
3. **App shell + routing + auth** — sidebar scaffold, go_router guards, login/signup/reset/verify against the live Firebase project. First end-to-end demo.
4. **Onboarding** — 6 steps, 1 question/screen, ~350ms auto-advance (needs a real-device/browser timing pass), reveal → single CTA to Dashboard (no auto-start). Writes displayName. No B2B/B2C jargon.
5. **Dashboard** — hero CTA + Skill Breakdown (weakest-first) + Earning Potential + Recent Sessions, on canonical mock data. Hero is NOT empty at session zero (onboarding pre-loads a scenario).
6. **Library + Scenario Preview Modal** — free = B2C, locked B2B cards route to upgrade. Modal shared with Dashboard.
7. **Settings + billing wall** — settings sections incl. the sub-pages that don't exist in the prototype (change password, delete account, connected accounts); upgrade screen, session_limit, upgrade_success; RC Web Purchase Link + Firestore entitlement watch; "Manage billing" → hosted portal.
8. **Progress + Achievements + Methodologies** — 7D/30D/90D/All must actually re-query all sections; one $ figure total in Achievements; methodologies are reference cards, no drill-down, gated.
9. **Scoring screens on mock data** — post-call score + full transcript (720px centered, read-only) + Key Moments deep links.
10. **Sim screens with faked conversation** — both stages (cold call audio-only + video full-screen stage w/ frosted topbar), coaching panel (Coaching tab default), momentum dots, scripted persona turns behind the real `SimSession` interface. `startSimSession` called from day one (v1 just increments) so the cap slots in with no client update.
11. **Real pipeline** (section 6) — cold call first, then the video stage rides the same pipeline.
12. **Analytics + funnel events** — one AnalyticsService (PostHog, uid-identified, no PII in payloads), event consts in one file, the full signup → onboarding → sim → cap_hit → upgrade → purchase funnel instrumented before launch. Monetization cannot be tuned blind.
13. **Error + edge states** — 404/unknown route (prototype has a 404; no screenshot exists, match shell style), mic-permission denied pre-call check, mid-call WSS reconnect then graceful abort (aborted sessions never count against the cap), TTS stall fallback to text, stream-error retry states. These protect the first-call experience, which is the conversion moment.

Justification: strict dependency order (nothing above needs anything below it), and every step ends in something demoable, which keeps a weekly-demo cadence honest. Sim last because it is the only unknown; everything else is deterministic assembly against a locked spec.

## 6. Sim pipeline architecture sketch (built last, designed now)

```
Flutter Web client
  mic (record, 16kHz PCM) ──WSS──► Session Broker ──► Deepgram streaming STT
  ◄──TTS audio chunks──┘   (Cloudflare Worker +      (partials, endpointing,
  barge-in: local VAD ►     Durable Object            filler words)
  cancel TTS playback       per session)                   │ final utterance
                                │                          ▼
                                │◄── stream ── Roleplay LLM (Haiku-class,
                                │              persona system prompt)
                                │ text chunks
                                ▼
                            Azure TTS (standard neural, streaming)
                            audio chunks + viseme timeline → client

  async, off the turn path:
    rolling transcript ──► Hint Analyzer (small LLM, every 1-2 utterances)
                           ──► good/warn/miss events ──► HintCard + MomentumDots
                           (a dot animates in per logged 'good' hint)
    call end ──► Scoring LLM (large model, rubric → JSON)
             ──► Cloud Function writes sessions/{id} + progress aggregates
             (scores are server-written; rules already block client forgery)
```

- **Why a broker, why Workers:** API keys never touch the client; Cloud Functions are weak at long-lived WebSockets, Workers + Durable Objects are built for them; you already run Cloudflare. Firebase stays the system of record; the DO holds only live-session state.
- **Latency budget per turn (target ≤1.3s, ceiling 2s):** endpoint detection ~300ms + LLM first token ~400ms + TTS first byte ~250ms + network ~150-300ms. Start TTS on first sentence boundary, don't wait for the full LLM reply.
- **Coaching guardrail:** every hint must be observable from audio/transcript only (voice, pacing, filler words, talk ratio, discovery questions). No body-language claims. Hint detection runs OFF the turn path so coaching never adds latency.
- **Cost-per-session model** (~12 min canonical, verified pricing 2026-07-07): Deepgram Nova-3 streaming ~$0.005-0.008/min × 12 ≈ $0.08; Azure TTS $16/1M chars × ~5K chars ≈ $0.08 (500K chars/mo free covers ~100 sessions early); GPT-5.4 mini ($0.75/M in, $4.50/M out, caching on) across turns + hints + scoring ≈ $0.05-0.10. **Total ~$0.20-0.30/session.** Free user's 5 sessions ≈ $1-1.50/mo worst case. Measure real numbers in week 4 before spending on acquisition (audit risk #2).
- **Video Sim delta:** same pipeline, zero new vendors. Swaps the stage widget: full-screen video stage, frosted topbar, blurred office bg (blur(3px) brightness(0.28) saturate(0.6) scale(1.06), no faces), Rive avatar lipsync driven by the Azure viseme timeline (viseme ID + audio offset mapped to Rive inputs). Accent: none (mic-on is cold-call's).
- **Rive rig contract + lipsync driver:** the avatar/asset interface is specified in `context/rive-contract.md` and it is binding: one state machine named `LipSync`, `viseme` Number input driving 8 mouth groups (rest, AA, EE, FF, LL, MM, OO, SS), `Blink`/`HalfBlink`/`Breath` Triggers running independently of mouth state, plus production-rig idle inputs (`Sway`, `Saccade`) once locked. The test rig validates this structure; the production rig keeps the exact names so the asset swap is a file drop with zero code change. Named deliverable: `lib/core/services/viseme_mapping.dart`, the ONE file mapping Azure viseme IDs 0-21 to the 8 rig groups, built once (own session, before the broker), referenced by LiveSimSession. Loading is via `StateMachineController` + SMI input handles, never the plain `RiveAnimation.asset` widget. Hard sync rule: viseme input updates are scheduled against just_audio's playback position per utterance, never against message-arrival time, because a sentence's visemes arrive over the socket before its audio is heard. Blink/breath (and idle life) run on their own randomized timers, fully decoupled from the viseme stream.
- **Interim stubs:** `SimSession` interface with `ScriptedSimSession` (canned persona turns, timed fake hints) and `LiveSimSession` (real pipeline). Screens bind to the interface, so step 10 → 11 is a swap, not a rewrite.

## 7. Risks (top 7, with mitigations)

1. **Both sims + real pipeline in 4 weeks.** Highest risk. Mitigation: video is a stage swap (above); the cut line, if week 4 slips, is video stage → v1.1 and ship cold call. Decide at the week-4 midpoint, not the deadline.
2. **Sim latency/cost.** Mitigation: managed-pipeline spike before hand-rolling; stream TTS on sentence boundaries; measure cost per session before scaling acquisition (free cap is 5 for now, re-check against measured COGS).
3. **Flutter Web platform quirks.** Safari mic permission, AudioContext autoplay, several-MB initial load. Mitigation: week-1 half-day spike on mic capture in Safari + Chrome; branded loading shell; app is behind login so load size is tolerable.
4. **Billing on web without purchases_flutter.** Mitigation: Web Purchase Links + webhook + Firestore watch (section 1). Test in Stripe test mode end-to-end (4242 card → entitlement flips → locked cards unlock live).
5. **App Store later (iOS second).** AI-content review, IAP rules, external-link entitlement. Mitigation: `BillingService` interface now; keep web checkout as the primary conversion funnel (you keep ~97% vs Apple's 70-85%); needs Apple Dev account lead time, start that account when iOS work begins.
6. **Solo-dev scope creep.** Mitigation: CLAUDE.md hard rules + one-feature-per-session protocol + the prompt pack's fixed verification step; anything not in the 24-screen contract is v1.1 by default.
7. **Persona content quality.** Free B2C library is the hook and the 6 personas are illustrative. Mitigation: schedule the content pass in week 3 (it needs no code) alongside real comp data for earnings figures; both are writing tasks Claude can draft against the earnings-framing rules.

## 8. Week-by-week (4 weeks, full-time, web target)

**Week 1: foundation.** Repo + CI (analyze, tests, token-hash check), token codegen + ThemeExtensions, fonts, grain shell; widget library with goldens (~17 components); app shell + go_router + auth screens live against the shared Firebase project. Safari mic spike (half day). Demo: sign up on web, land in a fully themed empty shell.

**Week 2: the browsable app.** Onboarding (6 steps + reveal), Dashboard, Library + Scenario Preview Modal, empty states wired to a real `sessionCount === 0` check. Demo: new user onboards and browses the free B2C library, locked Closer cards route to upgrade.

**Week 3: money + mock loop.** Settings (incl. new sub-pages) + billing (RC + Stripe accounts, Web Purchase Links live in test mode, entitlement watch); Progress/Achievements/Methodologies; post-call Score + Transcript on canonical mock data; `startSimSession` v1 deployed and wired; both sim screens running `ScriptedSimSession` with momentum dots. B2C persona content pass + comp data (writing, parallel). Demo: full loop with a faked call, hit the 5-cap, upgrade with a test card, cap lifts.

**Week 4: the real thing.** Managed-vs-hand-rolled spike (timeboxed 2-3 days), then the cold-call pipeline (broker + Deepgram + roleplay LLM + TTS + barge-in), hint analyzer → dots, real scoring writes, video stage on the same pipeline, deploy to app.closero.app behind EARLY_ACCESS. Demo: a real conversation with Sandra-Voss-grade fixtures replaced by live data.

Realistic caveat: week 4 is where plans die. Weeks 1-3 are deterministic; if the pipeline spills into weeks 5-6 you still have a complete, sellable app with a scripted sim to show early-access users. Ongoing newsletter time: budget the Resend welcome broadcast + one weekly email out of Friday afternoons; it does not block any of the above.
