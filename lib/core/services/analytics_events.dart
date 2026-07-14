/// The single registry of product-analytics event names, property keys,
/// and enumerated property values. Every string that reaches PostHog
/// lives here, so no inline event literal ever appears at a call site
/// (CI greps lib/ for `capture(` with a string literal).
///
/// Privacy contract: nothing in a payload identifies a person. Users are
/// keyed by Firebase uid via identify(); event properties carry only
/// non-personal dimensions (scenario id, sim type, tier, coarse score
/// band, duration). Never add email, displayName, transcript text, or
/// any free-form user content as a property.
library;

/// Event names. Pass one of these to [AnalyticsService.capture]; never a
/// bare string literal.
abstract final class AnalyticsEvents {
  static const signupCompleted = 'signup_completed';
  static const onboardingStep = 'onboarding_step';
  static const onboardingCompleted = 'onboarding_completed';
  static const scenarioPreviewOpened = 'scenario_preview_opened';
  static const simStart = 'sim_start';
  static const simCompleted = 'sim_completed';
  static const simAborted = 'sim_aborted';
  static const scoreViewed = 'score_viewed';
  static const capHit = 'cap_hit';
  static const upgradeScreenViewed = 'upgrade_screen_viewed';
  static const upgradeCtaClicked = 'upgrade_cta_clicked';
  static const purchaseSucceeded = 'purchase_succeeded';
  static const manageBillingClicked = 'manage_billing_clicked';
}

/// Property keys shared across events.
abstract final class AnalyticsProps {
  static const method = 'method';
  static const stepIndex = 'step_index';
  static const stepName = 'step_name';
  static const scenarioId = 'scenario_id';
  static const simType = 'sim_type';
  static const tier = 'tier';
  static const durationSec = 'duration_sec';
  static const scoreBand = 'score_band';
  static const reason = 'reason';
  static const source = 'source';
  static const sessionId = 'session_id';
}

/// `source` values for [AnalyticsEvents.upgradeScreenViewed]: which entry
/// point routed the user to the upgrade wall.
abstract final class UpgradeSource {
  static const cap = 'cap';
  static const lockedCard = 'locked_card';
  static const settings = 'settings';

  /// A direct visit to /upgrade with no routed source.
  static const direct = 'direct';
}

/// `method` values for [AnalyticsEvents.signupCompleted].
abstract final class SignupMethod {
  static const email = 'email';
  static const google = 'google';
  static const apple = 'apple';
  static const other = 'other';

  /// Maps Firebase provider ids on a freshly created account to a coarse
  /// signup method label. Non-personal.
  static String fromProviderIds(Iterable<String> providerIds) {
    if (providerIds.contains('google.com')) return google;
    if (providerIds.contains('apple.com')) return apple;
    if (providerIds.contains('password')) return email;
    return other;
  }
}

/// Coarse score buckets for the `score_band` property, matching the ring
/// thresholds (>=75 high, 60-74 mid, <60 low). A band, never the exact
/// score, keeps the payload non-identifying and analysis-friendly.
String scoreBandLabel(int score) {
  if (score >= 75) return 'high';
  if (score >= 60) return 'mid';
  return 'low';
}
