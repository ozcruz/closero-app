import 'package:closero_app/core/services/analytics_service.dart';

/// One captured analytics event, for assertions.
class RecordedEvent {
  RecordedEvent(this.name, this.properties);

  final String name;
  final Map<String, Object>? properties;
}

/// In-memory [AnalyticsService] that records everything, so tests can
/// assert which events fired (and with what properties) without any
/// PostHog dependency. Override [analyticsServiceProvider] with an
/// instance of this.
class RecordingAnalyticsService implements AnalyticsService {
  final List<String> identified = [];
  final List<RecordedEvent> events = [];
  int resets = 0;

  /// Names of every captured event, in order.
  List<String> get names => [for (final e in events) e.name];

  /// All captures of [name].
  Iterable<RecordedEvent> where(String name) =>
      events.where((e) => e.name == name);

  @override
  void identify(String uid) => identified.add(uid);

  @override
  void capture(String event, {Map<String, Object>? properties}) =>
      events.add(RecordedEvent(event, properties));

  @override
  void reset() => resets++;
}
