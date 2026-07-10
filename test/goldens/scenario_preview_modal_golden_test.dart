@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/features/library/data/scenario_repository.dart';
import 'package:closero_app/features/library/presentation/scenario_preview_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  final sandra =
      scenarioFixtures.singleWhere((s) => s.id == 'cold-call-saas-gatekeeper');
  final marisol = scenarioFixtures
      .singleWhere((s) => s.id == 'phone-quote-shopper-marisol');
  final coopers =
      scenarioFixtures.singleWhere((s) => s.id == 'door-knock-the-coopers');

  goldenTest(
    'ScenarioPreviewModal',
    fileName: 'scenario_preview_modal',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'personal best (canonical Sandra, 22-scenario-preview)',
          child: onBase(
            child: SizedBox(
              width: 560,
              height: 760,
              child: ScenarioPreviewModal(scenario: sandra),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'not attempted',
          child: onBase(
            child: SizedBox(
              width: 560,
              height: 760,
              child: ScenarioPreviewModal(scenario: marisol),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'in progress: resume',
          child: onBase(
            child: SizedBox(
              width: 560,
              height: 760,
              child: ScenarioPreviewModal(scenario: coopers),
            ),
          ),
        ),
      ],
    ),
  );
}
