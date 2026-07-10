@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'ClosTextField states',
    fileName: 'clos_text_field',
    // Fixed pump count: the focused scenario's cursor never settles.
    pumpBeforeTest: pumpNTimes(2, const Duration(milliseconds: 300)),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'default with hint',
          child: onBase(
            child: const SizedBox(
              width: 336,
              child: ClosTextField(
                label: 'Email',
                hintText: 'you@company.com',
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'filled',
          child: onBase(
            child: SizedBox(
              width: 336,
              child: ClosTextField(
                label: 'Email',
                controller: TextEditingController(text: 'rep@company.com'),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'focused',
          child: onBase(
            child: const SizedBox(
              width: 336,
              child: ClosTextField(
                label: 'Email',
                hintText: 'you@company.com',
                autofocus: true,
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'obscured',
          child: onBase(
            child: SizedBox(
              width: 336,
              child: ClosTextField(
                label: 'Password',
                obscureText: true,
                controller: TextEditingController(text: 'hunter22'),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'label trailing action',
          child: onBase(
            child: SizedBox(
              width: 336,
              child: ClosTextField(
                label: 'Password',
                hintText: 'Your password',
                labelTrailing: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Forgot password?',
                    style: ClosType.style(
                      fontSize: 11.5,
                      weight: FontWeight.w600,
                      color: ClosColors.bone.body,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'disabled',
          child: onBase(
            child: const SizedBox(
              width: 336,
              child: ClosTextField(
                label: 'Email',
                hintText: 'you@company.com',
                enabled: false,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
