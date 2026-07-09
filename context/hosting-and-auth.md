# Hosting + auth handoff (read before Session 4 and Session 14)

## Topology: two separate Cloudflare Pages projects, one Firebase backend

- `closero.app` — existing static marketing site (its own Pages project). Marketing + funnel only.
- `app.closero.app` — a SECOND, separate Pages project serving this Flutter app's `build/web`.
- Both share the same Firebase project and the same `users/{uid}` schema. Zero shared code.

## The auth handoff (the thing that is easy to get wrong)

Firebase persists the auth session PER ORIGIN (IndexedDB keyed to the hostname). A user signed in on
`closero.app` is NOT signed in on `app.closero.app`. So "sign in on the site, then redirect to the app"
does NOT carry the session across, it drops the user at a logged-out app.

**Decision: the Flutter app owns authentication.**
- The app (Session 4) builds login, signup, reset, and verify screens. The user authenticates inside the
  app's own origin, so the session lives where the app runs.
- The marketing site stops signing anyone in. Its "Log in" / "Start free" buttons become plain links to
  `https://app.closero.app`.
- Retire the site's placeholder `login.html`, `signup.html`, `app.html` (Phase-1 scaffolding the Flutter
  app replaces). Same Firebase project = same accounts, nothing to sync.
- Do NOT try to keep login on the marketing site and pass a custom token across origins. More code, more
  security surface, no benefit here.

## Deploy checklist deltas for the app project

- New Cloudflare Pages project → build output `build/web` → custom domain `app.closero.app`.
- Firebase → Authentication → Settings → Authorized domains → add `app.closero.app` AND the app's
  `*.pages.dev` preview domain, or sign-in silently fails.
- The app project gets its own `_headers` (mic/camera permissions live here, not on the site).
- Keep the subdomain, not a `closero.app/app` subpath. Subpath would share the origin (session carries)
  but couples the two Pages projects and complicates Flutter's base href. Build plan already chose subdomain.
