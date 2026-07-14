import '../../scoring/domain/session_doc.dart';

/// Coaching events pushed by a running sim: either a logged hint (the
/// "This call" list; a 'good' hint also fills a momentum dot) or a
/// replacement "Next move" suggestion. Hints must be observable from
/// audio/transcript only (voice, pacing, filler words, talk ratio);
/// never a body-language or camera claim.
sealed class SimCoachingEvent {
  const SimCoachingEvent();
}

/// One logged coaching hint.
class SimHint extends SimCoachingEvent {
  const SimHint({
    required this.kind,
    required this.label,
    required this.note,
  });

  final MomentType kind;

  /// Small-caps tag rendered in the kind color, e.g. 'Rapport'.
  final String label;

  /// The one-line observation, e.g. 'Used her name, good start'.
  final String note;
}

/// The current "Next move" suggestion; replaces the previous one.
class SimNextMove extends SimCoachingEvent {
  const SimNextMove({required this.title, required this.body});

  final String title;
  final String body;
}

/// What a finished session hands back: the id the post-call score
/// screen loads. Scores are server-written; the client never computes
/// one, it only carries the pointer.
class SimResult {
  const SimResult({required this.sessionId});

  final String sessionId;
}

/// Transport interface for a live or scripted sim. Screens bind to
/// this only, so swapping ScriptedSimSession for LiveSimSession
/// (Session 14) is a provider change, not a rewrite.
abstract interface class SimSession {
  /// Begins the conversation. Streams emit only after this resolves.
  Future<void> start();

  /// Utterances as they land, in call order. [Utterance.tsMs] is
  /// milliseconds since call start.
  Stream<Utterance> get transcript;

  /// Hint events and next-move updates.
  Stream<SimCoachingEvent> get coaching;

  /// Rep mic envelope, 0 to 1. Zero while the rep is silent.
  Stream<double> get inputLevel;

  /// Persona voice envelope, 0 to 1. Zero while the persona is silent.
  Stream<double> get outputLevel;

  /// Mute or unmute the rep's mic. On the live pipeline muting stops
  /// transmitting audio to the broker (privacy, and honest with the
  /// mic-off control); on the scripted stand-in it is a no-op.
  void setMuted({required bool muted});

  /// Ends the call and resolves the session result. [reason] follows
  /// the backend allowlist vocabulary ('user_hangup' for a normal
  /// hang-up; failure reasons are Session 16's abort path).
  Future<SimResult> end({required String reason});

  /// Cancels timers and closes streams. Safe to call twice.
  Future<void> dispose();
}
