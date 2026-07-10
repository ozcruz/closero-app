import 'package:closero_app/core/routing/auth_guard.dart';
import 'package:flutter_test/flutter_test.dart';

String? redirect(
  String location, {
  bool signedIn = false,
  bool emailVerified = false,
}) =>
    authRedirect(
      signedIn: signedIn,
      emailVerified: emailVerified,
      uri: Uri.parse(location),
    );

void main() {
  group('signed out', () {
    test('protected routes go to login', () {
      expect(redirect('/'), '/login');
      expect(redirect('/settings'), '/login?from=%2Fsettings');
    });

    test('deep links survive the round trip through ?from', () {
      expect(redirect('/score/abc123'), '/login?from=%2Fscore%2Fabc123');
      expect(
        redirect('/score/abc123/transcript?moment=2'),
        '/login?from=${Uri.encodeQueryComponent('/score/abc123/transcript?moment=2')}',
      );
    });

    test('auth pages render', () {
      expect(redirect('/login'), isNull);
      expect(redirect('/signup'), isNull);
      expect(redirect('/reset-password'), isNull);
    });

    test('verify-email without a session goes to login', () {
      expect(redirect('/verify-email'), '/login');
    });
  });

  group('signed in, email not verified', () {
    String? r(String location) => redirect(location, signedIn: true);

    test('protected routes go to verify, keeping the destination', () {
      expect(r('/'), '/verify-email');
      expect(r('/score/abc'), '/verify-email?from=%2Fscore%2Fabc');
    });

    test('verify-email renders', () {
      expect(r('/verify-email'), isNull);
      expect(r('/verify-email?from=%2Fscore%2Fabc'), isNull);
    });

    test('auth pages forward their ?from to verify', () {
      expect(
        r('/login?from=%2Fscore%2Fabc'),
        '/verify-email?from=%2Fscore%2Fabc',
      );
      expect(r('/login'), '/verify-email');
    });
  });

  group('signed in and verified', () {
    String? r(String location) =>
        redirect(location, signedIn: true, emailVerified: true);

    test('app routes render', () {
      expect(r('/'), isNull);
      expect(r('/settings'), isNull);
      expect(r('/score/abc'), isNull);
    });

    test('auth pages bounce to the dashboard', () {
      expect(r('/login'), '/');
      expect(r('/signup'), '/');
      expect(r('/verify-email'), '/');
    });

    test('auth pages honor a safe ?from', () {
      expect(r('/login?from=%2Fscore%2Fabc'), '/score/abc');
    });

    test('external or malformed ?from is dropped', () {
      expect(r('/login?from=https%3A%2F%2Fevil.example'), '/');
      expect(r('/login?from=%2F%2Fevil.example'), '/');
    });
  });

  group('sanitizeFrom', () {
    test('accepts in-app paths only', () {
      expect(sanitizeFrom('/score/abc'), '/score/abc');
      expect(sanitizeFrom('https://evil.example'), isNull);
      expect(sanitizeFrom('//evil.example'), isNull);
      expect(sanitizeFrom(null), isNull);
    });
  });
}
