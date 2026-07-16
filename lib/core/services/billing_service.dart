import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import 'billing_config.dart';

/// Purchase and billing-management entry points, behind an interface so
/// the web build (RevenueCat Web Purchase Links, no purchases SDK) and
/// the later iOS build (purchases_flutter) swap implementations without
/// touching screens.
///
/// The contract everywhere: this service only OPENS checkout/portal
/// surfaces. Entitlement truth never comes back through it; the
/// RevenueCat webhook flips users/{uid}.entitlement server-side and the
/// app watches that doc.
abstract class BillingService {
  /// Whether a checkout destination is configured in this build.
  bool get checkoutConfigured;

  /// Whether a hosted billing-management destination is configured.
  bool get manageBillingConfigured;

  /// Opens checkout for the Closer subscription, identified as [uid]
  /// (the Firebase uid, which equals the RevenueCat app_user_id).
  /// Returns false if nothing could be opened.
  Future<bool> openCheckout({required String uid, String? email});

  /// Opens the hosted subscription-management surface for [uid].
  /// Returns false if nothing could be opened.
  Future<bool> openManageBilling({required String uid});
}

/// Fetches an authenticated customer-portal URL, or null when there is
/// no subscription to manage. Injectable so tests never touch Firebase.
typedef ManageBillingUrlFetcher = Future<String?> Function();

/// The `getManageSubscriptionUrl` callable (closero-backend): the
/// server looks up the caller's RevenueCat subscription by uid and
/// exchanges it for a signed-in portal URL. Contract: `{}` in,
/// `{url: 'https://...'}` out; failed-precondition means nothing to
/// manage (returned as null here).
Future<String?> fetchManageSubscriptionUrl() async {
  try {
    final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('getManageSubscriptionUrl')
        .call<Map<String, dynamic>>(<String, dynamic>{});
    final url = result.data['url'];
    return (url is String && url.startsWith('https://')) ? url : null;
  } on FirebaseFunctionsException catch (e) {
    // No active subscription to manage; the screen shows honest copy.
    if (e.code == 'failed-precondition') return null;
    rethrow;
  }
}

/// Opens [uri] in a new browser tab (web) or externally (io targets).
Future<bool> _openExternal(Uri uri) => launcher.launchUrl(
      uri,
      mode: launcher.LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

/// Web v1: RevenueCat Web Purchase Links. Checkout is the RC-hosted
/// page at `<purchase link>/<app_user_id>`; the monthly/annual choice
/// happens there, payment runs through Stripe underneath. Manage/cancel
/// is the RevenueCat customer portal, reached through the
/// getManageSubscriptionUrl callable.
class WebBillingService implements BillingService {
  const WebBillingService({
    this.purchaseLinkBase = kRcPurchaseLinkBase,
    this.openUrl = _openExternal,
    this.fetchManageUrl = fetchManageSubscriptionUrl,
  });

  /// See [kRcPurchaseLinkBase].
  final String purchaseLinkBase;

  /// Injectable for tests; production opens a new tab.
  final Future<bool> Function(Uri uri) openUrl;

  /// Portal-URL source; null only in builds with no billing backend.
  final ManageBillingUrlFetcher? fetchManageUrl;

  @override
  bool get checkoutConfigured => purchaseLinkBase.isNotEmpty;

  @override
  bool get manageBillingConfigured => fetchManageUrl != null;

  /// The exact checkout URL: purchase link + uid path segment, plus a
  /// prefilled (non-editable) email when known, so the Stripe receipt
  /// and the Firebase account can't drift apart.
  Uri checkoutUri({required String uid, String? email}) {
    final base = purchaseLinkBase.endsWith('/')
        ? purchaseLinkBase.substring(0, purchaseLinkBase.length - 1)
        : purchaseLinkBase;
    final uri = Uri.parse('$base/${Uri.encodeComponent(uid)}');
    if (email == null || email.isEmpty) return uri;
    return uri.replace(queryParameters: {'email': email});
  }

  @override
  Future<bool> openCheckout({required String uid, String? email}) async {
    if (!checkoutConfigured) return false;
    return openUrl(checkoutUri(uid: uid, email: email));
  }

  /// False when there is no portal URL (no subscription, backend
  /// unreachable) or the tab could not open; the caller shows the
  /// receipt-email fallback copy. Never throws into the screen.
  @override
  Future<bool> openManageBilling({required String uid}) async {
    final fetch = fetchManageUrl;
    if (fetch == null) return false;
    try {
      final url = await fetch();
      if (url == null) return false;
      return await openUrl(Uri.parse(url));
    } on Object {
      return false;
    }
  }
}
