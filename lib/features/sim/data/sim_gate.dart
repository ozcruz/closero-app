import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Outcome of asking the server to start a sim session.
enum SimGateResult {
  /// The session may start (grant recorded server-side).
  allowed,

  /// Free-tier monthly cap reached: route to the Session limit screen.
  capReached,
}

/// The `startSimSession` callable, from day one: the client NEVER
/// decides the cap. Retries with the same requestId are idempotent
/// server-side and never double-count.
abstract interface class SimGate {
  Future<SimGateResult> requestStart({required String requestId});
}

/// Deployed v2 callable in us-central1 (closero-backend). Contract:
/// call with `{requestId}` matching `[A-Za-z0-9_-]{1,128}`; returns
/// `{allow: bool, reason?: 'cap'}`.
class CallableSimGate implements SimGate {
  CallableSimGate({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  @override
  Future<SimGateResult> requestStart({required String requestId}) async {
    final result = await _functions
        .httpsCallable('startSimSession')
        .call<Map<String, dynamic>>({'requestId': requestId});
    final allow = result.data['allow'] == true;
    if (allow) return SimGateResult.allowed;
    if (result.data['reason'] == 'cap') return SimGateResult.capReached;
    throw StateError('startSimSession denied: ${result.data}');
  }
}

/// Opaque idempotency key for one start attempt, within the callable's
/// `[A-Za-z0-9_-]{1,128}` charset.
String newSimRequestId() {
  final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final salt = Random().nextInt(1 << 30).toRadixString(36);
  return 'sim_$now$salt';
}

final simGateProvider = Provider<SimGate>((ref) => CallableSimGate());
