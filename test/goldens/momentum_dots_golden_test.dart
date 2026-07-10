@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'MomentumDots',
    fileName: 'momentum_dots',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'no strong moves yet',
          child: noMotion(
            child: onBase(child: const MomentumDots(filled: 0)),
          ),
        ),
        GoldenTestScenario(
          name: 'three strong moves with caption',
          child: noMotion(
            child: onBase(
              child: const SizedBox(
                width: 320,
                child: MomentumDots(
                  filled: 3,
                  caption:
                      '3 strong moves this call. Full score at the reveal.',
                ),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'all five',
          child: noMotion(
            child: onBase(child: const MomentumDots(filled: 5)),
          ),
        ),
      ],
    ),
  );
}
