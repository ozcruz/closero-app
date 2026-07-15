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

/// Reasons the backend `abortSimSession` will refund (REFUNDABLE_REASONS
/// on the server). A normal 'user_hangup' is deliberately NOT here: a
/// hang-up is a real session that keeps its cap credit and its score.
const Set<String> kRefundableAbortReasons = {
  'socket_drop',
  'mic_failure',
  'launch_failure',
};

/// Outcome of asking the server to abort and refund a granted session.
class SimAbortResult {
  const SimAbortResult({required this.refunded});

  /// True only when the server confirms the free-cap credit was returned.
  /// The "this didn't count against your sessions" copy shows on true
  /// alone: if the abort call fails, we never claim nothing was used.
  final bool refunded;
}

/// The `abortSimSession` callable: for a session that was GRANTED (the
/// gate allowed it) but then failed for a technical reason, this refunds
/// the free-cap credit so a dropped call never burns a session. The
/// broker refunds post-`ready` faults server-side; this covers the
/// client-side failures it cannot see (socket drop, mic failure).
abstract interface class SimAbort {
  /// Idempotent on [requestId]: safe to call more than once for the same
  /// failed attempt; the server refunds at most once.
  Future<SimAbortResult> requestAbort({
    required String requestId,
    required String reason,
  });
}

/// Deployed callable in us-central1 (closero-backend). Contract: call
/// with `{requestId, reason}`; returns `{refunded: bool}`. Idempotent on
/// requestId server-side.
class CallableSimAbort implements SimAbort {
  CallableSimAbort({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  @override
  Future<SimAbortResult> requestAbort({
    required String requestId,
    required String reason,
  }) async {
    // Enforce the allowlist client-side too, so a stray non-refundable
    // reason (a hang-up) can never reach the server as an abort.
    if (!kRefundableAbortReasons.contains(reason)) {
      return const SimAbortResult(refunded: false);
    }
    final result = await _functions
        .httpsCallable('abortSimSession')
        .call<Map<String, dynamic>>({
      'requestId': requestId,
      'reason': reason,
    });
    return SimAbortResult(refunded: result.data['refunded'] == true);
  }
}

final simAbortProvider = Provider<SimAbort>((ref) => CallableSimAbort());

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
