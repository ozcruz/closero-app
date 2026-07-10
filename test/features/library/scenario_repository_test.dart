import 'package:closero_app/core/widgets/widgets.dart';
import 'package:closero_app/features/dashboard/data/dashboard_repository.dart';
import 'package:closero_app/features/library/data/scenario_repository.dart';
import 'package:closero_app/features/library/domain/scenario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repo = FixtureScenarioRepository();

  test('scenario ids are unique', () async {
    final scenarios = await repo.list();
    final ids = scenarios.map((s) => s.id).toSet();
    expect(ids.length, scenarios.length);
  });

  test('B2C grid carries the canonical initials in display order',
      () async {
    final scenarios = await repo.list();
    final b2c = scenarios.where((s) => s.track == ScenarioTrack.b2c);
    expect(
      b2c.map((s) => s.initials),
      ['DW', 'TC', 'RH', 'MG', 'WB', 'TS'],
    );
  });

  test('every dashboard hero id resolves in the shared catalog and agrees',
      () async {
    for (final hero in [gatekeeperFeatured, homeownerFeatured]) {
      final scenario = await repo.byId(hero.id);
      expect(scenario, isNotNull, reason: hero.id);
      // One shared scenario source: the dashboard hero and the library
      // card must never disagree on the facts of a scenario.
      expect(scenario!.duration, hero.duration);
      expect(scenario.targets, hero.targets);
      expect(scenario.difficultyLabel, hero.difficultyLabel);
      expect(scenario.initials, hero.initials);
      expect(scenario.tint, hero.tint);
      expect(scenario.methodologyTags, hero.tags);
    }
  });

  test('unknown ids resolve to null', () async {
    expect(await repo.byId('not-a-scenario'), isNull);
  });

  test('status maps to the card contract, and locked always wins', () {
    const base = scenarioFixtures;
    final denise = base.singleWhere((s) => s.initials == 'DW');
    final coopers = base.singleWhere((s) => s.initials == 'TC');
    final marisol = base.singleWhere((s) => s.initials == 'MG');

    expect(denise.status(locked: false), ScenarioCardStatus.personalBest);
    expect(coopers.status(locked: false), ScenarioCardStatus.inProgress);
    expect(marisol.status(locked: false), ScenarioCardStatus.start);
    for (final s in base) {
      expect(s.status(locked: true), ScenarioCardStatus.locked);
    }
  });

  test('copy voice: no em dashes in any catalog string', () async {
    final scenarios = await repo.list();
    for (final s in scenarios) {
      final strings = [
        s.name,
        s.roleLine,
        s.cardLine,
        s.synopsis,
        s.difficultyBadge,
        s.difficultyLabel,
        s.duration,
        s.targets,
        ...s.methodologyTags,
      ];
      for (final value in strings) {
        expect(value.contains('—'), isFalse, reason: '${s.id}: $value');
      }
    }
  });
}
