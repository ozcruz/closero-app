@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/features/scoring/presentation/score_screen.dart';
import 'package:closero_app/features/scoring/presentation/transcript_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget scoring(
    Widget screen, {
    double width = 1440,
    double height = 2320,
  }) {
    return ProviderScope(
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          disableAnimations: true,
        ),
        child: SizedBox(width: width, height: height, child: screen),
      ),
    );
  }

  goldenTest(
    'Scoring screens',
    fileName: 'scoring',
    pumpBeforeTest: (tester) => tester.pumpAndSettle(),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'score (08-score-screen.png)',
          child: scoring(const ScoreScreen(sessionId: 's1')),
        ),
        GoldenTestScenario(
          name: 'score aborted: honest no-score state',
          child: scoring(
            const ScoreScreen(sessionId: 'aborted'),
            height: 720,
          ),
        ),
        GoldenTestScenario(
          name: 'transcript top (09-transcript.png)',
          child: scoring(
            const TranscriptScreen(sessionId: 's1'),
            height: 1400,
          ),
        ),
        GoldenTestScenario(
          name: 'transcript deep link (moment 2, the miss)',
          child: scoring(
            const TranscriptScreen(sessionId: 's1', moment: 2),
            height: 1400,
          ),
        ),
      ],
    ),
  );
}
