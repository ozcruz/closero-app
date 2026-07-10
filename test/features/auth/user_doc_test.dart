import 'package:closero_app/core/services/auth_service.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Entitlement.parse', () {
    test('closer parses', () {
      expect(Entitlement.parse('closer'), Entitlement.closer);
    });

    test('anything else reads as free so paid content never unlocks by '
        'accident', () {
      expect(Entitlement.parse('free'), Entitlement.free);
      expect(Entitlement.parse(null), Entitlement.free);
      expect(Entitlement.parse('CLOSER'), Entitlement.free);
      expect(Entitlement.parse(42), Entitlement.free);
    });

    test('labels', () {
      expect(Entitlement.free.label, 'Free');
      expect(Entitlement.closer.label, 'Closer');
    });
  });

  group('UserDoc.fromMap', () {
    test('parses a full doc', () {
      final doc = UserDoc.fromMap('uid-1', {
        'email': 'rep@company.com',
        'displayName': 'Sandra Voss',
        'entitlement': 'closer',
        'sessionsUsed': 3,
        'usageMonth': '2026-07',
        'rcAppUserId': 'uid-1',
      });
      expect(doc.uid, 'uid-1');
      expect(doc.email, 'rep@company.com');
      expect(doc.displayName, 'Sandra Voss');
      expect(doc.entitlement, Entitlement.closer);
      expect(doc.sessionsUsed, 3);
      expect(doc.usageMonth, '2026-07');
    });

    test('tolerates missing fields', () {
      final doc = UserDoc.fromMap('uid-2', const {});
      expect(doc.email, isNull);
      expect(doc.displayName, isNull);
      expect(doc.entitlement, Entitlement.free);
      expect(doc.sessionsUsed, 0);
      expect(doc.usageMonth, isNull);
    });

    test('sessionsUsed accepts Firestore numeric types', () {
      expect(UserDoc.fromMap('u', const {'sessionsUsed': 2.0}).sessionsUsed, 2);
    });
  });

  group('AuthService.currentUsageMonth', () {
    test('zero-pads the month', () {
      expect(AuthService.currentUsageMonth(DateTime(2026, 7, 10)), '2026-07');
      expect(AuthService.currentUsageMonth(DateTime(2026, 11)), '2026-11');
    });
  });
}
