import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/domain/user_doc.dart';
import 'analytics_events.dart';
import 'analytics_service.dart';

/// App-lifetime analytics side effects that no single screen owns:
/// identify/reset as the user signs in and out, and purchase_succeeded
/// when the entitlement flips. Kept alive by ClosApp watching it, so it
/// runs for the whole session regardless of the current screen.
///
/// purchase_succeeded fires from the Firestore entitlement flip
/// (users/{uid}.entitlement free -> closer), never from the checkout
/// click, per the analytics contract. It fires ONLY on a settled
/// free->closer transition on the same identity: a returning subscriber
/// whose doc loads straight to closer is not a purchase, and neither is
/// a closer signing in after a free user signed out on the same device.
final analyticsObserverProvider = Provider<void>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);

  // The last SETTLED entitlement (from a loaded doc) for the current
  // identity. Null while unknown, so a loading -> data step and an
  // identity switch never read as a purchase.
  Entitlement? lastSettled;

  // Identify by uid on sign-in; reset on sign-out. fireImmediately so a
  // session already signed in when this first mounts still identifies.
  ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
    final uid = next.value?.uid;
    final previousUid = previous?.value?.uid;
    if (uid != previousUid) {
      // New (or absent) identity: entitlement history restarts, so the
      // next doc load is a baseline, not a purchase.
      lastSettled = null;
    }
    if (uid != null && uid != previousUid) {
      analytics.identify(uid);
    } else if (uid == null && previousUid != null) {
      analytics.reset();
    }
  }, fireImmediately: true);

  ref.listen<AsyncValue<UserDoc?>>(userDocProvider, (previous, next) {
    if (next case AsyncData(:final value)) {
      final resolved = value?.entitlement ?? Entitlement.free;
      if (lastSettled == Entitlement.free && resolved == Entitlement.closer) {
        analytics.capture(AnalyticsEvents.purchaseSucceeded);
      }
      lastSettled = resolved;
    }
  }, fireImmediately: true);
});
