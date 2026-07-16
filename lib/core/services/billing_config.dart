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
///
/// Default is the live Closer Web Purchase Link (RevenueCat Web Billing app
/// appacabc1da1a → Stripe). It is a public token, safe to check in.
const String kRcPurchaseLinkBase = String.fromEnvironment(
  'RC_PURCHASE_LINK',
  defaultValue: 'https://pay.rev.cat/udnnzqorhqrkqlor',
);

// Subscription management deliberately has no static URL here: the
// portal link is per-user and authenticated, fetched at click time via
// the getManageSubscriptionUrl callable (see billing_service.dart).
