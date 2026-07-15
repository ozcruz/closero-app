import 'dart:async';

import 'package:closero_app/features/scoring/domain/session_doc.dart';
import 'package:closero_app/features/sim/application/sim_controller.dart';
import 'package:closero_app/features/sim/data/live_sim_session.dart';
import 'package:closero_app/features/sim/data/sim_gate.dart';
import 'package:closero_app/features/sim/domain/sim_session.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGate implements SimGate {
  _FakeGate(this.results);

  final List<SimGateResult> results;
  final List<String> requestIds = [];

  @override
  Future<SimGateResult> requestStart({required String requestId}) async {
    requestIds.add(requestId);
    if (results.isEmpty) throw Exception('gate down');
    return results.removeAt(0);
  }
}

class _FakeSession implements SimSession {
  final transcriptCtrl = StreamController<Utterance>.broadcast();
  final coachingCtrl = StreamController<SimCoachingEvent>.broadcast();
  final inputCtrl = StreamController<double>.broadcast();
  final outputCtrl = StreamController<double>.broadcast();
  bool started = false;
  bool disposed = false;
  bool? mutedState;
  String? endReason;

  @override
  Stream<Utterance> get transcript => transcriptCtrl.stream;
  @override
  Stream<SimCoachingEvent> get coaching => coachingCtrl.stream;
  @override
  Stream<double> get inputLevel => inputCtrl.stream;
  @override
  Stream<double> get outputLevel => outputCtrl.stream;

  @override
  Future<void> start() async => started = true;

  @override
  void setMuted({required bool muted}) => mutedState = muted;

  @override
  Future<SimResult> end({required String reason}) async {
    endReason = reason;
    return const SimResult(sessionId: 'scripted-cold-call');
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await Future.wait([
      transcriptCtrl.close(),
      coachingCtrl.close(),
      inputCtrl.close(),
      outputCtrl.close(),
    ]);
  }
}

/// A live-shaped session: reports link state and can end with an error
/// (a drop) or a result (a scored end), so the controller's aborted /
/// reconnect / refund paths are exercised without a broker.
class _FakeLiveSession
    implements SimSession, LinkStateReporting, ServerEndableSession {
  _FakeLiveSession() {
    endedCompleter.future.ignore();
  }

  final transcriptCtrl = StreamController<Utterance>.broadcast();
  final coachingCtrl = StreamController<SimCoachingEvent>.broadcast();
  final inputCtrl = StreamController<double>.broadcast();
  final outputCtrl = StreamController<double>.broadcast();
  final linkCtrl = StreamController<SimLinkState>.broadcast();
  final endedCompleter = Completer<SimResult>();

  bool started = false;
  bool disposed = false;
  Exception? startError;
  String? endReason;

  @override
  Stream<Utterance> get transcript => transcriptCtrl.stream;
  @override
  Stream<SimCoachingEvent> get coaching => coachingCtrl.stream;
  @override
  Stream<double> get inputLevel => inputCtrl.stream;
  @override
  Stream<double> get outputLevel => outputCtrl.stream;
  @override
  Stream<SimLinkState> get linkState => linkCtrl.stream;
  @override
  Future<SimResult> get ended => endedCompleter.future;

  @override
  Future<void> start() async {
    started = true;
    final err = startError;
    if (err != null) throw err;
  }

  @override
  void setMuted({required bool muted}) {}

  @override
  Future<SimResult> end({required String reason}) async {
    endReason = reason;
    return const SimResult(sessionId: 'sess-1');
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await Future.wait([
      transcriptCtrl.close(),
      coachingCtrl.close(),
      inputCtrl.close(),
      outputCtrl.close(),
      linkCtrl.close(),
    ]);
  }
}

class _FakeAbort implements SimAbort {
  _FakeAbort({this.refunded = true, this.throws = false});

  final bool refunded;
  final bool throws;
  final List<({String requestId, String reason})> calls = [];

  @override
  Future<SimAbortResult> requestAbort({
    required String requestId,
    required String reason,
  }) async {
    calls.add((requestId: requestId, reason: reason));
    if (throws) throw Exception('abort down');
    return SimAbortResult(refunded: refunded);
  }
}

void main() {
  test('cap response blocks without ever creating a session', () {
    fakeAsync((async) {
      var built = 0;
      final controller = SimController(
        gate: _FakeGate([SimGateResult.capReached]),
        createSession: (_) {
          built++;
          return _FakeSession();
        },
      );
      controller.start();
      async.flushMicrotasks();
      expect(controller.phase, SimPhase.capBlocked);
      expect(built, 0);
      controller.dispose();
    });
  });

  test('gate failure is startFailed and retry can recover', () {
    fakeAsync((async) {
      final gate = _FakeGate([]);
      final controller = SimController(
        gate: gate,
        createSession: (_) => _FakeSession(),
      );
      controller.start();
      async.flushMicrotasks();
      expect(controller.phase, SimPhase.startFailed);

      gate.results.add(SimGateResult.allowed);
      controller.retryStart();
      async.flushMicrotasks();
      expect(controller.phase, SimPhase.live);
      // Each attempt sends a fresh idempotency key.
      expect(gate.requestIds.toSet(), hasLength(2));
      controller.dispose();
    });
  });

  test('live session streams feed state and end routes to the result',
      () {
    fakeAsync((async) {
      final session = _FakeSession();
      final controller = SimController(
        gate: _FakeGate([SimGateResult.allowed]),
        createSession: (_) => session,
      );
      controller.start();
      async.flushMicrotasks();
      expect(controller.phase, SimPhase.live);
      expect(session.started, isTrue);

      async.elapse(const Duration(seconds: 3));
      expect(controller.elapsedSec, 3);

      session.transcriptCtrl.add(const Utterance(
        speaker: Speaker.persona,
        text: 'Hello.',
        tsMs: 1000,
      ));
      session.coachingCtrl.add(const SimHint(
        kind: MomentType.good,
        label: 'Rapport',
        note: 'Used her name, good start',
      ));
      session.coachingCtrl.add(const SimHint(
        kind: MomentType.warn,
        label: 'Tonality',
        note: 'Sentences ending on an uptick',
      ));
      session.coachingCtrl.add(const SimNextMove(
        title: 'Redirect',
        body: 'Bridge back to David.',
      ));
      session.outputCtrl.add(0.8);
      async.flushMicrotasks();

      expect(controller.transcript, hasLength(1));
      expect(controller.hints, hasLength(2));
      // Only good hints fill momentum dots.
      expect(controller.goodCount, 1);
      expect(controller.nextMove?.title, 'Redirect');
      expect(controller.personaSpeaking, isTrue);

      controller.endSession();
      async.flushMicrotasks();
      expect(controller.phase, SimPhase.ended);
      expect(controller.result?.sessionId, 'scripted-cold-call');
      // A normal hang-up, never a refundable abort reason.
      expect(session.endReason, 'user_hangup');
      controller.dispose();
    });
  });

  test('reconnecting pauses the call clock and live resumes it', () {
    fakeAsync((async) {
      final session = _FakeLiveSession();
      final controller = SimController(
        gate: _FakeGate([SimGateResult.allowed]),
        createSession: (_) => session,
        abort: _FakeAbort(),
      );
      controller.start();
      async.flushMicrotasks();
      expect(controller.phase, SimPhase.live);

      async.elapse(const Duration(seconds: 2));
      expect(controller.elapsedSec, 2);

      session.linkCtrl.add(SimLinkState.reconnecting);
      async.flushMicrotasks();
      expect(controller.reconnecting, isTrue);
      // Clock paused: elapsed does not advance while the link is down.
      async.elapse(const Duration(seconds: 3));
      expect(controller.elapsedSec, 2);

      session.linkCtrl.add(SimLinkState.live);
      async.flushMicrotasks();
      expect(controller.reconnecting, isFalse);
      async.elapse(const Duration(seconds: 1));
      expect(controller.elapsedSec, 3);
      controller.dispose();
    });
  });

  test('a mid-call drop aborts and refunds on socket_drop', () {
    fakeAsync((async) {
      final session = _FakeLiveSession();
      final abort = _FakeAbort();
      final controller = SimController(
        gate: _FakeGate([SimGateResult.allowed]),
        createSession: (_) => session,
        abort: abort,
      );
      controller.start();
      async.flushMicrotasks();
      expect(controller.phase, SimPhase.live);

      session.endedCompleter
          .completeError(const SimStartException('socket_drop', 'gone'));
      async.flushMicrotasks();

      expect(controller.phase, SimPhase.aborted);
      expect(abort.calls.single.reason, 'socket_drop');
      expect(controller.refundConfirmed, isTrue);
      controller.dispose();
    });
  });

  test('a server-declined refund is not claimed as returned', () {
    fakeAsync((async) {
      final session = _FakeLiveSession();
      final abort = _FakeAbort(refunded: false);
      final controller = SimController(
        gate: _FakeGate([SimGateResult.allowed]),
        createSession: (_) => session,
        abort: abort,
      );
      controller.start();
      async.flushMicrotasks();
      session.endedCompleter
          .completeError(const SimStartException('socket_drop', 'gone'));
      async.flushMicrotasks();

      expect(controller.phase, SimPhase.aborted);
      // The server did not confirm a refund: refundConfirmed is false, so
      // the screen shows the neutral copy, never "it didn't count".
      expect(controller.refundConfirmed, isFalse);
      controller.dispose();
    });
  });

  test('a failed refund call never claims the session was returned', () {
    fakeAsync((async) {
      final session = _FakeLiveSession();
      final abort = _FakeAbort(throws: true);
      final controller = SimController(
        gate: _FakeGate([SimGateResult.allowed]),
        createSession: (_) => session,
        abort: abort,
      );
      controller.start();
      async.flushMicrotasks();
      session.endedCompleter
          .completeError(const SimStartException('socket_drop', 'gone'));
      async.flushMicrotasks();

      expect(controller.phase, SimPhase.aborted);
      expect(abort.calls, hasLength(1));
      // The abort call threw: never claim nothing was used.
      expect(controller.refundConfirmed, isNull);
      controller.dispose();
    });
  });

  test('a post-grant start failure aborts and refunds the burned grant', () {
    fakeAsync((async) {
      final session = _FakeLiveSession()
        ..startError = const SimStartException('mic_failure', 'capture failed');
      final abort = _FakeAbort();
      final controller = SimController(
        gate: _FakeGate([SimGateResult.allowed]),
        createSession: (_) => session,
        abort: abort,
      );
      controller.start();
      async.flushMicrotasks();

      expect(controller.phase, SimPhase.aborted);
      expect(abort.calls.single.reason, 'mic_failure');
      expect(controller.refundConfirmed, isTrue);
      controller.dispose();
    });
  });

  test('a scored end never refunds', () {
    fakeAsync((async) {
      final session = _FakeLiveSession();
      final abort = _FakeAbort();
      final controller = SimController(
        gate: _FakeGate([SimGateResult.allowed]),
        createSession: (_) => session,
        abort: abort,
      );
      controller.start();
      async.flushMicrotasks();
      session.endedCompleter.complete(const SimResult(sessionId: 'sess-1'));
      async.flushMicrotasks();

      expect(controller.phase, SimPhase.ended);
      expect(abort.calls, isEmpty);
      controller.dispose();
    });
  });

  test('retry after an abort disposes the old session and can recover', () {
    fakeAsync((async) {
      final sessions = <_FakeLiveSession>[];
      final controller = SimController(
        gate: _FakeGate([SimGateResult.allowed, SimGateResult.allowed]),
        createSession: (_) {
          final s = _FakeLiveSession();
          sessions.add(s);
          return s;
        },
        abort: _FakeAbort(),
      );
      controller.start();
      async.flushMicrotasks();
      sessions[0]
          .endedCompleter
          .completeError(const SimStartException('socket_drop', 'gone'));
      async.flushMicrotasks();
      expect(controller.phase, SimPhase.aborted);

      controller.retryStart();
      async.flushMicrotasks();
      expect(sessions[0].disposed, isTrue);
      expect(sessions, hasLength(2));
      expect(controller.phase, SimPhase.live);
      controller.dispose();
    });
  });
}
