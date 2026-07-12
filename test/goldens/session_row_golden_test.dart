@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'SessionRow',
    fileName: 'session_row',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'scoreText ramp: green 75+, hi2 60-74, mid below 60',
          child: onBase(
            child: SizedBox(
              width: 520,
              child: ClosCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SessionRow(
                      title: 'Inbound Demo, Hesitant Buyer',
                      methodology: 'Sandler',
                      timeAgo: '2h ago',
                      score: 84,
                      onTap: () {},
                    ),
                    SessionRow(
                      title: 'Cold Call, Price Objection',
                      methodology: '7th Level',
                      timeAgo: 'Yesterday',
                      score: 61,
                      divided: true,
                      onTap: () {},
                    ),
                    SessionRow(
                      title: 'Cold Call, SaaS Gatekeeper',
                      methodology: 'Sandler',
                      timeAgo: '4d ago',
                      score: 58,
                      divided: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'hover',
          child: onBase(
            child: SizedBox(
              width: 520,
              child: ClosCard(
                padding: EdgeInsets.zero,
                child: SessionRow(
                  title: 'Follow-Up, Deal Going Cold',
                  methodology: 'Straight Line',
                  timeAgo: '2d ago',
                  score: 77,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ],
      // Hover the second scenario's row.
    ),
    whilePerforming: hover(find.text('Follow-Up, Deal Going Cold')),
  );
}
