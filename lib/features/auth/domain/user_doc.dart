/// The users/{uid} document, shared with the site (same Firebase
/// project). Server-owned fields (entitlement, trialEndsAt,
/// sessionsUsed, usageMonth) are read-only in this app; they flip via
/// the RevenueCat webhook and Cloud Functions.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// PAID plan entitlement, exactly as the webhook writes it. Unknown or
/// missing values read as [free] so a malformed doc can never unlock
/// paid content. This is the payment state only; what the user can
/// currently ACCESS is [PlanPhase] / the effective tier, which also
/// honors the trial window.
enum Entitlement {
  free,
  closer;

  static Entitlement parse(Object? raw) =>
      raw == 'closer' ? Entitlement.closer : Entitlement.free;

  /// Display name, e.g. for the sidebar plan line.
  String get label => this == Entitlement.closer ? 'Closer' : 'Free';
}

/// Where the user sits in the reverse-trial model (pricing doc
/// 2026-07-11). The server enforces the matching caps in
/// startSimSession; the client only reads and displays.
enum PlanPhase {
  /// Inside the trial window: full Closer-level access, not paying.
  trial,

  /// Trial over, not paying: the limited free tier.
  free,

  /// Paying (entitlement == closer).
  closer;

  /// Display name for plan lines and badges.
  String get label => switch (this) {
        PlanPhase.trial => 'Free trial',
        PlanPhase.free => 'Free',
        PlanPhase.closer => 'Closer',
      };
}

class UserDoc {
  const UserDoc({
    required this.uid,
    this.email,
    this.displayName,
    required this.entitlement,
    required this.sessionsUsed,
    this.usageMonth,
    this.trialEndsAt,
  });

  factory UserDoc.fromMap(String uid, Map<String, dynamic> data) => UserDoc(
        uid: uid,
        email: data['email'] as String?,
        displayName: data['displayName'] as String?,
        entitlement: Entitlement.parse(data['entitlement']),
        sessionsUsed: (data['sessionsUsed'] as num?)?.toInt() ?? 0,
        usageMonth: data['usageMonth'] as String?,
        trialEndsAt: parseTrialEndsAt(data['trialEndsAt']),
      );

  /// trialEndsAt is server-written (Auth trigger / callable backfill)
  /// and may arrive as a Firestore Timestamp, a DateTime, or millis.
  /// Anything else reads as null, which the app treats as "no trial":
  /// a malformed value can never extend access.
  static DateTime? parseTrialEndsAt(Object? raw) => switch (raw) {
        Timestamp() => raw.toDate(),
        DateTime() => raw,
        num() => DateTime.fromMillisecondsSinceEpoch(raw.toInt()),
        _ => null,
      };

  final String uid;
  final String? email;
  final String? displayName;
  final Entitlement entitlement;
  final int sessionsUsed;
  final String? usageMonth;

  /// End of the full-access trial window. Null means the server has not
  /// written it yet (backfill pending), which reads as no trial.
  final DateTime? trialEndsAt;
}
