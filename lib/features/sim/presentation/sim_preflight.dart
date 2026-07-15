import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/mic_permission.dart';
import '../domain/sim_script.dart';
import 'sim_widgets.dart';

enum _DeviceStatus { checking, ready, blocked }

/// Pre-call device check. Runs the mic-permission gate BEFORE the sim
/// gate (`startSimSession`), so a denied mic never burns a free session.
///
/// On grant it shows a calm ready state whose Start tap ([onStart]) is
/// where audio is primed and the sim gate finally runs. On denial it
/// shows per-browser steps to re-enable and a re-check, and never starts
/// a session that cannot capture audio.
class SimPreflight extends ConsumerStatefulWidget {
  const SimPreflight({
    super.key,
    required this.script,
    required this.onStart,
    required this.onBack,
  });

  final SimScript script;

  /// The Start tap: a user gesture, so the caller primes audio here.
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  ConsumerState<SimPreflight> createState() => _SimPreflightState();
}

class _SimPreflightState extends ConsumerState<SimPreflight> {
  _DeviceStatus _status = _DeviceStatus.checking;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    setState(() => _status = _DeviceStatus.checking);
    bool granted;
    try {
      granted = await ref.read(micPermissionProvider).ensureGranted();
    } on Object {
      granted = false;
    }
    if (!mounted) return;
    _checking = false;
    setState(() =>
        _status = granted ? _DeviceStatus.ready : _DeviceStatus.blocked);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_status) {
      _DeviceStatus.checking => PreflightChecking(script: widget.script),
      _DeviceStatus.ready =>
        PreflightReady(script: widget.script, onStart: widget.onStart),
      _DeviceStatus.blocked =>
        PreflightBlocked(onRecheck: _check, onBack: widget.onBack),
    };
  }
}

/// The device-check "still checking" view: persona placeholder + a quiet
/// line, no gate call yet.
class PreflightChecking extends StatelessWidget {
  const PreflightChecking({super.key, required this.script});

  final SimScript script;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RingedAvatar(
            initials: script.personaInitials,
            tint: script.tint,
            personaName: script.personaName,
          ),
          SizedBox(height: sp.sp6),
          Text(
            'Checking your microphone',
            style: ClosType.style(
              fontSize: 14,
              weight: FontWeight.w400,
              color: colors.mid,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mic granted: the call has not started yet, so nothing is burned.
/// The Start tap runs the gate.
class PreflightReady extends StatelessWidget {
  const PreflightReady({
    super.key,
    required this.script,
    required this.onStart,
  });

  final SimScript script;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.closColors;
    final sp = context.sp;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RingedAvatar(
            initials: script.personaInitials,
            tint: script.tint,
            personaName: script.personaName,
          ),
          SizedBox(height: sp.sp6),
          Text(script.personaName, style: context.closType.headlineMedium),
          SizedBox(height: sp.sp3),
          Text(
            'Your microphone is on. Start when you are ready.',
            textAlign: TextAlign.center,
            style: ClosType.style(
              fontSize: 14,
              weight: FontWeight.w400,
              color: colors.body,
            ),
          ),
          SizedBox(height: sp.sp6),
          SizedBox(
            width: 260,
            child: PrimaryButton(
              label: 'Start call',
              expand: true,
              onPressed: onStart,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mic denied: per-browser steps to re-enable and a re-check. The gate is
/// never called from here, so a denied mic never burns a session.
class PreflightBlocked extends StatelessWidget {
  const PreflightBlocked({
    super.key,
    required this.onRecheck,
    required this.onBack,
  });

  final VoidCallback onRecheck;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return Center(
      child: EmptyState(
        icon: const MicOffIcon(),
        title: 'Your microphone is off',
        body: 'A call needs your microphone. To turn it back on, open '
            "this page's site permissions and set Microphone to Allow, "
            'then choose Check again. Chrome and Edge: the lock or tune '
            'icon by the address bar. Safari: Settings for this website. '
            'Firefox: the microphone icon in the address bar.',
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              child: PrimaryButton(
                label: 'Check again',
                expand: true,
                onPressed: onRecheck,
              ),
            ),
            SizedBox(height: sp.sp3),
            GhostButton(label: 'Back to simulations', onPressed: onBack),
          ],
        ),
      ),
    );
  }
}
