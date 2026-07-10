import 'package:closero_app/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// In-memory stand-in so screens can be pumped without a Firebase app.
/// Records calls; every operation succeeds unless [failWith] is set.
class FakeAuthService implements AuthService {
  FakeAuthService();

  /// When set, auth operations throw this instead of succeeding.
  Exception? failWith;

  final List<String> calls = [];
  String? lastEmail;
  String? lastPassword;
  bool verified = false;

  void _record(String call) {
    calls.add(call);
    final error = failWith;
    if (error != null) throw error;
  }

  @override
  Stream<User?> userChanges() => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    _record('signInWithEmail');
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    _record('signUpWithEmail');
  }

  @override
  Future<void> signInWithGoogle() async => _record('signInWithGoogle');

  @override
  Future<void> signInWithApple() async => _record('signInWithApple');

  @override
  Future<void> sendPasswordReset(String email) async {
    lastEmail = email;
    _record('sendPasswordReset');
  }

  @override
  Future<void> resendVerificationEmail() async =>
      _record('resendVerificationEmail');

  @override
  Future<bool> reloadAndCheckVerified() async {
    calls.add('reloadAndCheckVerified');
    return verified;
  }

  @override
  Future<void> signOut() async => _record('signOut');

  @override
  Future<void> ensureUserDoc(User? user) async => _record('ensureUserDoc');
}
