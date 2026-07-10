@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'Auth building blocks',
    fileName: 'auth_widgets',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'eyebrow',
          child: onBase(child: const AuthEyebrow(text: 'Log in')),
        ),
        GoldenTestScenario(
          name: 'divider',
          child: onBase(
            child: const SizedBox(width: 336, child: AuthDivider()),
          ),
        ),
        GoldenTestScenario(
          name: 'confirmed email row',
          child: onBase(
            child: SizedBox(
              width: 336,
              child: ConfirmedEmailRow(
                email: 'rep@company.com',
                onChange: () {},
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'mail badge',
          child: onBase(child: const MailBadge()),
        ),
        GoldenTestScenario(
          name: 'resend row',
          child: onBase(
            child: ResendRow(
              text: "Didn't get it?",
              linkLabel: 'Resend link',
              onTap: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'switch line',
          child: onBase(
            child: AuthSwitchLine(
              prefix: "Don't have an account?",
              linkLabel: 'Sign up free',
              onTap: () {},
            ),
          ),
        ),
      ],
    ),
  );
}
