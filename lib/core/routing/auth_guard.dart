import 'app_routes.dart';

/// The screens a signed-out visitor may see.
const Set<String> _authPaths = {
  LoginRoute.path,
  SignupRoute.path,
  ResetPasswordRoute.path,
};

/// Router redirect policy, kept pure for testing:
///
/// - Signed out: everything except login/signup/reset goes to login,
///   carrying the attempted location in ?from so deep links (e.g.
///   /score/abc) survive the round trip.
/// - Signed in, email not verified: everything goes to /verify-email
///   (SSO accounts arrive verified, so this only gates email/password).
/// - Signed in and verified: the auth screens bounce to ?from or the
///   dashboard; everything else renders.
///
/// Returns the location to redirect to, or null to allow navigation.
String? authRedirect({
  required bool signedIn,
  required bool emailVerified,
  required Uri uri,
}) {
  final path = uri.path;
  final onAuthPage = _authPaths.contains(path);
  final onVerifyPage = path == VerifyEmailRoute.path;
  final from = sanitizeFrom(uri.queryParameters['from']);

  if (!signedIn) {
    if (onAuthPage) return null;
    if (onVerifyPage) return LoginRoute(from: from).location;
    final target = uri.toString();
    return LoginRoute(from: target == DashboardRoute.path ? null : target)
        .location;
  }

  if (!emailVerified) {
    if (onVerifyPage) return null;
    // Keep the pre-auth destination alive across the verify step.
    final target =
        onAuthPage ? from : (path == DashboardRoute.path ? null : uri.toString());
    return VerifyEmailRoute(from: sanitizeFrom(target)).location;
  }

  if (onAuthPage || onVerifyPage) {
    return from ?? DashboardRoute.path;
  }
  return null;
}

/// Only in-app absolute paths may round-trip through ?from; anything
/// else (external URLs, scheme-relative //host tricks) is dropped.
String? sanitizeFrom(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  return from;
}
