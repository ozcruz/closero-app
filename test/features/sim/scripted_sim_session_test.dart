import 'package:closero_app/core/widgets/widgets.dart' show AvatarArtTint;
import 'package:closero_app/features/scoring/domain/session_doc.dart';
import 'package:closero_app/features/sim/data/scripted_sim_session.dart';
import 'package:closero_app/features/sim/domain/sim_script.dart';
import 'package:closero_app/features/sim/domain/sim_session.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tiny deterministic script for the timing tests.
const _script = SimScript(
  resultSessionId: 'scripted-test',
  scenarioLabel: 'Test scenario',
  personaName: 'Sandra Voss',
  personaShortName: 'Sandra',
  personaRole: 'Front desk gatekeeper',
  personaInitials: 'SV',
  tint: AvatarArtTint.slate,
  estimatedMinutes: 12,
  turns: [
    ScriptedTurn(
      speaker: Speaker.persona,
      atMs: 1000,
      durMs: 2000,
      text: 'Persona line one.',
    ),
    ScriptedTurn(
      speaker: Speaker.rep,
      atMs: 4000,
      durMs: 1500,
      text: 'Rep line one.',
    ),
  ],
  coaching: [
    ScriptedCoaching(
      atMs: 500,
      event: SimNextMove(title: 'Open gently', body: 'Name, then reason.'),
    ),
    ScriptedCoaching(
      atMs: 4500,
      event: SimHint(
        kind: MomentType.good,
        label: 'Rapport',
        note: 'Used her name, good start',
      ),
    ),
  ],
);

void main() {
  test('emits turns and coaching events at their scripted times', () {
    fakeAsync((async) {
      final session = ScriptedSimSession(_script);
      final turns = <Utterance>[];
      final events = <SimCoachingEvent>[];
      session.transcript.listen(turns.add);
      session.coaching.listen(events.add);
      session.start();
      async.flushMicrotasks();

      async.elapse(const Duration(milliseconds: 600));
      expect(turns, isEmpty);
      expect(events, hasLength(1));
      expect(events.single, isA<SimNextMove>());

      async.elapse(const Duration(milliseconds: 600));
      expect(turns, hasLength(1));
      expect(turns.single.speaker, Speaker.persona);
      expect(turns.single.tsMs, 1000);

      async.elapse(const Duration(seconds: 4));
      expect(turns, hasLength(2));
      expect(turns.last.speaker, Speaker.rep);
      expect(events, hasLength(2));
      final hint = events.last as SimHint;
      expect(hint.kind, MomentType.good);

      session.dispose();
      async.flushMicrotasks();
    });
  });

  test('speaking envelopes pulse during a turn and fall silent after', () {
    fakeAsync((async) {
      final session = ScriptedSimSession(_script);
      var personaLevel = -1.0;
      var repLevel = -1.0;
      session.outputLevel.listen((level) => personaLevel = level);
      session.inputLevel.listen((level) => repLevel = level);
      session.start();
      async.flushMicrotasks();

      // Mid persona turn (1000ms to 3000ms).
      async.elapse(const Duration(milliseconds: 2000));
      expect(personaLevel, greaterThan(0));
      expect(repLevel, 0);

      // After the persona turn, before the rep turn.
      async.elapse(const Duration(milliseconds: 1500));
      expect(personaLevel, 0);

      // Mid rep turn (4000ms to 5500ms).
      async.elapse(const Duration(milliseconds: 1500));
      expect(repLevel, greaterThan(0));
      expect(personaLevel, 0);

      session.dispose();
      async.flushMicrotasks();
    });
  });

  test('end cancels the timeline and returns the scripted result', () {
    fakeAsync((async) {
      final session = ScriptedSimSession(_script);
      final turns = <Utterance>[];
      session.transcript.listen(turns.add);
      session.start();
      async.flushMicrotasks();

      SimResult? result;
      session.end(reason: 'user_hangup').then((r) => result = r);
      async.flushMicrotasks();
      expect(result?.sessionId, 'scripted-test');

      // Nothing fires after the session ended.
      async.elapse(const Duration(seconds: 10));
      expect(turns, isEmpty);
    });
  });

  test('canonical scripts satisfy the copy and coaching rules', () {
    for (final script in [coldCallScript, videoSimScript]) {
      final texts = [
        script.scenarioLabel,
        script.personaRole,
        for (final turn in script.turns) turn.text,
        for (final entry in script.coaching)
          switch (entry.event) {
            SimHint(:final label, :final note) => '$label $note',
            SimNextMove(:final title, :final body) => '$title $body',
          },
      ];
      for (final text in texts) {
        expect(text.contains('—'), isFalse,
            reason: 'em dash in "$text"');
      }
      // Hints must be observable from audio/transcript only.
      final labels = script.coaching
          .map((c) => c.event)
          .whereType<SimHint>()
          .map((h) => h.label.toLowerCase());
      for (final label in labels) {
        expect(label, isNot(contains('body')));
        expect(label, isNot(contains('presence')));
        expect(label, isNot(contains('eye')));
      }
      // Timeline stays sorted so the demo reads naturally.
      final turnTimes = script.turns.map((t) => t.atMs).toList();
      expect(turnTimes, orderedEquals([...turnTimes]..sort()));
    }
  });
}
