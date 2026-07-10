import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/widgets/widgets.dart';

import 'interactions.dart';

void main() {
  goldenTest(
    'ClosToggle states',
    fileName: 'clos_toggle',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'off',
          child: onBase(
            child: ClosToggle(
              value: false,
              onChanged: (_) {},
              semanticLabel: 'Daily streak reminder',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'on',
          child: onBase(
            child: ClosToggle(
              value: true,
              onChanged: (_) {},
              semanticLabel: 'Daily streak reminder',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'disabled off',
          child: onBase(
            child: const ClosToggle(
              value: false,
              onChanged: null,
              semanticLabel: 'Daily streak reminder',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'disabled on',
          child: onBase(
            child: const ClosToggle(
              value: true,
              onChanged: null,
              semanticLabel: 'Daily streak reminder',
            ),
          ),
        ),
      ],
    ),
  );
}
