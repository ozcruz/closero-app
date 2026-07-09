import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/theme/theme.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // CI compares the platform-independent Ahem-rendered goldens only; the
  // font-rendered platform goldens are generated and compared locally.
  final isCi = Platform.environment.containsKey('CI');
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: closTheme(),
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isCi),
    ),
    run: testMain,
  );
}
