/// Pre-call microphone check, run BEFORE `startSimSession` so a denied
/// mic never burns a free session. Abstracted so the preflight screen
/// runs against a fake in tests.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

/// Checks (and, if undecided, requests) microphone access.
abstract interface class MicPermission {
  /// True when the browser/OS grants the mic. On web this prompts the
  /// first time; a later call reflects the standing decision.
  Future<bool> ensureGranted();
}

/// The `record` plugin backing: its `hasPermission()` triggers the
/// browser prompt when the decision is still open, so a granted result
/// means the later capture stream will not prompt again.
class RecordMicPermission implements MicPermission {
  RecordMicPermission({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<bool> ensureGranted() => _recorder.hasPermission();
}

final micPermissionProvider =
    Provider<MicPermission>((ref) => RecordMicPermission());
