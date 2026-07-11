/// The one place plan facts live. Screens and copy read these; a price
/// change is a one-file edit that must match the RevenueCat products
/// (closermonth $15.99 P1M, closerannual $129 P1Y).
library;

/// Free-tier monthly session cap, enforced server-side by
/// startSimSession; the client only displays it.
const int kFreeSessionCap = 5;

const String kCloserMonthlyPrice = r'$15.99';
const String kCloserAnnualPrice = r'$129';

/// "save 33%": 129 / (15.99 * 12) = 0.672, rounded to the marketing
/// figure used on the site.
const String kAnnualSavingsNote = r'or $129/year, save 33%';

/// What Free includes, in display order.
const List<String> kFreePlanIncludes = [
  '5 sessions per month',
  'B2C scenario library',
  'Post-call scoring',
  '7-day session history',
];

/// What Free lacks (rendered dim with a cross), in display order.
const List<String> kFreePlanExcludes = [
  'Live coaching hints during calls',
  'Full B2B scenario library',
  'Methodology library',
];

/// What Closer includes, in display order.
const List<String> kCloserPlanIncludes = [
  'Unlimited sessions',
  'Full B2B + B2C library',
  'Live coaching hints, every call',
  'Full methodology library',
  'Complete transcript and history',
  'Achievements and earning potential',
];

/// The unlock list on the upgrade-success screen.
const List<String> kCloserUnlockHighlights = [
  'Unlimited sessions, every month',
  'Full B2B + B2C scenario library',
  'Methodologies library unlocked',
  'Live coaching hints on every call',
];
