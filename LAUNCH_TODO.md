# Launch TODO

Manual (non-code) work outside the prompt-building track. None of this blocks writing
Session 14+ prompts. Grouped by when it actually bites. Last reviewed 2026-07-13.

## Done (Session 14 live-scored-call prereqs)

- [x] Broker deployed and live (`closero-session-broker`, version `b0a065de`, 2026-07-13).
- [x] Firebase service account secret set (`FIREBASE_SERVICE_ACCOUNT_JSON`; code + docs
      aligned to that exact name, redeployed).
- [x] Firestore composite index created and verified: `sessions` (uid ASC, status ASC,
      endedAt DESC), COLLECTION scope.

## Before real (paying) users — the launch gate

- [~] **Firebase Auth authorized domains.** (Verified in console 2026-07-13.)
      DONE: `app.closero.app` is authorized (production domain covered). `localhost` works.
      STILL OPEN: the app's OWN `*.pages.dev` preview domain is NOT authorized. The
      `closero.pages.dev` entry present is the marketing-SITE project's preview domain, not
      this app's. Per context/hosting-and-auth.md the app is a SEPARATE Pages project with
      a distinct `*.pages.dev` (e.g. `closero-app.pages.dev`). That subdomain only exists
      once the app's Pages project is created (deploy step), then add it here or preview
      sign-in fails silently. (Session 4)
- [ ] **Cloudflare Pages `_redirects` SPA fallback.** Add `/* /index.html 200` so deep
      links like `/score/:sessionId` survive a refresh. Required: the app uses path URL
      strategy. (Session 4)
- [ ] **Broker: move off Cloudflare free plan to Workers Paid ($5/mo)** before real
      traffic. The broker relies on Durable Objects; free plan is fine for own testing
      only. (broker-worker-setup)

## Analytics (PostHog, Session 15)

- [x] **Create the PostHog account + project.** (Done 2026-07-14.) US cloud, org "Closero",
      project "Default project" (id 509099). Project API key (publishable, safe in the bundle):
      `phc_DkzgF5jDvacTUAnT7xPvB47sbYdBPkfTWP5hXvPqSPcs`. Consider renaming the project to
      "Closero app" in PostHog settings.
- [x] **Build the activation funnel + dashboard.** (Done 2026-07-14 via the PostHog MCP.)
      Funnel "Activation → Purchase" (`https://us.posthog.com/project/509099/insights/jYz1ZHrN`)
      on the pinned "Closero — Launch metrics" dashboard
      (`https://us.posthog.com/project/509099/dashboard/1848034`). Both are EMPTY until a build
      ships with the key set (below). Note: the funnel includes `cap_hit` as a step, so it
      measures the cap-driven upgrade path specifically; a large drop at `cap_hit` is expected.
- [ ] **Pass the key on every PRODUCTION build.** Analytics stays dark (the no-op service,
      zero events) unless the web bundle is compiled with
      `--dart-define=POSTHOG_API_KEY=phc_...`. Unlike `RC_PURCHASE_LINK`, there is NO baked-in
      default, on purpose (a key does not belong in source). The production build command
      lives in the app's Cloudflare Pages project, which does NOT exist yet (same separate
      Pages project as the auth-domain note above, lines 16-23; created at the Session 17
      deploy step) -- so wait until then to wire it. Cleaner form: store the key as a Pages
      env var and use `--dart-define=POSTHOG_API_KEY=$POSTHOG_API_KEY`. Local test builds need
      the same flag on your own `flutter build web` / `flutter run`.
- [ ] **Add PostHog to the Privacy policy vendor / sub-processor list** before public launch.
      It processes product-usage events keyed by the Firebase uid (no email, name, or
      transcript content). Part of the attorney ToS/Privacy pass. (launch gate)

## Hard calendar deadline

- [ ] **Node 20 runtime decommissioned 2026-10-30.** Upgrade both Cloud Functions groups
      in `closero-backend` to Node 22 and bump `firebase-functions` (currently `^6.1.0`,
      already flagged outdated). Affects the sim-cap callables (`startSimSession` /
      `abortSimSession`) AND the RevenueCat webhook. Expect breaking changes; do it as a
      deliberate maintenance pass. (backend-sim-cap-functions, Session 8)

## Optional but smart (verification / proof)

- [ ] **RevenueCat end-to-end money-path proof:** a real sandbox purchase or "Send test
      event" from RC. Webhook is deployed and verified against a test event, but a true
      purchase flip is the only definitive proof before pointing real buyers at the live
      CTA. (Session 8)
- [ ] **Broker real-vendor smoke test:** `npm run dev` with real keys in `.dev.vars`, or
      test against the deployed worker with a real Firebase token. Validates the
      Deepgram/Azure/OpenAI wire protocols against live services (the fakes only prove the
      broker's own protocol). Session 14 exercises this anyway. (Session 13)
- [ ] **Sim-cap functions on the Firestore emulator.** Currently tested against an
      in-memory fake, not the emulator (no Java on this Mac). Low priority.
      (backend-sim-cap-functions)
- [ ] **Safari autoplay (real browser).** The first TTS utterance plays on `utteranceEnd`,
      not on the Start tap, so Safari may block it; may need silent-play priming. Verify on
      real Safari (couldn't test headlessly). (Session 14)
- [ ] **Mic sample rate (real browser).** Confirm `record` delivers 16kHz PCM16 to
      Deepgram on both Chrome and Safari. (Session 14)

## Verified at code level (no action, recorded for confidence)

- [x] **Grant-doc contract matches** (checked 2026-07-13). `startSimSession` writes
      `users/{uid}/simSessions/{requestId}` with `{counted, month, grantedAt}`; the broker's
      hello check only needs existence, and its refund path reads `counted`/`month` -- field
      names align. Session 14 hard block #1 resolved short of a live call. (Session 14)
- [x] **Broker content scenarioIds match the app** (checked 2026-07-13). Broker ships
      personas for `cold-call-skeptical-homeowner`, `cold-call-saas-gatekeeper`,
      `discovery-roi-first-marcus` -- all real app scenario IDs; the latter two are the docs'
      example `LIVE_SCENARIOS`. Session 14 hard block #2 resolved. (Session 14)

## Known honest-copy debt (backend, not urgent)

- [ ] **Server-side user-doc cleanup on account delete.** The delete flow only blanks
      `email` / `displayName` client-side and removes the Auth user; no server hook purges
      the Firestore doc or auto-cancels the Closer subscription (the delete screen honestly
      says so). Future backend task, not a blocker. (Session 8)
