import 'package:closero_app/core/services/clock.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 16, 12);

  UserDoc user({
    Entitlement entitlement = Entitlement.free,
    DateTime? trialEndsAt,
  }) =>
      UserDoc(
        uid: 'uid-1',
        entitlement: entitlement,
        sessionsUsed: 0,
        trialEndsAt: trialEndsAt,
      );

  ProviderContainer container({UserDoc? doc}) {
    final c = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(() => now),
      userDocProvider.overrideWith((ref) => Stream.value(doc)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle(ProviderContainer c) async {
    // Hold a subscription so the stream provider stays alive, then let
    // the Stream.value microtask deliver the doc.
    c.listen(userDocProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
  }

  group('planPhaseProvider / effectiveTierProvider', () {
    test('paying user is closer regardless of the trial window', () async {
      final c = container(
        doc: user(
          entitlement: Entitlement.closer,
          trialEndsAt: now.subtract(const Duration(days: 30)),
        ),
      );
      await settle(c);
      expect(c.read(planPhaseProvider), PlanPhase.closer);
      expect(c.read(effectiveTierProvider), Entitlement.closer);
    });

    test('inside the trial window: trial phase, closer access', () async {
      final c = container(
        doc: user(trialEndsAt: now.add(const Duration(days: 3))),
      );
      await settle(c);
      expect(c.read(planPhaseProvider), PlanPhase.trial);
      expect(c.read(effectiveTierProvider), Entitlement.closer);
    });

    test('expired trial: free phase, free access', () async {
      final c = container(
        doc: user(trialEndsAt: now.subtract(const Duration(minutes: 1))),
      );
      await settle(c);
      expect(c.read(planPhaseProvider), PlanPhase.free);
      expect(c.read(effectiveTierProvider), Entitlement.free);
    });

    test('missing trialEndsAt never extends access', () async {
      final c = container(doc: user());
      await settle(c);
      expect(c.read(planPhaseProvider), PlanPhase.free);
      expect(c.read(effectiveTierProvider), Entitlement.free);
    });

    test('signed out / no doc reads as free', () async {
      final c = container();
      await settle(c);
      expect(c.read(planPhaseProvider), PlanPhase.free);
      expect(c.read(effectiveTierProvider), Entitlement.free);
    });
  });

  group('UserDoc.parseTrialEndsAt', () {
    test('accepts DateTime and millis, rejects junk', () {
      final date = DateTime.utc(2026, 7, 30);
      expect(UserDoc.parseTrialEndsAt(date), date);
      expect(
        UserDoc.parseTrialEndsAt(date.millisecondsSinceEpoch),
        DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch),
      );
      expect(UserDoc.parseTrialEndsAt('2026-07-30'), isNull);
      expect(UserDoc.parseTrialEndsAt(null), isNull);
    });
  });
}
