import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/billing_service.dart';

/// The platform billing implementation. Web v1 opens RevenueCat Web
/// Purchase Links; the iOS target overrides this with a
/// purchases_flutter-backed service without touching screens.
final billingServiceProvider =
    Provider<BillingService>((ref) => const WebBillingService());
