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
- [ ] **Site to app funnel does not exist yet (SITE repo work).** Verified 2026-07-14
      against the deployed site: `app.closero.app` is referenced on ZERO pages and has no
      DNS record, so on the day the app deploys the funnel still cannot reach it. Per
      `context/hosting-and-auth.md:15-23` the Flutter app owns auth (Firebase persists per
      origin, so a session on closero.app does NOT carry to app.closero.app): the site's
      buttons must become plain links to `https://app.closero.app`, and the site's own
      `login.html` / `signup.html` / `app.html` get retired. Cannot be done from a Claude
      Code session in this repo (macOS TCC blocks `~/Desktop`, so the site repo is
      unreadable here). (Session 17 research)
- [ ] **Decide EARLY_ACCESS for the APP (launch week).** The site's flag
      (`assets/js/firebase-init.js:52`, mirrored at `context/js/firebase-init.js`) only
      toggles site COPY: it hides `.when-launched` so the early-access landing + waitlist
      form shows instead of the full marketing site. It gates NOTHING (the site's
      login/signup never read it; anyone can make an account today), and it has no reach
      into the app's origin, so there is no mechanism for the app to be "consistent" with.
      Not urgent while the app stays unlinked. Pick at launch week alongside the Resend
      waitlist broadcast: (a) do nothing, rely on the unlisted URL; (b) Cloudflare Access
      in front of app.closero.app (real gate, zero app code, email allowlist/OTP); (c) a
      server-side allowlist checked at sign-in against the Firestore `waitlist` collection
      (real gate, backend work). See `context/session-17-prompts.md`. (Session 17 research)

## Before flipping any scenario to LIVE (the live-call gate)

Neither of these blocks DEPLOYING the app: it ships scripted by default, and the
Session 16 edge states (mic preflight, reconnect, abort/refund) only activate for a
scenario on `LIVE_SCENARIOS` with `BROKER_WSS_BASE` set. They bite the moment a real
user takes a live call.

- [ ] **`abortSimSession` must return `{refunded: bool}`.** The client now calls the
      callable on every post-grant technical failure, and shows the "it didn't count
      against your sessions" line ONLY when `refunded` is true (if the call itself
      fails it claims nothing about the cap). Confirm the deployed function in
      `closero-backend`: (1) returns a boolean field literally named `refunded`, true
      only when the cap credit was actually returned, honestly `false` when the grant
      was never counted; (2) is idempotent on `requestId` (refund at most once, stable
      result on a repeat call, e.g. a `refundedAt` marker on the grant doc); (3) accepts
      the reason allowlist `socket_drop | mic_failure | launch_failure` (`socket_drop`
      is NEW in Session 16) and refunds nothing for `user_hangup`. Deploy with
      `firebase deploy --only functions:abortSimSession`. Test: call twice with a
      counted test requestId (only the first decrements `sessionsUsed`), and once with
      `user_hangup` (no change). (Session 16)
- [ ] **Decide: broker mid-call resume, or degrade-to-refund.** The client reconnects on
      a droppable close with bounded backoff and re-sends `hello` for the same
      `requestId`. The broker has no mid-call resume in v1, so today a reconnect falls
      through to a graceful abort + refund. That is honest and safe: **recommended for
      v1, zero broker work** -- just confirm it in the live smoke test (pull the network
      ~5s: banner appears, clock pauses, aborted screen, refund fires). If you later want
      TRUE resume, it is broker-side work in `closero-broker`: keep the grant doc valid
      for a re-hello, keep the Durable Object's conversation state alive for a grace
      window (~15s, matching the client) after `webSocketClose`, treat a reconnect as a
      resume rather than `4409 superseded`, and re-emit `ready` (the client resumes on
      `ready` with zero app changes). (Session 16)

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
- [ ] **Safari autoplay (real browser).** Client handling now shipped (Session 16): the
      preflight builds + `preload()`s the TtsPlayer, and the Start tap `prime()`s it (silent
      WAV play) inside the user gesture, plus the mic grant in the same preflight gesture
      unlocks audio. STILL needs a real-Safari check that the first persona utterance
      (starts on `utteranceEnd`, not the tap) actually plays. Couldn't test headlessly.
      (Session 14, implemented Session 16)
- [ ] **Mic sample rate (real browser).** Client safeguard now shipped (Session 16):
      `resamplePcm16Mono` + the `MIC_INPUT_RATE` dart-define downsample mic audio to 16kHz
      when a browser ignores the requested rate. STILL needs a real-device measurement on
      Chrome AND Safari of the ACTUAL delivered rate; if it is 48kHz, ship the build with
      `--dart-define=MIC_INPUT_RATE=48000` (or the measured rate). (Session 14, implemented
      Session 16)

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
