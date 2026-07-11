/// Compile-time billing endpoints, set with --dart-define. Both URLs are
/// public tokens (like the Firebase config): safe to ship, safe to check
/// in as defaults once generated in the RevenueCat dashboard
/// (Funnels → Web Purchase Links).
library;

/// RevenueCat Web Purchase Link base, WITHOUT the app user id segment,
/// e.g. https://pay.rev.cat/xxxxxxxxxxxx. The checkout URL is
/// `$base/<uid>` so the purchase lands on the signed-in Firebase uid and
/// the webhook can flip users/{uid}.entitlement.
///
/// Override with: --dart-define=RC_PURCHASE_LINK=https://pay.rev.cat/...
const String kRcPurchaseLinkBase = String.fromEnvironment('RC_PURCHASE_LINK');

/// Hosted subscription-management URL, if one is configured. RevenueCat
/// Web Billing has no deterministic per-user portal URL (the portal link
/// arrives in RevenueCat's receipt emails), so this stays empty until a
/// hosted portal exists; the UI falls back to honest copy about the
/// receipt email.
///
/// Override with: --dart-define=RC_MANAGE_BILLING_URL=https://...
const String kRcManageBillingUrl =
    String.fromEnvironment('RC_MANAGE_BILLING_URL');
