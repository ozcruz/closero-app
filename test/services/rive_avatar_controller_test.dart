import 'dart:async';
import 'dart:math' as math;

import 'package:closero_app/core/services/rive_avatar_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart' as rive;

/// Records rig calls; widgetController stays null (no native Rive in
/// unit tests, the real controller is exercised by the demo harness).
class _FakeRig implements AvatarRig {
  final List<double> visemes = [];
  final List<double> halfBlinks = [];
  int blinkCount = 0;
  bool disposed = false;

  @override
  rive.RiveWidgetController? get widgetController => null;

  @override
  void setViseme(double value) => visemes.add(value);

  @override
  void fireBlink() => blinkCount++;

  @override
  void setHalfBlink(double value) => halfBlinks.add(value);

  @override
  void dispose() => disposed = true;
}

/// Deterministic Random: hands out scripted nextInt values in order.
/// Per blink cycle the controller draws the interval (max 4001), then
/// the half-blink choice (max 4, 0 means half blink).
class _ScriptedRandom implements math.Random {
  _ScriptedRandom(this._ints);
  final List<int> _ints;

  @override
  int nextInt(int max) => _ints.isEmpty ? 1 : _ints.removeAt(0);

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

void main() {
  test('missing rig falls back quietly: no controller, no crash', () {
    fakeAsync((async) {
      final controller = RiveAvatarController(
        loadRig: () async => null,
        random: _ScriptedRandom([0, 1]),
      );
      var notified = 0;
      controller.addListener(() => notified++);
      controller.load();
      async.flushMicrotasks();

      expect(controller.loadAttempted, isTrue);
      expect(controller.isReady, isFalse);
      expect(controller.riveController, isNull);
      expect(notified, 1, reason: 'host still hears the load settle');

      controller.setViseme(3);
      async.elapse(const Duration(seconds: 30));
      controller.dispose();
    });
  });

  test('setViseme forwards mouth groups to the rig as doubles', () {
    fakeAsync((async) {
      final rig = _FakeRig();
      final controller = RiveAvatarController(
        loadRig: () async => rig,
        random: _ScriptedRandom([4000, 1]),
      );
      controller.load();
      async.flushMicrotasks();

      controller
        ..setViseme(0)
        ..setViseme(5)
        ..setViseme(7);
      expect(rig.visemes, [0.0, 5.0, 7.0]);
      controller.dispose();
    });
  });

  test('fires full blinks on the randomized 2 to 6 second interval', () {
    fakeAsync((async) {
      final rig = _FakeRig();
      final controller = RiveAvatarController(
        loadRig: () async => rig,
        // First cycle: +0ms draw (2.0s), full blink. Second: +4000ms
        // draw (6.0s), full blink.
        random: _ScriptedRandom([0, 1, 4000, 1]),
      );
      controller.load();
      async.flushMicrotasks();

      async.elapse(const Duration(milliseconds: 1999));
      expect(rig.blinkCount, 0);
      async.elapse(const Duration(milliseconds: 1));
      expect(rig.blinkCount, 1);

      async.elapse(const Duration(milliseconds: 5999));
      expect(rig.blinkCount, 1);
      async.elapse(const Duration(milliseconds: 1));
      expect(rig.blinkCount, 2);
      controller.dispose();
    });
  });

  test('occasionally holds a half blink and releases it', () {
    fakeAsync((async) {
      final rig = _FakeRig();
      final controller = RiveAvatarController(
        loadRig: () async => rig,
        // 2.0s interval, choice 0 = half blink.
        random: _ScriptedRandom([0, 0]),
      );
      controller.load();
      async.flushMicrotasks();

      async.elapse(const Duration(milliseconds: 2000));
      expect(rig.halfBlinks, [1.0], reason: 'held');
      expect(rig.blinkCount, 0, reason: 'half blink replaces the full one');
      async.elapse(const Duration(milliseconds: 160));
      expect(rig.halfBlinks, [1.0, 0.0], reason: 'released');
      controller.dispose();
    });
  });

  test('dispose cancels blink timers and disposes the rig', () {
    fakeAsync((async) {
      final rig = _FakeRig();
      final controller = RiveAvatarController(
        loadRig: () async => rig,
        random: _ScriptedRandom([0, 1]),
      );
      controller.load();
      async.flushMicrotasks();

      controller.dispose();
      expect(rig.disposed, isTrue);
      async.elapse(const Duration(seconds: 30));
      expect(rig.blinkCount, 0);
    });
  });

  test('a rig resolving after dispose is disposed, not leaked', () {
    fakeAsync((async) {
      final rig = _FakeRig();
      final completer = Completer<AvatarRig?>();
      final controller = RiveAvatarController(
        loadRig: () => completer.future,
        random: _ScriptedRandom([0, 1]),
      );
      controller.load();
      async.flushMicrotasks();

      controller.dispose();
      completer.complete(rig);
      async.flushMicrotasks();

      expect(rig.disposed, isTrue);
      expect(controller.riveController, isNull);
    });
  });
}
