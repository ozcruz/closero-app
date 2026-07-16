# Session 17 prompts (polish + deploy), split

Written 2026-07-14, after Session 16. The original one-shot Session 17 prompt bundled four
modes of work: a read-only audit, a test sweep, a feature build (web loading shell), and
console deploy config. Split below so each session has one mode, one reviewable diff, and
the audit cannot silently "fix" what it is supposed to be reporting.

Run in order. Only 17a wants ultracode + max effort; the rest are normal Opus at high.

Prereq: commit Session 16 first, so each session starts from a clean diff.

---

## 17a — Release audit: DONE (2026-07-14/15)

Ran read-only, ultracode. Output lives distilled in `context/open-findings.md`;
the full report is `context/archive/session-17a-audit.md`.

## 17b — Fix pass: DONE (Session 17b, 2026-07-16)

Went a different way than "paste the list": adopted the reverse-trial model
(trialEndsAt + derived tier), rewrote plan_catalog to the real three phases,
wired getManageSubscriptionUrl. Closed must-fix 1-3. The remainder is in
`context/open-findings.md`.

## 17c — Accessibility sweep, as permanent tests

Repo facts this depends on: CLAUDE.md's Verification section has **no a11y step**; Flutter's
guideline matchers (`meetsGuideline`) are used **nowhere**; a11y tests today cover **3 widgets**
(`test/widgets/interaction_test.dart`), never a screen; 44px is enforced by convention via
hardcoded `44` literals in ~15 files with no token; the four auth screens have **zero**
`Semantics`. All 22 screens already have golden fixtures worth reusing.

> Accessibility sweep for the whole app, made permanent rather than a one-off. Add `test/a11y/`
> asserting `meetsGuideline(androidTapTargetGuideline)`, `meetsGuideline(labeledTapTargetGuideline)`
> and `meetsGuideline(textContrastGuideline)` for all 22 screens, reusing the fixtures and
> scenario builders the golden tests already construct in `test/goldens/*_golden_test.dart` (do
> not re-invent fixtures). Fix what fails. Expect: the four auth screens have zero `Semantics`;
> 44px is hardcoded in ~15 files rather than tokenized (if that surfaces as a real failure,
> PROPOSE a `kMinTapTarget` token, don't silently add it). Every icon-only control needs a
> Semantics label. Then add the a11y run to the CLAUDE.md Verification section and to
> `.github/workflows/ci.yml`. Report anything found but not fixed.

Why its own session: it is the only item in the original prompt that permanently raises the
floor instead of decaying the next time a screen is added.

## 17d — Web startup shell + Pages artifacts

Repo facts this depends on: `web/index.html` has **zero** startup UI (stock `<body>` +
`flutter_bootstrap.js`, no background) so the pre-boot paint is **white** against the warm-dark
app; `theme-color` at index.html:22 is already `#0E0C0A`, exactly the `base` token
(`tokens.g.dart:116`); the brand fonts are Flutter **asset** fonts (.ttf, no woff2) resolved only
at boot, so an HTML shell **cannot** reference Figtree/Bricolage by name; `tool/ci_greps.sh` only
greps `lib/**/*.dart`, so HTML copy escapes the em-dash/token guards.

> Three files under `web/`, all of which ship inside `build/web`.
> (1) Branded startup shell in `web/index.html`: paint the `base` token `#0E0C0A` immediately
> (already the `theme-color` at index.html:22) and show the brand mark, not a bare spinner. The
> brand fonts are Flutter ASSET fonts resolved only at boot, so the shell must NOT reference
> Figtree/Bricolage by name: use the locked wordmark/ring geometry as inline SVG. The path
> strings are verbatim in `lib/core/widgets/closero_wordmark.dart` (viewBox `-60 -760 3745 1112`)
> and `CloseroMark` is pure ring geometry. Geometry is LOCKED: recolor only, never redraw. Keep
> shell copy to zero or one calm line and hand-check it (`tool/ci_greps.sh` does not cover HTML).
> Remove the shell once Flutter boots; respect `prefers-reduced-motion`. Do NOT disturb the
> deliberate key-less PostHog loader stub at index.html:36-44.
> (2) `web/_redirects` with `/* /index.html 200`. The app calls `usePathUrlStrategy()`
> (`lib/core/routing/url_strategy/url_strategy_web.dart:6`), so without this every deep link and
> hard refresh 404s on Pages.
> (3) `web/_headers`, required by `context/hosting-and-auth.md:30` and currently missing. It must
> GRANT the microphone via `Permissions-Policy` or the live sim's mic is blocked in production
> (note the marketing site's own `_headers` actively denies it: `microphone=()`). Add sensible
> security headers alongside.
> Verify: `flutter build web`, confirm all three land in `build/web`, serve `build/web` locally,
> and check that a hard refresh on `/progress` returns the app and that there is no white flash.

`_headers` is the highest-risk missing artifact in the repo: without it the mic can be blocked
in production, which silently breaks the entire product.

## 17e — Deploy (thin prompt; mostly manual)

> Give me the exact Cloudflare Pages setup for a NEW project serving this app's `build/web` at
> app.closero.app, as a second Pages project separate from the marketing site (per
> `context/hosting-and-auth.md`). Note the real constraint first: Cloudflare Pages' build image
> has no Flutter (this repo: Flutter 3.44.5 stable, Dart ^3.12.2), so recommend the build approach
> and justify it: (a) GitHub Actions builds and publishes via wrangler (CI already installs Flutter
> with `subosito/flutter-action@v2` in `.github/workflows/ci.yml`), (b) Pages Git integration with
> a build command that installs Flutter, or (c) local `flutter build web` + `wrangler pages deploy
> build/web`. Then give me the exact project settings (build command, output dir, root dir, env
> vars), the required `--dart-define`s (`POSTHOG_API_KEY` has NO baked default, analytics stays
> dark without it; plus `BROKER_WSS_BASE` / `LIVE_SCENARIOS` / `MIC_INPUT_RATE` when live scenarios
> roll), and the manual checklist: create the project, attach app.closero.app, and add BOTH
> app.closero.app AND the new `*.pages.dev` preview domain to Firebase authorized domains
> (`hosting-and-auth.md:28-29`; sign-in fails silently otherwise). Then tick the matching
> LAUNCH_TODO.md items.

Why thin: no agent can click the Cloudflare or Firebase console. The valuable output is the
build-approach decision plus an accurate checklist, not code. Can be merged into 17d if you would
rather build the web artifacts and ship them in one sitting.

---

## Deliberately NOT in Session 17: EARLY_ACCESS

The original prompt asked for "the EARLY_ACCESS gating approach consistent with the site's flag."
That premise does not hold, so it was dropped:

- The site's flag is `export const EARLY_ACCESS = true` in `assets/js/firebase-init.js:52`
  (mirrored here at `context/js/firebase-init.js`). It is read in two places: the homepage sets
  `document.body.dataset.ea` and CSS hides `.when-launched` (early-access landing + waitlist form
  instead of the full marketing site), and `app.html` swaps the upgrade UI for a holding message.
  Flipping it to `false` reveals the full marketing site. That works as intended.
- **It gates nothing.** The site's `login.html` / `signup.html` never read it, so anyone can
  create a real Firebase account today regardless. It toggles site copy; it has no enforcement to
  be "consistent" with, and a JS const on closero.app has no reach into a different origin.
- It is also not urgent: `app.closero.app` is linked from zero pages and has no DNS record, so the
  app is private by default until the site links to it.
- `context/archive/promptSessionPreReqs.md:111` already places it in launch week ("Deploy behind
  EARLY_ACCESS, invite the waitlist (Resend broadcast)"); the phrase originated in
  `context/archive/build-plan.md:10` as borrowed vocabulary standing in for "TestFlight". Session 17's own
  documented hard blocks (`context/archive/promptSessionPreReqs.md:101-103`) are only the Pages project and the
  Firebase authorized domains.

The real decision, for launch week: (a) do nothing, rely on the unlisted URL; (b) Cloudflare
Access in front of app.closero.app (real gate, zero app code, email allowlist/OTP); (c) a
server-side allowlist checked at sign-in against the Firestore `waitlist` collection (real gate,
backend work). Tracked in LAUNCH_TODO.md.
