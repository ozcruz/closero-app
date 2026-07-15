@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/routing/placeholder_screen.dart';
import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:closero_app/features/sim/domain/sim_script.dart';
import 'package:closero_app/features/sim/presentation/sim_preflight.dart';
import 'package:closero_app/features/sim/presentation/sim_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real-viewport frame on the app base, standing in for ClosScaffold.
Widget _frame(double width, double height, Widget child) => MediaQuery(
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
    'Edge states',
    fileName: 'edge_states',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        GoldenTestScenario(
          name: 'aborted, refund confirmed',
          child: _frame(
            560,
            520,
            SimAborted(
              refundConfirmed: true,
              onRetry: () {},
              onBack: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'aborted, refund not confirmed',
          child: _frame(
            560,
            520,
            SimAborted(
              refundConfirmed: null,
              onRetry: () {},
              onBack: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'reconnecting banner',
          child: _frame(
            420,
            120,
            const Center(child: ReconnectingBanner()),
          ),
        ),
        GoldenTestScenario(
          name: '404 not found',
          child: _frame(560, 460, const NotFoundScreen()),
        ),
        GoldenTestScenario(
          name: 'data load error',
          child: _frame(
            560,
            460,
            DataLoadError(
              title: 'The dashboard could not load.',
              onRetry: () {},
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'Preflight device check',
    fileName: 'sim_preflight',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        GoldenTestScenario(
          name: 'mic ready',
          child: _frame(
            560,
            640,
            PreflightReady(script: coldCallScript, onStart: () {}),
          ),
        ),
        GoldenTestScenario(
          name: 'mic blocked',
          child: _frame(
            560,
            640,
            PreflightBlocked(onRecheck: () {}, onBack: () {}),
          ),
        ),
      ],
    ),
  );
}
