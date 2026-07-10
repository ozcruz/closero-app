@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'TranscriptLine',
    fileName: 'transcript_line',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'persona, plain',
          child: onBase(
            child: const SizedBox(
              width: 520,
              child: TranscriptLine(
                speaker: 'Sandra',
                timestamp: '0:04',
                text: 'Meridian Software, this is Sandra. How can I direct '
                    'your call?',
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'rep, strong annotation',
          child: onBase(
            child: const SizedBox(
              width: 520,
              child: TranscriptLine(
                speaker: 'You',
                timestamp: '1:14',
                text: 'Totally fair question. I work with a few SaaS '
                    'companies here in Chicago helping their sales teams '
                    'cut ramp time. Two minutes, tops.',
                annotationKind: HintKind.good,
                annotation: 'Disarmed the gatekeeper in under 30 seconds: '
                    'matched her pace and got the opening without friction.',
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'rep, watch annotation',
          child: onBase(
            child: const SizedBox(
              width: 520,
              child: TranscriptLine(
                speaker: 'You',
                timestamp: '4:52',
                text: 'Yeah, whenever is easiest for him. I do not want to '
                    'be a bother, so no pressure if today does not work.',
                annotationKind: HintKind.warn,
                annotation: 'Gave away too much when she offered a callback. '
                    'Volunteering "no pressure" signals low leverage.',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
