import 'package:closero_app/core/services/billing_service.dart';
import 'package:closero_app/features/billing/presentation/session_limit_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebBillingService', () {
    test('checkout URL is purchase link + uid, with prefilled email', () {
      const service = WebBillingService(
        purchaseLinkBase: 'https://pay.rev.cat/abc123',
      );
      expect(
        service.checkoutUri(uid: 'uid-1', email: 'rep@company.com').toString(),
        'https://pay.rev.cat/abc123/uid-1?email=rep%40company.com',
      );
    });

    test('trailing slash on the base does not double up', () {
      const service = WebBillingService(
        purchaseLinkBase: 'https://pay.rev.cat/abc123/',
      );
      expect(
        service.checkoutUri(uid: 'uid-1').toString(),
        'https://pay.rev.cat/abc123/uid-1',
      );
    });

    test('unconfigured build reports itself and never launches', () async {
      final launched = <Uri>[];
      final service = WebBillingService(
        // Explicit empty base / null fetcher: the real defaults bake in
        // the live link and the callable, so the unconfigured case has
        // to be constructed on purpose.
        purchaseLinkBase: '',
        fetchManageUrl: null,
        openUrl: (uri) async {
          launched.add(uri);
          return true;
        },
      );
      expect(service.checkoutConfigured, isFalse);
      expect(service.manageBillingConfigured, isFalse);
      expect(await service.openCheckout(uid: 'uid-1'), isFalse);
      expect(await service.openManageBilling(uid: 'uid-1'), isFalse);
      expect(launched, isEmpty);
    });

    test('manage billing opens the fetched portal URL', () async {
      final launched = <Uri>[];
      final service = WebBillingService(
        fetchManageUrl: () async => 'https://pay.rev.cat/portal/abc',
        openUrl: (uri) async {
          launched.add(uri);
          return true;
        },
      );
      expect(service.manageBillingConfigured, isTrue);
      expect(await service.openManageBilling(uid: 'uid-1'), isTrue);
      expect(launched.single.toString(), 'https://pay.rev.cat/portal/abc');
    });

    test('manage billing reports false when there is no portal URL',
        () async {
      final launched = <Uri>[];
      final service = WebBillingService(
        fetchManageUrl: () async => null,
        openUrl: (uri) async {
          launched.add(uri);
          return true;
        },
      );
      expect(await service.openManageBilling(uid: 'uid-1'), isFalse);
      expect(launched, isEmpty);
    });

    test('manage billing swallows fetcher errors as false, never throws',
        () async {
      final service = WebBillingService(
        fetchManageUrl: () async => throw Exception('backend down'),
        openUrl: (uri) async => true,
      );
      expect(await service.openManageBilling(uid: 'uid-1'), isFalse);
    });

    test('configured checkout opens the exact URL', () async {
      final launched = <Uri>[];
      final service = WebBillingService(
        purchaseLinkBase: 'https://pay.rev.cat/abc123',
        openUrl: (uri) async {
          launched.add(uri);
          return true;
        },
      );
      expect(await service.openCheckout(uid: 'uid-9'), isTrue);
      expect(launched.single.toString(), 'https://pay.rev.cat/abc123/uid-9');
    });
  });

  group('freeCapResetLabel', () {
    test('mid-year resets on the first of next month', () {
      expect(freeCapResetLabel(DateTime(2026, 7, 10)), 'August 1');
    });

    test('December rolls over to January', () {
      expect(freeCapResetLabel(DateTime(2026, 12, 31)), 'January 1');
    });
  });
}
