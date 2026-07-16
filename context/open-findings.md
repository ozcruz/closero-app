# Open findings (the live list)

Distilled 2026-07-16 from the Session 17a release audit (full report,
method, and everything refuted: `context/archive/session-17a-audit.md`).
This file only lists what is still actionable. When an item is fixed,
delete it here.

Already resolved, for orientation: must-fix 1-3 (plan catalog honesty +
manage billing) closed by Session 17b. All icon findings are void (they
enforced a rule that has been struck). All cosmetic findings (accent,
tokens, contrast, the 16 nits) are deferred to the UI overhaul; fixing
them now means fixing them twice.

## Must fix before launch (honesty: copy written ahead of the wiring)

4. **"Resume" restarts from zero and burns a second session.**
   `scenario_card.dart:228`, `scenario_preview_modal.dart:127`. No resume
   path exists (broker has no mid-call resume). Relabel to "Start again"
   or drop `inProgress: true` from the fixture.
5. **Exit-confirm modal promises a score and a save that never happen.**
   `sim_widgets.dart:748`. On the default (scripted, fixture-repo) build
   the transcript is ignored. Keep only "This still counts as a session."
   until live scoring + the Firestore session repo are wired.
6. **Practice preferences are write-only.** `settings_screen.dart:275/286/299`.
   The toggles change nothing (library ignores audience, start paths
   hardcode Cold Call). Wire them in or copy the Notifications card's
   honest "saved now, live later" treatment.
7. **Methodology cards advertise scenarios that do not exist.**
   `methodology.dart:62-94`, `methodologies_screen.dart:385`. DELETE
   `scenarioCount` outright (custom scenarios are planned, any count is a
   lie with a shelf life) and reword the link to "Browse the library"
   until a real filter exists.
8. **Aborted score screen asserts an unverified refund + wrong cause.**
   `score_screen.dart:156-157`. Make the cause neutral and only claim
   "didn't count" on a server-written refund flag (SimAborted already
   models this correctly).
9. **Dashboard earnings figure drops the market-median framing.**
   `dashboard_screen.dart:528`. Match the siblings: "Market median at
   your current skill tier, per published comp data."
10. **Dashboard hero asserts a "weakest skill" nothing computes.**
    `dashboard_repository.dart:88`. Drop the analytic sentence or compute
    it from the sorted skills.
11. **"Link sent." asserts a send that may not happen.**
    `reset_password_screen.dart:132/49`. Anti-enumeration swallows
    user-not-found. Use "Check your email." + "If that email has an
    account, the link is on its way."

(Must-fix 12, dim1 contrast on the sourced earnings line, is deferred to
the UI overhaul with the rest of the cosmetics.)

## v1.1 (survives the overhaul; not cosmetic)

- `upgrade_screen.dart:45/60` — `?source=` from the URL lands raw in the
  PostHog payload. Allowlist-parse against `UpgradeSource`, fall back to
  `direct`.
- `upgrade_screen.dart:156` — "For reps actually trying to close their
  skill gaps" characterizes the reader. Drop the adverb.
- `progress_screen.dart:389` — `_TrendChip('↑ 1 skill tier')` is const
  across ranges; drive it from `earning.tierDelta` or hide it.
- `achievements_repository.dart:135` — session-zero earning note is an
  unsourced personal prediction. "Entry-level market median, per
  published comp data."
- `achievements_screen.dart:44` — hand-rolled error state duplicates
  `DataLoadError`; replace with the component.
- `PlaceholderScreen` (`lib/core/routing/placeholder_screen.dart`) is
  dead in the app (only the app-shell golden uses it as dummy content);
  fold it into the test and delete post-launch.
