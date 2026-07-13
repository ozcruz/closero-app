// Temporary Session-12-precheck probe. Run with:
//   flutter run -d web-server --web-port 8788 -t lib/rive_probe_main.dart
// Verifies avatar.riv against context/rive-contract.md: the mouth is
// driven by DATA BINDING (AvatarVM.viseme), not the legacy viseme
// input; blink is a lowercase trigger input; halfBlink is a Number
// hold (1 = held, 0 = released); Breath plays autonomously.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

void main() => runApp(const _ProbeApp());

class _ProbeApp extends StatelessWidget {
  const _ProbeApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _ProbeScreen(),
      );
}

class _ProbeScreen extends StatefulWidget {
  const _ProbeScreen();

  @override
  State<_ProbeScreen> createState() => _ProbeScreenState();
}

class _ProbeScreenState extends State<_ProbeScreen> {
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstanceNumber? _visemeVm;
  rive.NumberInput? _halfBlink;
  final List<String> _report = [];

  void _log(String line) {
    debugPrint('[probe] $line');
    setState(() => _report.add(line));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = await rive.File.asset(
        'assets/rive/avatar.riv',
        riveFactory: rive.Factory.rive,
      );
      if (file == null) {
        _log('FAIL: file did not decode');
        return;
      }
      final controller = rive.RiveWidgetController(
        file,
        stateMachineSelector: const rive.StateMachineNamed('LipSync'),
      );
      final machine = controller.stateMachine;
      _log('state machine resolved: ${machine.name}');

      final vmi = controller.dataBind(rive.DataBind.auto());
      _visemeVm = vmi.number('viseme');
      _log('AvatarVM bound, viseme property: ${_visemeVm != null}');

      _log('blink trigger input: ${machine.trigger('blink') != null}');
      _halfBlink = machine.number('halfBlink');
      _log('halfBlink number input: ${_halfBlink != null}');

      setState(() => _controller = controller);
    } on Object catch (e) {
      _log('FAIL: $e');
    }
  }

  void _setViseme(double value) {
    _visemeVm?.value = value;
    debugPrint('[probe] AvatarVM.viseme set to $value');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          Expanded(
            child: _controller == null
                ? const Center(
                    child: Text(
                      'loading rig',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : rive.RiveWidget(controller: _controller!),
          ),
          SizedBox(
            width: 380,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var v = 0; v <= 7; v++)
                      ElevatedButton(
                        key: Key('viseme-$v'),
                        onPressed: () => _setViseme(v.toDouble()),
                        child: Text('viseme $v'),
                      ),
                    ElevatedButton(
                      key: const Key('trigger-blink'),
                      onPressed: () {
                        _controller?.stateMachine.trigger('blink')?.fire();
                        debugPrint('[probe] fired blink');
                      },
                      child: const Text('blink'),
                    ),
                    ElevatedButton(
                      key: const Key('halfBlink-hold'),
                      onPressed: () {
                        _halfBlink?.value = 1;
                        debugPrint('[probe] halfBlink = 1 (hold)');
                      },
                      child: const Text('halfBlink 1'),
                    ),
                    ElevatedButton(
                      key: const Key('halfBlink-release'),
                      onPressed: () {
                        _halfBlink?.value = 0;
                        debugPrint('[probe] halfBlink = 0 (release)');
                      },
                      child: const Text('halfBlink 0'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final line in _report)
                  Text(
                    line,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
