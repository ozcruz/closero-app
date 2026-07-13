/// Schedules mouth updates against audio playback position, per the
/// sync rule in context/rive-contract.md: a sentence's viseme events
/// arrive over the socket well before its audio is heard, so events
/// buffer here and fire only when the utterance's playback clock
/// crosses their offset. NEVER at event-arrival time.
library;

import 'dart:async';

import 'viseme_mapping.dart';

/// One viseme event as the broker sends it: which utterance, which
/// Azure viseme ID, and the offset from that utterance's audio start.
class VisemeEvent {
  const VisemeEvent({
    required this.utteranceId,
    required this.azureVisemeId,
    required this.offsetMs,
  });

  final String utteranceId;
  final int azureVisemeId;
  final int offsetMs;
}

/// Buffers viseme events per utterance and replays them against a
/// playback position stream (just_audio's position stream for that
/// utterance's audio). [onMouthGroup] receives mapped mouth group
/// values (see MouthGroup); consecutive duplicates are dropped.
class VisemeScheduler {
  VisemeScheduler({required this.onMouthGroup});

  final void Function(int mouthGroup) onMouthGroup;

  /// Events per utterance, kept sorted by offset. Retained after
  /// playback so a replay (re-attach) works without re-sending.
  final Map<String, List<VisemeEvent>> _events = {};

  StreamSubscription<Duration>? _positionSub;
  String? _activeUtteranceId;
  int _nextIndex = 0;
  int? _lastGroup;
  bool _disposed = false;

  /// Buffers events. Callable any time, including long before (or
  /// while) the utterance's audio plays; nothing fires from here.
  void addEvents(Iterable<VisemeEvent> events) {
    if (_disposed) return;
    var activeTouched = false;
    for (final event in events) {
      final list = _events.putIfAbsent(event.utteranceId, () => []);
      list.add(event);
      if (event.utteranceId == _activeUtteranceId) activeTouched = true;
    }
    for (final list in _events.values) {
      list.sort((a, b) => a.offsetMs.compareTo(b.offsetMs));
    }
    // Late-arriving events for the playing utterance already behind
    // the clock fire on the next position tick via the normal path;
    // sorting above just keeps the cursor's view consistent.
    if (activeTouched) _nextIndex = _indexAt(_lastFiredOffsetMs);
  }

  int _lastFiredOffsetMs = -1;

  int _indexAt(int offsetMs) {
    final list = _events[_activeUtteranceId];
    if (list == null) return 0;
    var i = 0;
    while (i < list.length && list[i].offsetMs <= offsetMs) {
      i++;
    }
    return i;
  }

  /// Starts (or restarts) driving the mouth from [position], the
  /// playback clock of [utteranceId]'s audio. Detaches any previous
  /// utterance. Re-attaching the same utterance replays it from
  /// wherever the new clock starts.
  void attachPlayback({
    required String utteranceId,
    required Stream<Duration> position,
  }) {
    if (_disposed) return;
    _positionSub?.cancel();
    _activeUtteranceId = utteranceId;
    _nextIndex = 0;
    _lastFiredOffsetMs = -1;
    _positionSub = position.listen(_onPosition, onDone: endUtterance);
  }

  void _onPosition(Duration position) {
    final list = _events[_activeUtteranceId];
    if (list == null) return;
    final positionMs = position.inMilliseconds;
    // Position ticks are coarser than viseme events: fast-forward
    // through everything the clock passed and show only the latest.
    VisemeEvent? current;
    while (_nextIndex < list.length &&
        list[_nextIndex].offsetMs <= positionMs) {
      current = list[_nextIndex];
      _nextIndex++;
    }
    if (current == null) return;
    _lastFiredOffsetMs = current.offsetMs;
    _emit(mouthGroupForAzureViseme(current.azureVisemeId));
  }

  /// Playback for the active utterance finished (or was cut): stop
  /// listening and relax the mouth to rest.
  void endUtterance() {
    if (_disposed) return;
    _positionSub?.cancel();
    _positionSub = null;
    _activeUtteranceId = null;
    _nextIndex = 0;
    _lastFiredOffsetMs = -1;
    _emit(MouthGroup.rest);
  }

  /// Drops a finished utterance's buffered events (live pipeline
  /// hygiene; the demo loop keeps them around to replay).
  void removeUtterance(String utteranceId) {
    _events.remove(utteranceId);
  }

  void _emit(int group) {
    if (group == _lastGroup) return;
    _lastGroup = group;
    onMouthGroup(group);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _positionSub?.cancel();
    _positionSub = null;
    _events.clear();
  }
}
