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

  Widget sampleContent(String title) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: type.titleMedium),
          const SizedBox(height: 12),
          Text(
            'Practice the call before it costs you the deal.',
            style: type.bodyMedium,
          ),
        ],
      );

  goldenTest(
    'ClosCard',
    fileName: 'clos_card',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'default',
          child: onBase(
            child: SizedBox(
              width: 320,
              child: ClosCard(child: sampleContent('Skill breakdown')),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'inset',
          child: onBase(
            child: SizedBox(
              width: 320,
              child: ClosCard(
                variant: ClosCardVariant.inset,
                child: sampleContent('Earning potential'),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'hairline (auth card treatment)',
          child: onBase(
            child: SizedBox(
              width: 320,
              child: ClosCard(
                hairline: true,
                child: sampleContent('Welcome back'),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'inset nested in default',
          child: onBase(
            child: SizedBox(
              width: 320,
              child: ClosCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Earning potential', style: type.titleMedium),
                    const SizedBox(height: 12),
                    ClosCard(
                      variant: ClosCardVariant.inset,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Reps at 60 percent plus average 85 to 95K in your '
                        'target market, per published comp data.',
                        style: type.bodySmall,
                      ),
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
