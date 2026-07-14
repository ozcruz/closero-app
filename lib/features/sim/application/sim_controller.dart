import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../scoring/domain/session_doc.dart';
import '../data/live_sim_session.dart';
import '../data/sim_gate.dart';
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

  /// Builds the session for one attempt. The [requestId] is the same id
  /// passed to the gate, so a live session addresses the broker with it.
  final SimSession Function(String requestId) createSession;

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

  /// Mapped mouth-group values from a live session, for the Video Sim's
  /// Rive avatar to consume; null on the scripted path.
  Stream<int>? visemeGroups;

  /// The finished session's pointer, set when [phase] is ended.
  SimResult? result;

  /// Filled momentum dots: one per logged 'good' hint, capped by the
  /// widget at 5.
  int get goodCount =>
      hints.where((h) => h.kind == MomentType.good).length;

  Future<void> start() async {
    final SimGateResult gateResult;
    final requestId = newSimRequestId();
    try {
      gateResult = await gate.requestStart(requestId: requestId);
    } on Exception {
      _set(() => phase = SimPhase.startFailed);
      return;
    }
    if (_disposed) return;
    if (gateResult == SimGateResult.capReached) {
      _set(() => phase = SimPhase.capBlocked);
      return;
    }

    final session = createSession(requestId);
    _session = session;
    if (session is VisemeStreaming) {
      visemeGroups = (session as VisemeStreaming).visemeGroups;
    }
    if (session is ServerEndableSession) {
      // The broker can end the call itself (time cap); route on its
      // scored result. onError guards against an unhandled async error
      // when the call drops without a score (Session 16 abort UX).
      unawaited((session as ServerEndableSession)
          .ended
          .then(_onServerEnded, onError: _onSessionError));
    }
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
    try {
      await session.start();
    } on Object {
      // Mic denied, socket refused, or hello rejected: nothing to score.
      // Session 16 owns the refund + honest copy split; here we surface
      // the honest start-failure state.
      if (_disposed) return;
      _set(() => phase = SimPhase.startFailed);
      return;
    }
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

  void toggleMuted() {
    _set(() => muted = !muted);
    _session?.setMuted(muted: muted);
  }

  /// Normal hang-up: still counts as a session, still gets scored.
  Future<void> endSession() async {
    final session = _session;
    if (session == null || phase != SimPhase.live) return;
    _set(() => phase = SimPhase.ending);
    final SimResult ended;
    try {
      ended = await session.end(reason: 'user_hangup');
    } on Object catch (e) {
      // The score never arrived (socket dropped mid-hang-up). Keep the
      // last live frame rather than a fake score; Session 16 abort UX.
      debugPrint('endSession failed before scoring: $e');
      return;
    }
    _clock?.cancel();
    _set(() {
      result = ended;
      phase = SimPhase.ended;
    });
  }

  /// The broker ended and scored the call on its own initiative (time
  /// cap). The user-hang-up path owns the transition when it is running.
  void _onServerEnded(SimResult ended) {
    if (_disposed || phase != SimPhase.live) return;
    _clock?.cancel();
    _set(() {
      result = ended;
      phase = SimPhase.ended;
    });
  }

  void _onSessionError(Object error) {
    // Unexpected end without a score. Avoids an unhandled async error;
    // the aborted-call UX + abortSimSession refund is Session 16.
    debugPrint('sim session ended without a score: $error');
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
