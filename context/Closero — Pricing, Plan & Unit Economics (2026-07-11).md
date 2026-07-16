# Closero — Pricing, Plan & Unit Economics

_Last updated 2026-07-11._

**Status:** Direction is mostly locked (reverse trial, $15.99/mo, own the pipeline). All specific numbers (trial length, session caps, free allowance) are **PROVISIONAL** until week-4 usage + conversion data. All costs are **modeled estimates** at 2026-07 pricing; verify against the broker's real per-session cost log (Prompt Pack Part 4 #9) before betting on them.

---

## 1. How the plan works (reverse trial)

Instead of starting users weak and asking them to upgrade, Closero starts them **strong** and downgrades them if they don't pay. They taste the full product first, so the lockout is what drives the purchase. This is the highest-converting model that still fits the low-pressure coaching brand (~24% cross-industry median vs ~4.5% for pure freemium).

**Phase 1 — Free trial (~14 days, no credit card).** Full Closer-level access. This is the hook: they build a streak, watch their income tier climb, and feel real progress.

**Phase 2 — Lockout / downgrade.** When the window ends, they drop to a limited free tier. They can still practice a little, but the score, progress, and income tier go behind the paywall. The card is asked for **here**, at the moment of loss, not at signup.

**Phase 3 — Closer subscription ($15.99/mo or $129/yr).** Everything unlocked, unlimited practice.

Why lock the score and not the practice: locking the score is a **conversion** lever, not a cost saver (the session already cost the same to run). Letting them keep practicing with live hints keeps the free tier useful; hiding "how am I doing" is the upgrade trigger.

---

## 2. What users get

| | **Free trial** (~14 days) | **Free** (after trial) | **Closer — $15.99/mo** ($129/yr) |
|---|---|---|---|
| Card to start? | No | No | Yes |
| Sessions | 3 per day | ~3 per month | Unlimited (fair-use ~75/mo) |
| Sims | Both (Cold Call + Video) | Both | Both |
| Library | Everything (B2C + B2B) | B2C personas only | B2C + B2B + methodologies (SPIN, Sandler, etc.) |
| In-call coaching (momentum dots, live hints) | Yes | Yes | Yes |
| Post-call score + skill breakdown | Yes | Locked (teaser only) | Yes |
| Progress, history, income potential | Yes | Locked | Yes |
| Streaks + rewards (7-day bonus, 30-day unlock) | Yes | Yes | Yes |

_Provisional numbers: 14 days, 3/day, 3/month, 75/mo. The exact "what stays visible on free" line still needs pressure-testing: lock too much and free feels pointless, lock too little and no one upgrades._

---

## 3. What costs money (the stack)

### Variable — per session (the live sim)

Modeled at the default session shape: **15 outputs, ~150-character average persona replies**, ~6 minute call.

| Item | Vendor / plan | Rate (2026-07) | Per session |
|---|---|---|---|
| Speech-to-text | Deepgram Nova-3 streaming (Pay-As-You-Go) | $0.0077/min ($0.0048 promo) | ~$0.040 |
| Text-to-speech | Azure Standard Neural | $16 / 1M characters | ~$0.036 |
| Roleplay + hints + scoring | OpenAI GPT-5.4-mini (caching on) | $0.75/1M in, $4.50/1M out | ~$0.025 |
| **Total per session** | | | **~$0.10** |

TTS is the biggest lever because it's billed per character; keeping persona replies terse (~150-char average) is what holds this at ~$0.10. Wordier replies (~280 chars) and 20 outputs push it back to ~$0.20.

Free credits that offset early usage: Deepgram $200 credit; Azure 500K TTS chars/month free; these likely cover the entire beta.

### Per transaction (only when someone pays)

| Item | Rate | On a $15.99 charge |
|---|---|---|
| Stripe | 2.9% + $0.30 | ~$0.76 |
| RevenueCat | Free under $2,500/mo tracked revenue, then 1% | ~$0 early |

### Fixed — monthly (roughly flat regardless of users, early on)

| Item | Cost | Notes |
|---|---|---|
| Cloudflare Workers paid plan | $5/mo | Durable Objects require it (the broker) |
| Firebase (Firestore/Auth/Functions) | ~$0 early | Free Spark tier or minimal Blaze pay-as-you-go at low scale |
| PostHog (analytics) | ~$0 early | Free tier ~1M events/mo |
| Resend (transactional email) | ~$0 early | Free tier ~3,000/mo; $20/mo later |
| Domain | ~$1/mo | ~$10–15/yr |
| **Fixed total** | **~$5–10/mo** | Stays tiny until real scale |

---

## 4. Cost by usage level (paid user)

| Paid user | Sessions/mo | Stack COGS | Net margin* |
|---|---|---|---|
| Casual | ~9 | ~$0.90 | ~$14.30 |
| Typical | ~27 | ~$2.70 | ~$12.50 |
| Heavy | ~50 | ~$5.00 | ~$10.20 |
| **Maxing the fair-use cap** | **75** | **~$7.58** | **~$7.70** |

_*Net margin = $15.99 − stack COGS − ~$0.76 Stripe fee._

**The 75-session cap is safe:** even a user pegging the cap every month still nets ~$7.70 (~48% margin). At the old ~$0.20/session shape, 75 sessions (~$15) would have wiped out the margin, this is exactly why the session-shape optimization mattered. In reality almost no one hits 75 (that's 2.5 sessions every single day); the average paid user runs ~27 and nets ~$12.50 (~78% margin).

### Free-tier cost (non-payers)

| | Sessions | Cost to you |
|---|---|---|
| Trial user (realistic) | ~10 over 14 days | ~$1.00 one-time |
| Trial user (maxed, rare) | ~42 over 14 days | ~$4.20 one-time |
| Post-lockout free user | ~3/month | ~$0.30/month |

---

## 5. Revenue & profit

Every paying customer is profitable at any usage level. Total profit = per-customer margin × number of paying customers.

### Per 100 trial signups (one-time trial give-away ≈ $150)

| Conversion | Paying customers | Gross rev/mo | Net profit/mo |
|---|---|---|---|
| 10% (conservative, first app) | 10 | ~$160 | ~$116 |
| 15% | 15 | ~$240 | ~$179 |
| 24% (reverse-trial benchmark) | 24 | ~$384 | ~$292 |

Each batch of 100 signups pays back the ~$150 trial give-away inside the first month, then throws off recurring profit.

### By total paying customers (typical usage, ~$12/customer net)

| Paying customers | Gross rev/mo | Net profit/mo |
|---|---|---|
| 25 | ~$400 | ~$290 |
| 100 | ~$1,600 | ~$1,200 |
| 500 | ~$8,000 | ~$6,000 |

Break-even is ~2 paying subscribers against fixed costs. Everything past that is margin.

---

## 6. Assumptions, unknowns & risks

**The two numbers that set the ceiling (still unknown):**
1. **Signup volume / CAC.** The tables scale per 100 signups, but how you *get* signups (organic, content, ads) is undetermined. This is the real limiter, not cost per session.
2. **Churn / retention.** B2C subscriptions churn ~5–10%/mo. At ~$12.50 net margin, a 6-month customer is worth ~$75 LTV; a 2-month customer ~$25. Retention decides whether this compounds or leaks.

**Watch items:**
- All caps (14-day trial, 3/day, 3/month, 75/mo) are provisional; confirm on week-4 data.
- Costs are modeled; the broker cost log (Part 4 #9) is the source of truth before scaling spend.
- 24% conversion is a cross-industry median, not a promise; plan around 10–15% for a first app and treat 24% as upside.
- `startSimSession` must BLOCK at every cap (not just count), or the whole cost model leaks.
- Margins shown are gross; they don't count your time or paid marketing.
