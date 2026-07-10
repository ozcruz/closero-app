import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication for the app origin (app.closero.app owns auth; the
/// marketing site only links here, see context/hosting-and-auth.md).
///
/// Firestore contract: this service may CREATE users/{uid} on first
/// sign-in, and only with the server-mandated defaults (entitlement
/// 'free', sessionsUsed 0, rcAppUserId == uid; enforced by
/// firestore.rules). It never updates entitlement, sessionsUsed, or
/// usageMonth; those flip server-side via the RevenueCat webhook and
/// Cloud Functions.
class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Emits on sign-in/out and on user reloads, so the router guard also
  /// reacts to emailVerified flipping.
  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await ensureUserDoc(cred.user);
  }

  /// Creates the account and sends the verification email.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await ensureUserDoc(cred.user);
    await cred.user?.sendEmailVerification();
  }

  /// Web uses the Firebase popup flow directly; no google_sign_in
  /// package needed. The iOS target swaps in a native flow later.
  Future<void> signInWithGoogle() async {
    if (!kIsWeb) {
      throw UnsupportedError('Google sign-in ships with the iOS target.');
    }
    final cred = await _auth.signInWithPopup(GoogleAuthProvider());
    await ensureUserDoc(cred.user);
  }

  /// Behind [kAppleSsoEnabled]; no Apple Developer account yet.
  Future<void> signInWithApple() async {
    if (!kIsWeb) {
      throw UnsupportedError('Apple sign-in ships with the iOS target.');
    }
    final cred = await _auth.signInWithPopup(OAuthProvider('apple.com'));
    await ensureUserDoc(cred.user);
  }

  /// Treats user-not-found as success so the form can't be used to probe
  /// which emails have accounts.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found') rethrow;
    }
  }

  Future<void> resendVerificationEmail() async =>
      _auth.currentUser?.sendEmailVerification();

  /// Reloads the current user and reports whether the email is now
  /// verified. Reload emits on [userChanges], which also refreshes the
  /// router guard.
  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() => _auth.signOut();

  /// Sets the display name on the auth profile and users/{uid}
  /// (onboarding step 2, settings profile). displayName is
  /// client-owned; server-owned fields are never touched here.
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName);
    await _firestore.collection('users').doc(user.uid).update({
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Creates users/{uid} on first sign-in if it doesn't exist yet.
  /// Idempotent and non-throwing so it never blocks the auth flow;
  /// mirrors the site's ensureUserDoc.
  Future<void> ensureUserDoc(User? user) async {
    if (user == null) return;
    try {
      final ref = _firestore.collection('users').doc(user.uid);
      final snap = await ref.get();
      if (snap.exists) return;
      await ref.set({
        'email': user.email,
        'displayName': user.displayName,
        // The only values firestore.rules accept from a client create.
        'entitlement': 'free',
        'sessionsUsed': 0,
        'rcAppUserId': user.uid,
        'usageMonth': currentUsageMonth(DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Object catch (e) {
      debugPrint('ensureUserDoc failed: $e');
    }
  }

  /// Month key for the free-tier usage counter, e.g. "2026-07".
  @visibleForTesting
  static String currentUsageMonth(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

/// Short, human messages for auth failures, ported from the site's
/// authMessage map. Firebase Flutter error codes come without the
/// "auth/" prefix; strip it defensively anyway.
String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Something went wrong. Please try again.';
  }
  final code = error.code.replaceFirst('auth/', '');
  return switch (code) {
    'invalid-email' => "That email doesn't look right.",
    'missing-password' => 'Enter your password.',
    'weak-password' => 'Password must be at least 8 characters.',
    'email-already-in-use' =>
      'An account already exists for this email. Try logging in.',
    'invalid-credential' ||
    'wrong-password' =>
      'Email or password is incorrect.',
    'user-not-found' => 'No account found for that email.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'popup-closed-by-user' ||
    'cancelled-popup-request' =>
      'Sign-in window closed before finishing.',
    'popup-blocked' =>
      'Your browser blocked the sign-in popup. Allow popups and retry.',
    'network-request-failed' =>
      'Network problem. Check your connection and retry.',
    _ => 'Something went wrong. Please try again.',
  };
}
