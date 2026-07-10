/// The users/{uid} document, shared with the site (same Firebase
/// project). Server-owned fields (entitlement, sessionsUsed, usageMonth)
/// are read-only in this app; they flip via the RevenueCat webhook and
/// Cloud Functions.
library;

/// Plan entitlement. Unknown or missing values read as [free] so a
/// malformed doc can never unlock paid content.
enum Entitlement {
  free,
  closer;

  static Entitlement parse(Object? raw) =>
      raw == 'closer' ? Entitlement.closer : Entitlement.free;

  /// Display name, e.g. for the sidebar plan line.
  String get label => this == Entitlement.closer ? 'Closer' : 'Free';
}

class UserDoc {
  const UserDoc({
    required this.uid,
    this.email,
    this.displayName,
    required this.entitlement,
    required this.sessionsUsed,
    this.usageMonth,
  });

  factory UserDoc.fromMap(String uid, Map<String, dynamic> data) => UserDoc(
        uid: uid,
        email: data['email'] as String?,
        displayName: data['displayName'] as String?,
        entitlement: Entitlement.parse(data['entitlement']),
        sessionsUsed: (data['sessionsUsed'] as num?)?.toInt() ?? 0,
        usageMonth: data['usageMonth'] as String?,
      );

  final String uid;
  final String? email;
  final String? displayName;
  final Entitlement entitlement;
  final int sessionsUsed;
  final String? usageMonth;
}
