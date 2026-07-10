@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'SectionHeader',
    fileName: 'section_header',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'title with trailing action',
          child: onBase(
            child: SizedBox(
              width: 320,
              child: SectionHeader(
                title: 'Skill breakdown',
                trailingLabel: 'View all',
                onTrailingTap: () {},
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'title only',
          child: onBase(
            child: const SizedBox(
              width: 320,
              child: SectionHeader(title: 'Recent sessions'),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'small caps section label',
          child: onBase(
            child: const SizedBox(
              width: 320,
              child: SectionHeader(
                title: 'Key moments',
                variant: SectionHeaderVariant.label,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
