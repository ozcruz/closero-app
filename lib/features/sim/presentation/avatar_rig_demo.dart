import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/services/rive_avatar_controller.dart';
import '../../../core/services/viseme_scheduler.dart';
import '../../../core/widgets/widgets.dart';

/// Debug harness behind the AVATAR_RIG_DEMO flag: mounts the rig in
/// AvatarStack's Rive slot and loops the bundled test clip, driving
/// the mouth from the canned timeline below via the playback-position
/// scheduler. This is the lipsync test bed until the live pipeline
/// (Session 14) feeds real broker events.
const String kLipsyncDemoAsset = 'assets/audio/lipsync_demo.wav';
const String _demoUtteranceId = 'lipsync-demo';

/// Azure viseme IDs aligned to the beeps in the demo clip; keep in
/// step with the segment table in tool/gen_lipsync_clip.dart. The
/// mouth opens exactly at each beep's start and rests at its end, so
/// drift between audio and mouth is visible by eye.
const List<VisemeEvent> kLipsyncDemoTimeline = [
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 2, offsetMs: 400),
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 6, offsetMs: 650),
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 0, offsetMs: 900),
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 7, offsetMs: 1300),
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 0, offsetMs: 1800),
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 6, offsetMs: 2200),
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 0, offsetMs: 2700),
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 18, offsetMs: 3100),
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 0, offsetMs: 3600),
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 15, offsetMs: 4000),
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 1, offsetMs: 4300),
  VisemeEvent(utteranceId: _demoUtteranceId, azureVisemeId: 0, offsetMs: 4600),
];

/// Drop-in for the stage's AvatarStack slot. Renders the same
/// placeholder underneath; the rig mounts on top once loaded, and any
/// load failure quietly leaves the placeholder (never crashes).
class AvatarRigDemoStack extends StatefulWidget {
  const AvatarRigDemoStack({
    super.key,
    this.initials,
    this.tint = AvatarArtTint.neutral,
    this.semanticLabel,
  });

  final String? initials;
  final AvatarArtTint tint;
  final String? semanticLabel;

  @override
  State<AvatarRigDemoStack> createState() => _AvatarRigDemoStackState();
}

class _AvatarRigDemoStackState extends State<AvatarRigDemoStack> {
  final RiveAvatarController _avatar = RiveAvatarController();
  late final VisemeScheduler _scheduler =
      VisemeScheduler(onMouthGroup: _avatar.setViseme);
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<ProcessingState>? _stateSub;
  Timer? _replayTimer;

  @override
  void initState() {
    super.initState();
    _avatar.addListener(_onAvatarChanged);
    unawaited(_start());
  }

  void _onAvatarChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    await _avatar.load();
    if (!mounted || !_avatar.isReady) return;
    // The timeline is buffered up front, exactly like broker events
    // that land before their audio; nothing fires until playback.
    _scheduler.addEvents(kLipsyncDemoTimeline);
    try {
      await _player.setAsset(kLipsyncDemoAsset);
    } on Object catch (error) {
      debugPrint('AvatarRigDemo: demo clip failed to load ($error)');
      return;
    }
    if (!mounted) return;
    _stateSub = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _onClipCompleted();
    });
    _playFromStart();
  }

  void _playFromStart() {
    if (!mounted) return;
    _scheduler.attachPlayback(
      utteranceId: _demoUtteranceId,
      position: _player.createPositionStream(
        minPeriod: const Duration(milliseconds: 16),
        maxPeriod: const Duration(milliseconds: 33),
      ),
    );
    unawaited(_player.seek(Duration.zero));
    unawaited(_player.play());
  }

  void _onClipCompleted() {
    _scheduler.endUtterance();
    unawaited(_player.pause());
    _replayTimer = Timer(const Duration(milliseconds: 2500), _playFromStart);
  }

  @override
  void dispose() {
    _replayTimer?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    _scheduler.dispose();
    _avatar.removeListener(_onAvatarChanged);
    _avatar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AvatarStack(
      initials: widget.initials,
      tint: widget.tint,
      controller: _avatar.riveController,
      semanticLabel: widget.semanticLabel,
    );
  }
}
