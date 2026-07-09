import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'core/widgets/widgets.dart';

void main() {
  runApp(const ProviderScope(child: ClosApp()));
}

class ClosApp extends StatelessWidget {
  const ClosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Closero',
      debugShowCheckedModeBanner: false,
      theme: closTheme(),
      home: const ClosScaffold(
        body: Center(child: Text('Where reps become closers.')),
      ),
    );
  }
}
