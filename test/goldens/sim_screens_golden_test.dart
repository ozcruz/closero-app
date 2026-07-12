@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:closero_app/features/scoring/domain/session_doc.dart';
import 'package:closero_app/features/sim/domain/sim_script.dart';
import 'package:closero_app/features/sim/domain/sim_session.dart';
import 'package:closero_app/features/sim/presentation/cold_call_screen.dart';
import 'package:closero_app/features/sim/presentation/sim_widgets.dart';
import 'package:closero_app/features/sim/presentation/video_sim_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

/// Mid-call fixtures matching prototype 05/06 content (em-dash and
/// body-language drift corrected per the hard rules).
const _coldHints = [
  SimHint(
    kind: MomentType.good,
    label: 'Rapport',
    note: 'Used her name, good start',
  ),
  SimHint(
    kind: MomentType.good,
    label: 'Framing',
    note: 'Led with outcome, not product',
  ),
  SimHint(
    kind: MomentType.warn,
    label: 'Tonality',
    note: 'Sentences ending on an uptick',
  ),
  SimHint(
    kind: MomentType.miss,
    label: 'Discovery',
    note: 'Skipped a qualifying question',
  ),
];

const _coldNextMove = SimNextMove(
  title: 'Answer her name question, then redirect immediately',
  body: "Don't let her pause reset the momentum. Name your company, "
      'then bridge straight back to David.',
);

List<Utterance> _turns(SimScript script, int count) => [
      for (final turn in script.turns.take(count))
        Utterance(speaker: turn.speaker, text: turn.text, tsMs: turn.atMs),
    ];

/// Real-viewport frame on the app base, standing in for ClosScaffold.
Widget _viewport(double width, double height, Widget child) => MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        disableAnimations: true,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(color: ClosColors.bone.base, child: child),
      ),
    );

void main() {
  goldenTest(
    'Cold Call sim',
    fileName: 'cold_call_screen',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'live mid-call, wide',
          child: _viewport(
            1440,
            900,
            ColdCallView(
              script: coldCallScript,
              elapsedSec: 134,
              personaSpeaking: true,
              muted: false,
              nextMove: _coldNextMove,
              hints: _coldHints,
              transcript: _turns(coldCallScript, 5),
              goodCount: 2,
              onToggleMuted: () {},
              onEndCall: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'collapsed panel under 1100',
          child: _viewport(
            1000,
            760,
            ColdCallView(
              script: coldCallScript,
              elapsedSec: 62,
              personaSpeaking: false,
              muted: true,
              nextMove: _coldNextMove,
              hints: _coldHints,
              transcript: _turns(coldCallScript, 3),
              goodCount: 2,
              onToggleMuted: () {},
              onEndCall: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'connecting',
          child: _viewport(
            1000,
            700,
            const SimConnecting(
              personaName: 'Sandra Voss',
              initials: 'SV',
              tint: AvatarArtTint.slate,
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'start failed, honest copy',
          child: _viewport(
            800,
            460,
            SimStartFailed(onRetry: () {}, onBack: () {}),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'Video sim',
    fileName: 'video_sim_screen',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'live mid-call, wide',
          child: _viewport(
            1440,
            900,
            VideoSimView(
              script: videoSimScript,
              elapsedSec: 221,
              personaSpeaking: true,
              muted: false,
              nextMove: const SimNextMove(
                title: "Ask about current onboarding, don't pitch yet",
                body: "He's still sizing you up. A discovery question "
                    'keeps him talking and builds trust first.',
              ),
              hints: const [
                SimHint(
                  kind: MomentType.good,
                  label: 'Discovery',
                  note: 'Opened with his process, not your pitch',
                ),
                SimHint(
                  kind: MomentType.good,
                  label: 'Pacing',
                  note: 'Letting silence land, not rushing to fill',
                ),
                SimHint(
                  kind: MomentType.warn,
                  label: 'Talk ratio',
                  note: 'Creeping past half, tighten your turns',
                ),
                SimHint(
                  kind: MomentType.miss,
                  label: 'Discovery',
                  note: 'Missed a budget signal, "looked at options"',
                ),
              ],
              transcript: _turns(videoSimScript, 6),
              goodCount: 2,
              onToggleMuted: () {},
              onEndCall: () {},
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'End session modal',
    fileName: 'end_session_modal',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'exit confirm',
          child: noMotion(
            child: onBase(
              child: const SizedBox(
                width: 520,
                child: EndSessionDialog(
                  personaShortName: 'Sandra',
                  elapsedSec: 134,
                  estimatedMinutes: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'Sim icons',
    fileName: 'sim_icons',
    builder: () => GoldenTestGroup(
      children: [
        for (final (name, icon) in <(String, Widget)>[
          ('mic', const MicIcon()),
          ('mic off', const MicOffIcon()),
          ('power', const PowerIcon()),
          ('alert', const AlertIcon()),
        ])
          GoldenTestScenario(
            name: name,
            child: onBase(
              child: IconTheme(
                data: IconThemeData(color: ClosColors.bone.hi2, size: 30),
                child: icon,
              ),
            ),
          ),
      ],
    ),
  );
}
