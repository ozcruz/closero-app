/// Rive avatar runtime for the sim stages, per context/rive-contract.md.
///
/// Loads `assets/rive/avatar.riv` through `RiveWidgetController` and
/// data binding (never the plain `RiveAnimation.asset` widget), holds
/// the contract handles, drives the mouth via [setViseme], and runs
/// idle blinks on its own randomized timers. Breathing is autonomous
/// inside the rig's `Breath` layer; the app never drives it.
///
/// Fail-soft rule: a missing file, state machine, view model, or
/// required handle leaves [riveController] null so the AvatarStack
/// gradient placeholder stays visible. Never crash the sim over art.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart' as rive;

/// Contract name consts (context/rive-contract.md). The app adapts to
/// the rig here, once; any replacement .riv must conform to these.
const String kAvatarAssetPath = 'assets/rive/avatar.riv';
const String kAvatarStateMachine = 'LipSync';
const String kAvatarViewModelVisemeProperty = 'viseme';
const String kAvatarBlinkInput = 'blink';
const String kAvatarHalfBlinkInput = 'halfBlink';

/// The resolved rig surface the controller drives. Abstract so blink
/// cadence and viseme forwarding are testable without native Rive.
abstract interface class AvatarRig {
  /// The painter to mount in AvatarStack's Rive slot; null in fakes.
  rive.RiveWidgetController? get widgetController;

  /// Sets `AvatarVM.viseme` (mouth group 0 to 7, compared by equality).
  void setViseme(double value);

  /// Fires the `blink` trigger input (full blink).
  void fireBlink();

  /// Sets the `halfBlink` Number hold: 1 held, 0 released.
  void setHalfBlink(double value);

  void dispose();
}

class _RiveRig implements AvatarRig {
  _RiveRig({
    required this.file,
    required this.controller,
    required this.viewModelInstance,
    required this.viseme,
    required this.blink,
    required this.halfBlink,
  });

  final rive.File file;
  final rive.RiveWidgetController controller;
  final rive.ViewModelInstance viewModelInstance;
  final rive.ViewModelInstanceNumber viseme;
  final rive.TriggerInput blink;
  final rive.NumberInput halfBlink;

  @override
  rive.RiveWidgetController get widgetController => controller;

  @override
  void setViseme(double value) => viseme.value = value;

  @override
  void fireBlink() => blink.fire();

  @override
  void setHalfBlink(double value) => halfBlink.value = value;

  @override
  void dispose() {
    viewModelInstance.dispose();
    controller.dispose();
    file.dispose();
  }
}

/// Loads the real rig. Returns null (after logging) on any missing
/// piece so callers fall back to the placeholder.
Future<AvatarRig?> loadAvatarRig() async {
  rive.File? file;
  rive.RiveWidgetController? controller;
  try {
    file = await rive.File.asset(
      kAvatarAssetPath,
      riveFactory: rive.Factory.rive,
    );
    if (file == null) {
      debugPrint('RiveAvatarController: $kAvatarAssetPath did not decode');
      return null;
    }
    controller = rive.RiveWidgetController(
      file,
      stateMachineSelector:
          const rive.StateMachineNamed(kAvatarStateMachine),
    );
    final vmi = controller.dataBind(rive.DataBind.auto());
    final viseme = vmi.number(kAvatarViewModelVisemeProperty);
    // Blinks are the two contract-locked state machine inputs; the rig
    // predates data-binding blinks, so the deprecated accessors are
    // deliberate until the production rig moves them onto AvatarVM.
    // ignore: deprecated_member_use
    final blink = controller.stateMachine.trigger(kAvatarBlinkInput);
    // ignore: deprecated_member_use
    final halfBlink = controller.stateMachine.number(kAvatarHalfBlinkInput);
    if (viseme == null || blink == null || halfBlink == null) {
      debugPrint(
        'RiveAvatarController: missing handle '
        '(viseme: ${viseme != null}, blink: ${blink != null}, '
        'halfBlink: ${halfBlink != null}), falling back to placeholder',
      );
      vmi.dispose();
      controller.dispose();
      file.dispose();
      return null;
    }
    return _RiveRig(
      file: file,
      controller: controller,
      viewModelInstance: vmi,
      viseme: viseme,
      blink: blink,
      halfBlink: halfBlink,
    );
  } on Object catch (error) {
    debugPrint(
      'RiveAvatarController: rig load failed ($error), '
      'falling back to placeholder',
    );
    controller?.dispose();
    file?.dispose();
    return null;
  }
}

/// Owns one avatar rig instance for a sim stage: loading, the mouth
/// property, and idle blink life. Listeners fire when the rig becomes
/// ready (or fails), so the host can mount [riveController].
class RiveAvatarController extends ChangeNotifier {
  RiveAvatarController({
    Future<AvatarRig?> Function()? loadRig,
    math.Random? random,
  })  : _loadRig = loadRig ?? loadAvatarRig,
        _random = random ?? math.Random();

  final Future<AvatarRig?> Function() _loadRig;
  final math.Random _random;

  AvatarRig? _rig;
  Timer? _blinkTimer;
  Timer? _halfBlinkRelease;
  bool _disposed = false;
  bool _loaded = false;

  /// Mount this in AvatarStack's Rive slot; null until loaded, and
  /// stays null on failure (placeholder remains).
  rive.RiveWidgetController? get riveController => _rig?.widgetController;

  /// True once [load] resolved, whether or not a rig came back.
  bool get loadAttempted => _loaded;

  bool get isReady => _rig != null;

  /// Resolves the rig and starts idle life. Safe to call once; a
  /// failed load leaves the controller in permanent placeholder mode.
  Future<void> load() async {
    if (_loaded || _disposed) return;
    final rig = await _loadRig();
    if (_disposed) {
      rig?.dispose();
      return;
    }
    _loaded = true;
    _rig = rig;
    if (rig != null) _scheduleNextBlink();
    notifyListeners();
  }

  /// Sets the mouth group (0 to 7, see MouthGroup). No-op until ready.
  void setViseme(int mouthGroup) => _rig?.setViseme(mouthGroup.toDouble());

  /// Idle blink cadence per the contract: a blink roughly every 2 to
  /// 6 seconds, occasionally a half blink (held ~160ms) instead. Runs
  /// on its own timers, fully decoupled from the viseme stream.
  void _scheduleNextBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2000 + _random.nextInt(4001)),
      () {
        final rig = _rig;
        if (rig == null) return;
        if (_random.nextInt(4) == 0) {
          rig.setHalfBlink(1);
          _halfBlinkRelease = Timer(
            const Duration(milliseconds: 160),
            () => _rig?.setHalfBlink(0),
          );
        } else {
          rig.fireBlink();
        }
        _scheduleNextBlink();
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _blinkTimer?.cancel();
    _halfBlinkRelease?.cancel();
    _rig?.dispose();
    _rig = null;
    super.dispose();
  }
}
