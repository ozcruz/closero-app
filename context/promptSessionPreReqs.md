Week 3 (billing + content), all in Part 4:


[M] Create Stripe account, RevenueCat project, Web Purchase Link (items 3-4).
[P] Deploy webhook + startSimSession + cap-hit email (items 5, 7, 7b): paste the prompts.
[M] Test-mode purchase end to end (item 6). NOT optional: if the webhook is wrong, nobody can ever pay you.
[P] Persona content pass + real comp data (item 13).
[M] Book the attorney for ToS/Privacy (item 12). Only launch blocker no prompt clears.


Week 4 (pipeline accounts + launch), Part 4:


[M] Deepgram, Azure Speech, OpenAI API keys; Cloudflare Workers paid plan ($5/mo) (item 8).
[P] Cost instrumentation after first live sessions (item 9).
[M] Cloudflare Pages project for app.closero.app, Firebase authorized domain (items 10-11).


Manual work to finish BEFORE each session (Session 8 onward)

This is the checklist no prompt can do for you. [M] = you do it in a dashboard. [P] = a prompt you paste into a Claude Code session in the backend repo. "HARD BLOCK" means the session cannot be tested (or built correctly) without it; everything else is "do it in parallel, don't stall the build."

Session 8 — Settings + billing wall


[M] HARD BLOCK: Create your Stripe account (test + live mode). ~15 min. (Part 4, item 3)
[M] HARD BLOCK: Create the RevenueCat project → add Web Billing, connect Stripe, create the closer entitlement, one offering with Monthly ($15.99) + Annual ($129), and generate the Web Purchase Link. That URL is the thing the Session 8 prompt says "(URL provided)" — you paste it in. (Part 4, item 4)
[P] Deploy the RevenueCat webhook + the Auth onCreate trigger (it exists dormant in closero-backend). Without this, a purchase never flips entitlement, so the unlock can't be tested even though the screen builds. (Part 4, item 5)
[M] Then run the test-mode purchase (card 4242 4242 4242 4242) end to end so you KNOW billing works. Not optional: if the webhook is wrong, nobody can ever pay you. (Part 4, item 6)


Session 9 — Progress, Achievements, Methodologies


No hard blocks. Runs on mock data.
[P] Nice-to-have in parallel: the real comp-data pass so the earnings figures ($64K / $85-95K tier) are defensible, not placeholder. (Part 4, item 13)


Session 10 — Scoring + Transcript


[M] HARD BLOCK: Answer the 4 open questions at the bottom of scoring-rubric.md. That file is the binding scoring contract this session builds against (category keys, weights, keyMoments shape). Locking it after the screens are built means rework.


Session 11 — Sim screens (scripted)


[P] HARD BLOCK: Deploy the startSimSession callable function. Session start routes through it from day one, and it's what makes the 5-session cap work later. Include the abortSimSession companion in the same prompt. (Part 4, item 7)
[P] Nice-to-have: the cap-hit email via Resend, right after the cap function. (Part 4, item 7b)
[M] Nice-to-have: the Safari/Chrome mic + autoplay spike (half day) so you know the real pipeline in Session 14 won't hit a wall.


Session 12 — Rive avatar runtime


[M] HARD BLOCK: Drop the test .riv file into assets/rive/. The session literally cannot run without it. Confirm the mouth-group Number values match rive-contract.md.


Session 13 — The broker (separate repo)


[M] HARD BLOCK, and these take lead time, so set them up a few days early:

Deepgram account + API key (STT).
Azure Speech account + key (TTS with visemes).
LLM API key (OpenAI/Anthropic).
Cloudflare Workers PAID plan ($5/mo — Durable Objects require it).
(Part 4, item 8)



[M] Firebase Admin credentials for the broker (service account) so it can write scores.
[P] Nice-to-have: the persona content briefs, loaded as versioned content files. (Part 4, item 13)


Session 14 — Live pipeline in the app


HARD BLOCK: Session 13's broker must be deployed and you need its message-schema doc (Session 13 produces it). All the item-8 accounts above must be live keys, not placeholders.
[M] Plan to test on both Chrome and Safari.


Session 15 — Analytics


[M] HARD BLOCK: Create a PostHog account + project (pick EU or US cloud). You'll pass the key via --dart-define.
[M] Reminder: add PostHog to your Privacy policy vendor list before public launch.


Session 16 — Error + edge states


[P] HARD BLOCK: the abortSimSession refund path must exist (deployed with item 7). The aborted-session flow depends on it so a dropped call doesn't burn a free session.


Session 17 — Polish + deploy


[M] HARD BLOCK: Create the Cloudflare Pages project for the app and point app.closero.app at it (Session 17 gives you the exact settings). (Part 4, item 10)
[M] HARD BLOCK: Add app.closero.app to Firebase authorized domains. (Part 4, item 11)
[M] Launch blocker (start in week 3, not here): the attorney pass on ToS/Privacy — auto-renew disclosures, methodology trademark names, earnings claims. The only launch blocker no prompt clears. (Part 4, item 12)


The one rule: [M] account setups (Stripe activation, Deepgram, Apple later) can sit in review queues for days. Start each one a session or two before you need it, not the morning you sit down to build.

After the pack ends (what Part 5 and launch week look like)


Deploy behind EARLY_ACCESS, invite the waitlist (Resend broadcast).
Watch the PostHog funnel + the cost-per-session table for 1-2 weeks. These two numbers decide everything next: the free cap, the video-sim gating, and whether to spend a dollar on acquisition.
Lock the freemium shape (currently leaning 3 sessions/mo, full scoring) and the Day One annual offer.
Then the backlog, in rough order: more personas (content pass), iOS build (Apple account first, it takes days), win-back emails, B2B outreach once you have retention proof.


The one-sentence version

Sessions 0-11 build a beautiful fake, 12-14 make it real, 15-17 make it measurable and safe, Part 4 is your checklist of accounts + pasted backend prompts, and Part 5 is the list of ways it can go wrong that we are already watching.