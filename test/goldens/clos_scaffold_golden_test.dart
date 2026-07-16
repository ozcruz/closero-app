@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  goldenTest(
    'ClosScaffold shell',
    fileName: 'clos_scaffold',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'shell with type scale sample',
          child: const SizedBox(
            width: 480,
            height: 360,
            child: ClosScaffold(body: _TypeSample()),
          ),
        ),
      ],
    ),
  );
}

class _TypeSample extends StatelessWidget {
  const _TypeSample();

  @override
  Widget build(BuildContext context) {
    final type = context.closType;
    final sp = context.sp;
    return Padding(
      padding: EdgeInsets.all(sp.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where reps become closers.', style: type.headlineMedium),
          SizedBox(height: sp.headlineToSubtext),
          Text(
            'Practice the call before it costs you the deal.',
            style: type.bodyMedium,
          ),
        ],
      ),
    );
  }
}
