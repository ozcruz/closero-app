/// The one place plan facts live. Screens and copy read these; a price
/// or cap change is a one-file edit. Prices must match the RevenueCat
/// products (closermonth $15.99 P1M, closerannual $129 P1Y); caps must
/// match limits.js in closero-backend, which is what actually enforces
/// them (startSimSession blocks at every cap).
///
/// Reverse-trial model (pricing doc 2026-07-11), three phases:
///   trial  (~14 days from signup)  full Closer access, 3 sessions/day
///   free   (after the trial)       3 sessions/month, B2C library only
///   closer ($15.99/mo or $129/yr)  everything, fair use 75 sessions/mo
/// All caps are provisional until week-4 usage data.
library;

/// Days of full access from signup. Server-written as trialEndsAt.
const int kTrialDays = 14;

/// Sessions per day while trialing, enforced by startSimSession.
const int kTrialDailyCap = 3;

/// Post-trial free-tier monthly session cap, enforced server-side by
/// startSimSession; the client only displays it.
const int kFreeSessionCap = 3;

/// Closer fair-use monthly cap, enforced by startSimSession. "Unlimited"
/// copy anywhere must carry this number.
const int kCloserFairUseCap = 75;

const String kCloserMonthlyPrice = r'$15.99';
const String kCloserAnnualPrice = r'$129';

/// "save 33%": 129 / (15.99 * 12) = 0.672, rounded to the marketing
/// figure used on the site.
const String kAnnualSavingsNote = r'or $129/year, save 33%';

/// What Free includes, in display order. Free deliberately KEEPS live
/// coaching hints: locking the score is the conversion lever, keeping
/// practice useful is the retention lever (pricing doc, section 1).
const List<String> kFreePlanIncludes = [
  '$kFreeSessionCap practice sessions per month',
  'B2C scenario library',
  'Live coaching hints during calls',
];

/// What Free lacks (rendered dim with a cross), in display order. Only
/// gates that exist: B2B cards and methodologies render locked for the
/// effective free tier and route to the upgrade screen.
const List<String> kFreePlanExcludes = [
  'Full B2B scenario library',
  'Methodology library',
];

/// What Closer includes, in display order. The fair-use number rides
/// along so "unlimited" stays mechanically true.
const List<String> kCloserPlanIncludes = [
  'Unlimited sessions (fair use: $kCloserFairUseCap per month)',
  'Full B2B + B2C scenario library',
  'Methodology library: SPIN, Sandler, and more',
];

/// The unlock list on the upgrade-success screen.
const List<String> kCloserUnlockHighlights = [
  'Unlimited sessions (fair use: $kCloserFairUseCap per month)',
  'Full B2B + B2C scenario library',
  'Methodologies library unlocked',
];

/// The trial column, shown to trialing users on the upgrade screen so
/// the three phases are all described where the decision happens.
const String kTrialPhaseNote =
    "You're on the free trial: everything above is unlocked, "
    '$kTrialDailyCap sessions per day. When it ends you keep '
    '$kFreeSessionCap sessions per month on the free plan.';
