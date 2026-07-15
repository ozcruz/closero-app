# Session 17 prompts (polish + deploy), split

Written 2026-07-14, after Session 16. The original one-shot Session 17 prompt bundled four
modes of work: a read-only audit, a test sweep, a feature build (web loading shell), and
console deploy config. Split below so each session has one mode, one reviewable diff, and
the audit cannot silently "fix" what it is supposed to be reporting.

Run in order. Only 17a wants ultracode + max effort; the rest are normal Opus at high.

Prereq: commit Session 16 first, so each session starts from a clean diff.

---

## 17a — Release audit (READ-ONLY, ultracode + max)

> Release audit, read-only: do not edit a single file. First run the mechanical gate and
> report pass/fail only: `flutter analyze`, `flutter test`, `dart run tool/gen_tokens.dart --check`,
> `bash tool/ci_greps.sh`. Then audit all 22 screens registered in `lib/core/routing/app_router.dart`
> (9 in-shell, 12 standalone, plus `NotFoundScreen`) against the CLAUDE.md hard rules, fanning
> out per screen-cluster per dimension: (1) accent discipline: count accent-filled elements per
> view, must be <=1 and on the permitted list; (2) container + state-color rules (no tinted-chip
> washes, no red-tinted destructive, rings/bars by threshold never accent, scoreText ramp);
> (3) copy voice: no em dashes, sentence case, no combat metaphors, low-pressure, and every
> promise mechanically true (trace each claim to the code that makes it true, e.g. any "we email
> you" or "this didn't count against your sessions" line); (4) tokens: no hardcoded
> color/size/radius/font outside `tokens.g.dart`, spacing on the 4px scale, the 18px+bold type
> rule; (5) icon signature (one -60deg element, 15x15 viewBox); (6) backend contract: the client
> never writes `entitlement`/`sessionsUsed`/`usageMonth`, scores are server-written, analytics
> payloads carry no email/displayName/transcript content; (7) accessibility: Semantics on every
> icon-only control, 44px minimum targets, body contrast.
> Reuse the existing reviewers in `.claude/agents/` (accent-auditor, copy-voice, token-cop) as
> the per-dimension lenses. Adversarially verify every finding against the code before reporting
> it: default to dropping anything you cannot prove with a file:line. Output ONE ranked list:
> severity, file:line, rule broken, suggested fix. Separate "must fix before launch" from
> "v1.1". Fix nothing.

Pass condition: a findings list AND an unchanged working tree (`git status` clean). A dirty
tree means it broke the read-only rule.

Why read-only + ultracode: 22 screens x 7 dimensions is broad, unknown-size discovery, which is
the one place fan-out earns its cost. The adversarial-verify pass is what keeps the list
trustworthy. Note the mechanical half is only 4 commands and was green at the end of Session 16;
the value here is the judgment dimensions, not re-running greps.

## 17b — Fix pass (CONDITIONAL: write it only after reading 17a's list)

Do not pre-write this. Its size is unknowable until 17a reports, and Session 16 shut clean, so
the list may be short. Shape:

> Apply these findings from the release audit, most severe first: [paste the must-fix list].
> One file at a time, smallest correct change; do not refactor beyond the finding. After each:
> `flutter analyze`, `flutter test`, `bash tool/ci_greps.sh`. Regenerate any golden a change
> touches (`flutter test --update-goldens`) and eyeball the PNG before accepting it. Anything
> you decide NOT to fix, say why and label it v1.1.

If the must-fix list is a handful of one-liners, fold this into the top of 17c instead of
spending a session on it.

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
- `context/promptSessionPreReqs.md:111` already places it in launch week ("Deploy behind
  EARLY_ACCESS, invite the waitlist (Resend broadcast)"); the phrase originated in
  `build-plan.md:10` as borrowed vocabulary standing in for "TestFlight". Session 17's own
  documented hard blocks (`promptSessionPreReqs.md:101-103`) are only the Pages project and the
  Firebase authorized domains.

The real decision, for launch week: (a) do nothing, rely on the unlisted URL; (b) Cloudflare
Access in front of app.closero.app (real gate, zero app code, email allowlist/OTP); (c) a
server-side allowlist checked at sign-in against the Firestore `waitlist` collection (real gate,
backend work). Tracked in LAUNCH_TODO.md.
