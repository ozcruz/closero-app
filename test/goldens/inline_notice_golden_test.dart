@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'InlineNotice states',
    fileName: 'inline_notice',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'error',
          child: onBase(
            child: const SizedBox(
              width: 336,
              child: InlineNotice(
                kind: InlineNoticeKind.error,
                message: 'Email or password is incorrect.',
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'info',
          child: onBase(
            child: const SizedBox(
              width: 336,
              child: InlineNotice(
                kind: InlineNoticeKind.info,
                message: 'Sent. Check your inbox and spam folder.',
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'error, two lines',
          child: onBase(
            child: const SizedBox(
              width: 336,
              child: InlineNotice(
                kind: InlineNoticeKind.error,
                message: 'Your browser blocked the sign-in popup. '
                    'Allow popups and retry.',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
