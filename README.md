# closero-app

The Closero Flutter app: reps practice sales calls against AI personas and
get live coaching plus post-call scoring. v1 ships to web (Cloudflare
Pages, app.closero.app); iOS second, Android third. Shares a Firebase +
RevenueCat backend with the marketing site (closero.app), never code.

## Where things are

- `CLAUDE.md` — the binding rules (tokens, accent, copy voice, backend
  contracts). Read it first; violating it is a bug.
- `context/` — binding specs (scoring rubric, Rive rig contract, design
  tokens, canonical mock data) and the prototype screens the UI matches.
  `context/open-findings.md` is the live fix list; `context/archive/` is
  history, not law.
- `LAUNCH_TODO.md` — every manual step between here and real users.
- `lib/core/` — theme (generated tokens), shared widgets, routing,
  services. `lib/features/` — one folder per screen cluster.

## Run

```
flutter run -d chrome
```

Live-call scenarios, analytics, and billing need dart-defines and
deployed backends; see LAUNCH_TODO.md. Without them the app runs on
fixtures with those paths dark.

## Verify (before any commit)

```
flutter analyze
flutter test            # includes goldens locally
dart run tool/gen_tokens.dart --check
bash tool/ci_greps.sh
```

Design tokens are generated: edit `closero-site/design-tokens.json`
(sibling repo), then `bash tool/sync_tokens.sh`. Never edit
`context/design-tokens.json` or `lib/core/theme/tokens.g.dart` by hand.
