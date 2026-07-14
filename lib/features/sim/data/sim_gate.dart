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

/// Idempotency key for one start attempt AND the address of the live
/// session. A UUIDv4 (secure random): the broker addresses the Durable
/// Object and sessions/{id} by it and enforces length >= 20, so its
/// entropy is the guessing protection. Passed to startSimSession and,
/// unchanged, to the broker's WSS URL + hello.
String newSimRequestId() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
  String hex(int start, int end) =>
      bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

final simGateProvider = Provider<SimGate>((ref) => CallableSimGate());
