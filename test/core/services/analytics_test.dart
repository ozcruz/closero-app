import 'dart:async';

import 'package:closero_app/core/services/analytics_events.dart';
import 'package:closero_app/core/services/analytics_observer.dart';
import 'package:closero_app/core/services/analytics_service.dart';
import 'package:closero_app/features/auth/application/auth_providers.dart';
import 'package:closero_app/features/auth/domain/user_doc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/recording_analytics_service.dart';

UserDoc _doc(Entitlement entitlement) => UserDoc(
      uid: 'uid-1',
      email: 'rep@example.com',
      displayName: 'Rep',
      entitlement: entitlement,
      sessionsUsed: 0,
      usageMonth: '2026-07',
    );

void main() {
  group('scoreBandLabel', () {
    test('buckets on the ring thresholds (>=75 / 60-74 / <60)', () {
      expect(scoreBandLabel(90), 'high');
      expect(scoreBandLabel(75), 'high');
      expect(scoreBandLabel(74), 'mid');
      expect(scoreBandLabel(60), 'mid');
      expect(scoreBandLabel(59), 'low');
      expect(scoreBandLabel(0), 'low');
    });
  });

  group('SignupMethod.fromProviderIds', () {
    test('maps provider ids to coarse method labels', () {
      expect(SignupMethod.fromProviderIds(['password']), SignupMethod.email);
      expect(SignupMethod.fromProviderIds(['google.com']), SignupMethod.google);
      expect(SignupMethod.fromProviderIds(['apple.com']), SignupMethod.apple);
      expect(SignupMethod.fromProviderIds(['phone']), SignupMethod.other);
      expect(SignupMethod.fromProviderIds(const []), SignupMethod.other);
    });
  });

  test('analyticsServiceProvider is a no-op when no key is compiled in', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Tests build without --dart-define=POSTHOG_API_KEY, so the default
    // must be the no-op, never PostHog.
    expect(container.read(analyticsServiceProvider), isA<NoopAnalyticsService>());
  });

  group('analyticsObserverProvider purchase_succeeded', () {
    late StreamController<UserDoc?> userDoc;
    late RecordingAnalyticsService analytics;

    ProviderContainer build() {
      final container = ProviderContainer(overrides: [
        analyticsServiceProvider.overrideWithValue(analytics),
        // Signed out throughout: the userDoc stream is driven directly,
        // so no fake firebase User is needed.
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        userDocProvider.overrideWith((ref) => userDoc.stream),
      ]);
      addTearDown(container.dispose);
      // Keep the observer alive for the test the way ClosApp does with
      // ref.watch, so its ref.listen wiring stays subscribed.
      final sub = container.listen(analyticsObserverProvider, (_, _) {});
      addTearDown(sub.close);
      return container;
    }

    setUp(() {
      userDoc = StreamController<UserDoc?>();
      analytics = RecordingAnalyticsService();
    });

    tearDown(() => userDoc.close());

    int purchases() =>
        analytics.where(AnalyticsEvents.purchaseSucceeded).length;

    test('fires once on a settled free -> closer flip', () async {
      build();
      userDoc.add(_doc(Entitlement.free));
      await pumpEventQueue();
      expect(purchases(), 0);

      userDoc.add(_doc(Entitlement.closer));
      await pumpEventQueue();
      expect(purchases(), 1);
    });

    test('does NOT fire for a returning subscriber (loads straight to closer)',
        () async {
      build();
      userDoc.add(_doc(Entitlement.closer));
      await pumpEventQueue();
      expect(purchases(), 0);
    });

    test('does NOT fire while staying free', () async {
      build();
      userDoc.add(_doc(Entitlement.free));
      userDoc.add(_doc(Entitlement.free));
      await pumpEventQueue();
      expect(purchases(), 0);
    });

    test('does not re-fire once already closer', () async {
      build();
      userDoc.add(_doc(Entitlement.free));
      userDoc.add(_doc(Entitlement.closer));
      userDoc.add(_doc(Entitlement.closer));
      await pumpEventQueue();
      expect(purchases(), 1);
    });
  });
}
