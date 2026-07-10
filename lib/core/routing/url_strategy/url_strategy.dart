/// Conditional export: path-based URLs on web, no-op elsewhere.
library;

export 'url_strategy_stub.dart'
    if (dart.library.js_interop) 'url_strategy_web.dart';
