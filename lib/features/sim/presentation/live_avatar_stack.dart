/// Mounts the Rive avatar for a live Video Sim and drives its mouth
/// from the session's [visemeGroups] stream. The Rive controller's
/// lifecycle lives here (created and disposed with the widget), so the
/// pure LiveSimSession never touches Rive; it only emits mouth-group
/// values scheduled against playback position (Session 12 contract,
/// context/rive-contract.md). Blink and breath run autonomously in the
/// controller; the placeholder shows until the rig loads and stays as
/// the fallback if it never does.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/rive_avatar_controller.dart';
import '../../../core/widgets/widgets.dart';

class LiveAvatarStack extends StatefulWidget {
  const LiveAvatarStack({
    super.key,
    required this.visemeGroups,
    this.initials,
    this.tint = AvatarArtTint.neutral,
    this.semanticLabel,
  });

  /// Mapped mouth-group values (0..7) from the live session.
  final Stream<int> visemeGroups;

  final String? initials;
  final AvatarArtTint tint;
  final String? semanticLabel;

  @override
  State<LiveAvatarStack> createState() => _LiveAvatarStackState();
}

class _LiveAvatarStackState extends State<LiveAvatarStack> {
  final RiveAvatarController _avatar = RiveAvatarController();
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    _avatar.addListener(_onAvatarChanged);
    unawaited(_avatar.load());
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    // setViseme is a no-op until the rig is ready, so late-loading the
    // rig simply misses the mouth movements before it mounts.
    _sub = widget.visemeGroups.listen(_avatar.setViseme);
  }

  @override
  void didUpdateWidget(LiveAvatarStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visemeGroups != widget.visemeGroups) _subscribe();
  }

  void _onAvatarChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sub?.cancel();
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
