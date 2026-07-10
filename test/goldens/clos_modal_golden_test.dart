@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  const type = ClosType();

  goldenTest(
    'ClosModal',
    fileName: 'clos_modal',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'body with close and actions',
          child: onBase(
            child: SizedBox(
              width: 560,
              height: 320,
              child: ClosModal(
                onClose: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Leave this call?', style: type.headlineMedium),
                    const SizedBox(height: 12),
                    Text(
                      'Your progress on this session will not be saved. '
                      'You can start the scenario again any time.',
                      style: type.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        GhostButton(label: 'Keep going', onPressed: () {}),
                        const SizedBox(width: 12),
                        PrimaryButton(label: 'Leave call', onPressed: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'with full-bleed avatar header',
          child: onBase(
            child: SizedBox(
              width: 560,
              height: 420,
              child: ClosModal(
                onClose: () {},
                header: const SizedBox(
                  height: 180,
                  child: AvatarStack(
                    initials: 'SV',
                    semanticLabel: 'Sandra Voss, AI persona',
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sandra', style: type.headlineMedium),
                    const SizedBox(height: 12),
                    Text(
                      'EA and front desk gatekeeper. She wants a name, a '
                      'reason, and a reason to believe you, all in under '
                      'fifteen seconds.',
                      style: type.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
