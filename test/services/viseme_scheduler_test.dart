import 'dart:async';

import 'package:closero_app/core/services/viseme_mapping.dart';
import 'package:closero_app/core/services/viseme_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

VisemeEvent _event(int azureId, int offsetMs, {String utterance = 'u1'}) =>
    VisemeEvent(
      utteranceId: utterance,
      azureVisemeId: azureId,
      offsetMs: offsetMs,
    );

Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  late List<int> fired;
  late VisemeScheduler scheduler;

  setUp(() {
    fired = [];
    scheduler = VisemeScheduler(onMouthGroup: fired.add);
  });

  tearDown(() => scheduler.dispose());

  test('events never fire at arrival time, only against playback', () async {
    scheduler.addEvents([_event(2, 0), _event(0, 500)]);
    await _pump();
    expect(fired, isEmpty, reason: 'nothing may fire before playback');

    final position = StreamController<Duration>();
    scheduler.attachPlayback(utteranceId: 'u1', position: position.stream);
    await _pump();
    expect(fired, isEmpty, reason: 'attaching alone fires nothing');

    position.add(const Duration(milliseconds: 10));
    await _pump();
    expect(fired, [MouthGroup.aa]);

    position.add(const Duration(milliseconds: 200));
    await _pump();
    expect(fired, [MouthGroup.aa], reason: 'no event crossed yet');

    position.add(const Duration(milliseconds: 520));
    await _pump();
    expect(fired, [MouthGroup.aa, MouthGroup.rest]);
    await position.close();
  });

  test('fast-forwards through missed events, showing only the latest',
      () async {
    scheduler.addEvents([
      _event(2, 100),
      _event(7, 200),
      _event(15, 300),
    ]);
    final position = StreamController<Duration>();
    scheduler.attachPlayback(utteranceId: 'u1', position: position.stream);
    position.add(const Duration(milliseconds: 350));
    await _pump();
    expect(fired, [MouthGroup.ss], reason: 'only the latest crossed event');
    await position.close();
  });

  test('drops consecutive duplicate mouth groups', () async {
    // Azure 1 and 2 both map to AA.
    scheduler.addEvents([_event(1, 100), _event(2, 200)]);
    final position = StreamController<Duration>();
    scheduler.attachPlayback(utteranceId: 'u1', position: position.stream);
    position.add(const Duration(milliseconds: 150));
    await _pump();
    position.add(const Duration(milliseconds: 250));
    await _pump();
    expect(fired, [MouthGroup.aa]);
    await position.close();
  });

  test('ignores events for other utterances', () async {
    scheduler.addEvents([
      _event(2, 100),
      _event(18, 100, utterance: 'u2'),
    ]);
    final position = StreamController<Duration>();
    scheduler.attachPlayback(utteranceId: 'u2', position: position.stream);
    position.add(const Duration(milliseconds: 150));
    await _pump();
    expect(fired, [MouthGroup.ff]);
    await position.close();
  });

  test('position stream ending relaxes the mouth to rest', () async {
    scheduler.addEvents([_event(2, 100)]);
    final position = StreamController<Duration>();
    scheduler.attachPlayback(utteranceId: 'u1', position: position.stream);
    position.add(const Duration(milliseconds: 150));
    await _pump();
    await position.close();
    await _pump();
    expect(fired, [MouthGroup.aa, MouthGroup.rest]);
  });

  test('endUtterance relaxes to rest and detaches the clock', () async {
    scheduler.addEvents([_event(2, 100), _event(15, 400)]);
    final position = StreamController<Duration>();
    scheduler.attachPlayback(utteranceId: 'u1', position: position.stream);
    position.add(const Duration(milliseconds: 150));
    await _pump();
    scheduler.endUtterance();
    position.add(const Duration(milliseconds: 500));
    await _pump();
    expect(fired, [MouthGroup.aa, MouthGroup.rest],
        reason: 'nothing fires after endUtterance');
    await position.close();
  });

  test('re-attaching replays the same utterance from the new clock',
      () async {
    scheduler.addEvents([_event(2, 100), _event(0, 300)]);
    final first = StreamController<Duration>();
    scheduler.attachPlayback(utteranceId: 'u1', position: first.stream);
    first.add(const Duration(milliseconds: 350));
    await _pump();
    scheduler.endUtterance();
    expect(fired, [MouthGroup.rest], reason: 'AA and rest collapse: the '
        'fast-forward showed only the latest event, rest');

    fired.clear();
    final second = StreamController<Duration>();
    scheduler.attachPlayback(utteranceId: 'u1', position: second.stream);
    second.add(const Duration(milliseconds: 150));
    await _pump();
    expect(fired, [MouthGroup.aa]);
    await first.close();
    await second.close();
  });

  test('late events already behind the playback clock are skipped',
      () async {
    scheduler.addEvents([_event(2, 100)]);
    final position = StreamController<Duration>();
    scheduler.attachPlayback(utteranceId: 'u1', position: position.stream);
    position.add(const Duration(milliseconds: 500));
    await _pump();
    expect(fired, [MouthGroup.aa]);

    // A stale event behind the last fired offset arrives late.
    scheduler.addEvents([_event(15, 50)]);
    position.add(const Duration(milliseconds: 600));
    await _pump();
    expect(fired, [MouthGroup.aa], reason: 'stale event never fires');
    await position.close();
  });

  test('dispose stops everything without firing', () async {
    scheduler.addEvents([_event(2, 100)]);
    final position = StreamController<Duration>();
    scheduler.attachPlayback(utteranceId: 'u1', position: position.stream);
    scheduler.dispose();
    position.add(const Duration(milliseconds: 500));
    await _pump();
    expect(fired, isEmpty);
    await position.close();
  });
}
