import 'package:flutter_web_plugins/url_strategy.dart';

/// Clean paths (app.closero.app/score/abc), no hash fragment, so the
/// deep-link routes read like real URLs. Cloudflare Pages needs the SPA
/// fallback for these at deploy time.
void configureUrlStrategy() => usePathUrlStrategy();
