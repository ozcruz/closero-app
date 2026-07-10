import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/routing.dart';
import 'core/routing/url_strategy/url_strategy.dart';
import 'core/theme/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: ClosApp()));
}

class ClosApp extends ConsumerWidget {
  const ClosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Closero',
      debugShowCheckedModeBanner: false,
      theme: closTheme(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
