# Canonical mock data (fixtures)

These are the single source of truth for placeholder data across every screen. Any screen that
disagrees with a value here is a bug, not a variation. Keep the prototype, the app, and the
golden tests all aligned to this sheet.

Copy voice rules still apply to every string below: no em dashes, sentence case, low-pressure
coaching voice, earnings figures always framed as market medians/ranges "per published comp data"
(never a personal prediction).

## Primary user

- Name: Sandra Voss
- Display name shown in app chrome: Osman Cruz (account owner in the prototype shell)
- Streak: 9 day streak
- Sessions completed: 47
- Practice time: 11.2 hrs
- Plan: Closer (paid). Free-tier variants use the "empty" screens.

## Earnings (framed as market medians, never personal predictions)

- Current skill level figure: $64K (progress screen shows the full form: $64,000)
- Market range at tier: $40K entry to $150K top performer
- Next tier: reps at 60 percent plus average $85 to 95K in the target market, per published comp data
- Movement is skill-tier movement only: "up 1 skill tier this quarter". Never a personal dollar delta.

## Skill breakdown (dashboard)

- Objection handling: 38 percent
- Discovery questions: 54 percent
- Building rapport: 71 percent
- Closing technique: 46 percent
- Tonality and pacing: 63 percent

## Next / featured session (dashboard)

- Title: Cold Call, SaaS Gatekeeper
- AI persona: Sandra, EA
- Tags: Sandler Method, Cold Call, B2B SaaS
- Scenario length: ~12 min
- Difficulty: 3 of 5

## Recent sessions (dashboard list)

- Inbound Demo, Hesitant Buyer, Sandler, 2h ago, 84 percent
- Cold Call, Price Objection, 7th Level, yesterday, 61 percent
- Follow-Up, Deal Going Cold, 77 percent

## Score screen

- Scenario: Gatekeeper bypass, SaaS AE
- Overall score: 78 (ring colors by threshold: hi2 >=75, mid 60 to 74, dim1 <60)
- Sub-scores shown: 84, 71, 61
- No live score mid-call. Momentum dots only during the sim.

## Simulation personas (Simulations grid initials)

DW, TC, RH, MG, WB, TS. Sandra Voss is the canonical gatekeeper persona used on the dashboard
and in the Scenario Preview modal.

## Billing

- Free: $0
- Closer: $15.99 / mo
- Free-tier session cap: 5 sessions this month, then the Session limit screen.

## Empty-state variants

Dashboard (empty), Progress (empty), and Achievements (empty) show the $40K entry figure and the
"no sessions yet" states for a brand-new free user, before any sessions are logged.
