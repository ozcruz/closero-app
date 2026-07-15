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

  /// The gate call failed (network, auth) BEFORE a grant. Honest copy,
  /// retry offered; a session that never started burns nothing.
  startFailed,

  /// Conversation running.
  live,

  /// `end()` in flight after the exit confirm.
  ending,

  /// Result ready: the screen routes to the post-call score.
  ended,

  /// A granted session failed technically (post-grant start failure,
  /// mid-call socket drop past the reconnect window, dead audio
  /// pipeline). No score; the free-cap credit is refunded via
  /// abortSimSession and the aborted-call screen shows honest copy.
  aborted,
}

/// Orchestrates gate, session streams, and the call clock for both sim
/// screens. Pure ChangeNotifier so tests drive it without widgets.
class SimController extends ChangeNotifier {
  SimController({
    required this.gate,
    required this.createSession,
    this.abort,
  });

  final SimGate gate;

  /// Builds the session for one attempt. The [requestId] is the same id
  /// passed to the gate, so a live session addresses the broker with it.
  final SimSession Function(String requestId) createSession;

  /// Refunds the free-cap credit when a GRANTED session fails for a
  /// technical reason. Null on the scripted path (nothing to refund) and
  /// in tests that don't exercise the abort flow.
  final SimAbort? abort;

  SimSession? _session;
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _clock;
  bool _disposed = false;

  /// The gate/broker id for the current attempt, so a refund addresses
  /// the same granted session.
  String? _requestId;

  /// Guards against a double refund when both the start-failure catch and
  /// the ended-future error fire for one attempt.
  bool _refundRequested = false;

  SimPhase phase = SimPhase.requesting;
  int elapsedSec = 0;
  final List<Utterance> transcript = [];
  final List<SimHint> hints = [];
  SimNextMove? nextMove;
  bool personaSpeaking = false;
  bool repSpeaking = false;
  bool muted = false;

  /// True while the live link is dropping and reconnecting: the screen
  /// shows a calm banner and the call clock is paused.
  bool reconnecting = false;

  /// Whether abortSimSession confirmed the refund on the aborted path.
  /// Null until the abort call resolves (or if it never ran / failed), so
  /// the screen only claims "this didn't count" when it is true.
  bool? refundConfirmed;

  /// The refund-vocabulary reason for the aborted state, for analytics.
  String? abortReason;

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
    // Retrying after an aborted attempt: tear the previous session down
    // before building the next, so streams and the old session's player
    // never linger or get shared.
    await _cleanupSession();
    final SimGateResult gateResult;
    final requestId = newSimRequestId();
    _requestId = requestId;
    try {
      gateResult = await gate.requestStart(requestId: requestId);
    } on Exception {
      // Pre-grant: the gate never allowed a session, so nothing was used.
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
      // scored result. onError carries the mid-call drop to the aborted
      // UX + refund.
      unawaited((session as ServerEndableSession)
          .ended
          .then(_onServerEnded, onError: _onSessionError));
    }
    if (session is LinkStateReporting) {
      _subs.add(
        (session as LinkStateReporting).linkState.listen(_onLinkState),
      );
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
    } on Object catch (error) {
      // The gate already granted this session, so a technical failure
      // here (mic capture failed, socket refused, hello rejected) burned
      // the grant: refund it and show the aborted-call UX, never the
      // "nothing used" copy.
      if (_disposed) return;
      _toAborted(error);
      return;
    }
    if (_disposed) return;
    _startClock();
    _set(() => phase = SimPhase.live);
  }

  /// Retry after a failed gate call or an aborted session. Resets the
  /// per-attempt state so a fresh grant is requested with a new id.
  Future<void> retryStart() async {
    _refundRequested = false;
    _set(() {
      reconnecting = false;
      refundConfirmed = null;
      phase = SimPhase.requesting;
    });
    await start();
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      _set(() => elapsedSec++);
    });
  }

  /// Reconnecting/live transitions from the live session's link state.
  /// The clock pauses while the link is down so the call duration only
  /// counts time the rep could actually talk.
  void _onLinkState(SimLinkState state) {
    if (phase != SimPhase.live) return;
    switch (state) {
      case SimLinkState.reconnecting:
        _clock?.cancel();
        _clock = null;
        _set(() => reconnecting = true);
      case SimLinkState.live:
        _startClock();
        _set(() => reconnecting = false);
    }
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

  /// The session ended without a score (a mid-call drop past the
  /// reconnect window, or a dead audio pipeline). Route to the
  /// aborted-call UX + refund.
  void _onSessionError(Object error) {
    if (_disposed) return;
    _toAborted(error);
  }

  /// Move a granted-but-failed attempt to the aborted state and start the
  /// refund. Idempotent: safe if both the start-failure catch and the
  /// ended-future error fire for the same attempt.
  void _toAborted(Object error) {
    if (_disposed) return;
    if (phase == SimPhase.ended || phase == SimPhase.aborted) return;
    _clock?.cancel();
    _clock = null;
    final reason = error is SimStartException ? error.reason : 'socket_drop';
    abortReason = reason;
    _set(() {
      reconnecting = false;
      phase = SimPhase.aborted;
    });
    unawaited(_refund(reason));
  }

  /// Ask the server to refund the burned grant. Sets [refundConfirmed]
  /// only when the callable confirms it: if the abort call itself fails,
  /// it stays null so the screen never claims nothing was used.
  Future<void> _refund(String reason) async {
    if (_refundRequested) return;
    _refundRequested = true;
    final abort = this.abort;
    final id = _requestId;
    if (abort == null ||
        id == null ||
        !kRefundableAbortReasons.contains(reason)) {
      return;
    }
    try {
      final result = await abort.requestAbort(requestId: id, reason: reason);
      if (_disposed) return;
      _set(() => refundConfirmed = result.refunded);
    } on Object catch (e) {
      // The refund call failed: leave refundConfirmed null (honest copy).
      debugPrint('abortSimSession failed: $e');
    }
  }

  /// Cancels this attempt's stream subscriptions and clock and disposes
  /// its session. A no-op on the first start (nothing built yet).
  Future<void> _cleanupSession() async {
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();
    _clock?.cancel();
    _clock = null;
    final old = _session;
    _session = null;
    visemeGroups = null;
    await old?.dispose();
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
