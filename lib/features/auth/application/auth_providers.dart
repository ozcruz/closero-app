import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/auth_service.dart';
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

/// Current entitlement, defaulting to free while loading or signed out
/// so paid content can never unlock by accident.
final entitlementProvider = Provider<Entitlement>(
  (ref) => ref.watch(userDocProvider).value?.entitlement ?? Entitlement.free,
);
