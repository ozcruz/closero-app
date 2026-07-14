import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'core/routing/routing.dart';
import 'core/routing/url_strategy/url_strategy.dart';
import 'core/services/services.dart';
import 'core/theme/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _initAnalytics();
  runApp(const ProviderScope(child: ClosApp()));
}

/// Initializes PostHog only when a key is compiled in (--dart-define).
/// On web this inits the posthog-js stub loaded by index.html with the
/// runtime key; on every target it then hooks the Flutter plugin in.
/// Absent a key, analytics stays a no-op and nothing here runs.
Future<void> _initAnalytics() async {
  if (kPosthogApiKey.isEmpty) return;
  await bootstrapPosthogJs(apiKey: kPosthogApiKey, host: kPosthogHost);
  await Posthog().setup(PostHogConfig(kPosthogApiKey)..host = kPosthogHost);
}

class ClosApp extends ConsumerWidget {
  const ClosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the app-lifetime analytics side effects (identify/reset and
    // the entitlement-flip purchase event) alive for the whole session.
    ref.watch(analyticsObserverProvider);
    return MaterialApp.router(
      title: 'Closero',
      debugShowCheckedModeBanner: false,
      theme: closTheme(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
