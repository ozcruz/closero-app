import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scoring/domain/session_doc.dart';
import '../data/scripted_sim_session.dart';
import '../data/sim_gate.dart';
import '../domain/sim_script.dart';
import '../domain/sim_session.dart';

/// Lifecycle of a sim screen.
enum SimPhase {
  /// Waiting on the `startSimSession` callable.
  requesting,

  /// Free cap hit: the screen routes to Session limit.
  capBlocked,

  /// The gate call failed (network, auth). Honest copy, retry offered;
  /// a session that never started burns nothing.
  startFailed,

  /// Conversation running.
  live,

  /// `end()` in flight after the exit confirm.
  ending,

  /// Result ready: the screen routes to the post-call score.
  ended,
}

/// Orchestrates gate, session streams, and the call clock for both sim
/// screens. Pure ChangeNotifier so tests drive it without widgets.
class SimController extends ChangeNotifier {
  SimController({required this.gate, required this.createSession});

  final SimGate gate;
  final SimSession Function() createSession;

  SimSession? _session;
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _clock;
  bool _disposed = false;

  SimPhase phase = SimPhase.requesting;
  int elapsedSec = 0;
  final List<Utterance> transcript = [];
  final List<SimHint> hints = [];
  SimNextMove? nextMove;
  bool personaSpeaking = false;
  bool repSpeaking = false;
  bool muted = false;

  /// The finished session's pointer, set when [phase] is ended.
  SimResult? result;

  /// Filled momentum dots: one per logged 'good' hint, capped by the
  /// widget at 5.
  int get goodCount =>
      hints.where((h) => h.kind == MomentType.good).length;

  Future<void> start() async {
    final SimGateResult gateResult;
    try {
      gateResult = await gate.requestStart(requestId: newSimRequestId());
    } on Exception {
      _set(() => phase = SimPhase.startFailed);
      return;
    }
    if (_disposed) return;
    if (gateResult == SimGateResult.capReached) {
      _set(() => phase = SimPhase.capBlocked);
      return;
    }

    final session = createSession();
    _session = session;
    _subs.add(session.transcript.listen((u) {
      _set(() => transcript.add(u));
    }));
    _subs.add(session.coaching.listen((event) {
      _set(() {
        switch (event) {
          case SimHint():
            hints.add(event);
          case SimNextMove():
            nextMove = event;
        }
      });
    }));
    _subs.add(session.outputLevel.listen((level) {
      final speaking = level > 0;
      if (speaking != personaSpeaking) {
        _set(() => personaSpeaking = speaking);
      }
    }));
    _subs.add(session.inputLevel.listen((level) {
      final speaking = level > 0 && !muted;
      if (speaking != repSpeaking) {
        _set(() => repSpeaking = speaking);
      }
    }));
    await session.start();
    if (_disposed) return;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      _set(() => elapsedSec++);
    });
    _set(() => phase = SimPhase.live);
  }

  /// Retry after a failed gate call.
  Future<void> retryStart() async {
    _set(() => phase = SimPhase.requesting);
    await start();
  }

  void toggleMuted() => _set(() => muted = !muted);

  /// Normal hang-up: still counts as a session, still gets scored.
  Future<void> endSession() async {
    final session = _session;
    if (session == null || phase == SimPhase.ending) return;
    _set(() => phase = SimPhase.ending);
    final ended = await session.end(reason: 'user_hangup');
    _clock?.cancel();
    _set(() {
      result = ended;
      phase = SimPhase.ended;
    });
  }

  void _set(VoidCallback mutate) {
    if (_disposed) return;
    mutate();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subs) {
      sub.cancel();
    }
    _clock?.cancel();
    _session?.dispose();
    super.dispose();
  }
}

/// Builds the controller for a sim type. The scripted scripts are the
/// Session 11 stand-in; LiveSimSession replaces the factory in
/// Session 14.
SimController buildSimController(Ref ref, {required SimScript script}) =>
    SimController(
      gate: ref.read(simGateProvider),
      createSession: () => ScriptedSimSession(script),
    );
