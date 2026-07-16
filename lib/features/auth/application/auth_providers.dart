import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/clock.dart';
import '../domain/user_doc.dart';

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    ref.watch(analyticsServiceProvider),
  ),
);

/// The signed-in Firebase user. Uses userChanges so reloads (e.g. email
/// verification) propagate, not just sign-in/out.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).userChanges(),
);

/// The signed-in user's email, for screens that only need to display it.
final currentUserEmailProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).value?.email,
);

/// Live users/{uid} doc. Read-only: the client never writes entitlement,
/// sessionsUsed, or usageMonth; it only watches the server flip them.
final userDocProvider = StreamProvider<UserDoc?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream<UserDoc?>.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) {
    final data = snap.data();
    return data == null ? null : UserDoc.fromMap(snap.id, data);
  });
});

/// Current PAID entitlement, defaulting to free while loading or signed
/// out so paid content can never unlock by accident. Purchase-flip
/// listeners (upgrade flow, analytics) read this; access gates read
/// [effectiveTierProvider] instead, which also honors the trial window.
final entitlementProvider = Provider<Entitlement>(
  (ref) => ref.watch(userDocProvider).value?.entitlement ?? Entitlement.free,
);

/// Reverse-trial phase: closer when paying, trial while now is inside
/// the server-written trialEndsAt window, free otherwise (including
/// while loading, signed out, or before the backfill has written
/// trialEndsAt: a missing date never extends access).
///
/// The clock is read once per recompute; an expiry mid-session shows up
/// on the next doc change or navigation rebuild, and the server caps
/// are what actually enforce the window.
final planPhaseProvider = Provider<PlanPhase>((ref) {
  if (ref.watch(entitlementProvider) == Entitlement.closer) {
    return PlanPhase.closer;
  }
  final trialEndsAt = ref.watch(userDocProvider).value?.trialEndsAt;
  if (trialEndsAt != null &&
      ref.watch(clockProvider)().isBefore(trialEndsAt)) {
    return PlanPhase.trial;
  }
  return PlanPhase.free;
});

/// What the user can ACCESS right now: closer if paying OR trialing.
/// Every content gate (B2B library, methodologies) reads this, never
/// [entitlementProvider] directly.
final effectiveTierProvider = Provider<Entitlement>(
  (ref) => ref.watch(planPhaseProvider) == PlanPhase.free
      ? Entitlement.free
      : Entitlement.closer,
);
