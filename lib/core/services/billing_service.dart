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

/// Opens [uri] in a new browser tab (web) or externally (io targets).
Future<bool> _openExternal(Uri uri) => launcher.launchUrl(
      uri,
      mode: launcher.LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

/// Web v1: RevenueCat Web Purchase Links. Checkout is the RC-hosted
/// page at `<purchase link>/<app_user_id>`; the monthly/annual choice
/// happens there, payment runs through Stripe underneath.
class WebBillingService implements BillingService {
  const WebBillingService({
    this.purchaseLinkBase = kRcPurchaseLinkBase,
    this.manageBillingUrl = kRcManageBillingUrl,
    this.openUrl = _openExternal,
  });

  /// See [kRcPurchaseLinkBase].
  final String purchaseLinkBase;

  /// See [kRcManageBillingUrl].
  final String manageBillingUrl;

  /// Injectable for tests; production opens a new tab.
  final Future<bool> Function(Uri uri) openUrl;

  @override
  bool get checkoutConfigured => purchaseLinkBase.isNotEmpty;

  @override
  bool get manageBillingConfigured => manageBillingUrl.isNotEmpty;

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

  @override
  Future<bool> openManageBilling({required String uid}) async {
    if (!manageBillingConfigured) return false;
    return openUrl(Uri.parse(manageBillingUrl));
  }
}
