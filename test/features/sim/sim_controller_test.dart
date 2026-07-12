import 'dart:async';

import 'package:closero_app/features/scoring/domain/session_doc.dart';
import 'package:closero_app/features/sim/application/sim_controller.dart';
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

void main() {
  test('cap response blocks without ever creating a session', () {
    fakeAsync((async) {
      var built = 0;
      final controller = SimController(
        gate: _FakeGate([SimGateResult.capReached]),
        createSession: () {
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
        createSession: _FakeSession.new,
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
        createSession: () => session,
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
}
