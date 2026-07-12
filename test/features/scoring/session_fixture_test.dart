import 'package:closero_app/core/widgets/widgets.dart';
import 'package:closero_app/features/scoring/data/session_repository.dart';
import 'package:closero_app/features/scoring/domain/session_doc.dart';
import 'package:closero_app/features/scoring/presentation/score_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fixture must match the sessions/{id} schema and rubric in
/// context/scoring-rubric.md exactly; these tests pin the contract.
void main() {
  final view = sessionViewFixture('s1');
  final doc = view.doc;

  group('locked rubric', () {
    test('the five category keys and display names never change', () {
      expect(
        [for (final c in scoringCategories) c.key],
        ['objections', 'discovery', 'closing', 'rapport', 'tonality'],
      );
      expect(
        [for (final c in scoringCategories) c.displayName],
        [
          'Objection handling',
          'Discovery questions',
          'Closing technique',
          'Building rapport',
          'Tonality and pacing',
        ],
      );
    });

    test('weights are the rubric weights and sum to 1', () {
      expect(
        {for (final c in scoringCategories) c.key: c.weight},
        {
          'objections': 0.25,
          'discovery': 0.25,
          'closing': 0.20,
          'rapport': 0.15,
          'tonality': 0.15,
        },
      );
      final sum = scoringCategories.fold(0.0, (t, c) => t + c.weight);
      expect(sum, closeTo(1.0, 1e-9));
    });
  });

  group('canonical session fixture', () {
    test('score block has exactly the five locked keys', () {
      expect(
        doc.score!.categories.keys.toSet(),
        {for (final c in scoringCategories) c.key},
      );
    });

    test('stored total equals the weighted rubric composite', () {
      expect(doc.score!.total, 78);
      expect(rubricComposite(doc.score!.categories), doc.score!.total);
    });

    test('canonical sheet values: 84 rapport, 71 objections, 61 tonality',
        () {
      expect(doc.score!.categories['rapport'], 84);
      expect(doc.score!.categories['objections'], 71);
      expect(doc.score!.categories['tonality'], 61);
    });

    test('delta basis follows the write-time rule for session 47', () {
      expect(doc.delta!.value, 6);
      expect(doc.delta!.basis, DeltaBasis.rolling10);
      expect(view.sessionNumber, 47);
      // The stored basis and the session-number rule agree, so the
      // pill label is identical either way.
      expect(
        deltaBasisLabel(doc.delta!.basis),
        DeltaPill.comparisonLabel(view.sessionNumber),
      );
    });

    test('key moments: max 6, up to 2 per type, valid categories', () {
      expect(doc.keyMoments.length, lessThanOrEqualTo(6));
      for (final type in MomentType.values) {
        final ofType = doc.keyMoments.where((m) => m.type == type);
        expect(ofType.length, lessThanOrEqualTo(2), reason: '$type');
      }
      final keys = {for (final c in scoringCategories) c.key};
      for (final moment in doc.keyMoments) {
        expect(keys, contains(moment.categoryKey));
      }
    });

    test('each key moment deep-links to an utterance annotated with '
        'its own type', () {
      for (final moment in doc.keyMoments) {
        expect(moment.utteranceIndex, inInclusiveRange(0, doc.transcript.length - 1));
        final utterance = doc.transcript[moment.utteranceIndex];
        expect(utterance.annotation, moment.type);
        // Key moments are coaching on the rep, so they anchor on rep
        // lines.
        expect(utterance.speaker, Speaker.rep);
      }
    });

    test('every annotated utterance has a matching key moment', () {
      final linked = {for (final m in doc.keyMoments) m.utteranceIndex};
      for (final (i, utterance) in doc.transcript.indexed) {
        if (utterance.annotation != null) {
          expect(linked, contains(i));
        }
      }
    });

    test('display order is Strong, then Watch, then Missed', () {
      expect(
        [for (final m in orderedKeyMoments(doc)) m.type],
        [MomentType.good, MomentType.warn, MomentType.miss],
      );
    });

    test('timestamps are monotonic and inside the session duration', () {
      var last = -1;
      for (final utterance in doc.transcript) {
        expect(utterance.tsMs, greaterThan(last));
        last = utterance.tsMs;
      }
      expect(last, lessThanOrEqualTo(doc.durationSec * 1000));
      expect(doc.stats!.durationSec, doc.durationSec);
    });

    test('copy voice: no em dashes anywhere in the fixture', () {
      final strings = [
        view.scenarioTitle,
        for (final m in doc.keyMoments) m.text,
        for (final u in doc.transcript) u.text,
      ];
      for (final s in strings) {
        expect(s.contains('—'), isFalse, reason: s);
      }
    });
  });

  group('repository', () {
    test('serves the canonical session under any requested id', () async {
      final loaded =
          await const FixtureSessionRepository().load('inbound-demo');
      expect(loaded!.doc.id, 'inbound-demo');
      expect(loaded.doc.score!.total, 78);
    });

    test('the aborted variant has no score, moments, or transcript',
        () async {
      final aborted = await const FixtureSessionRepository().load('aborted');
      expect(aborted!.doc.status, SessionStatus.aborted);
      expect(aborted.doc.score, isNull);
      expect(aborted.doc.keyMoments, isEmpty);
      expect(aborted.doc.transcript, isEmpty);
    });
  });
}
