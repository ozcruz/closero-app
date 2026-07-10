import 'package:alchemist/alchemist.dart';
import 'package:closero_app/core/theme/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hovers a mouse pointer over the widget matched by [finder] and holds it
/// there while the golden is captured, so hover-lift states can be recorded.
Interaction hover(Finder finder) => (WidgetTester tester) async {
      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(finder));
      await tester.pump(const Duration(milliseconds: 300));
      return gesture.removePointer;
    };

/// Places a scenario on the app's base background with breathing room,
/// matching how components sit on real screens.
Widget onBase({required Widget child}) => ColoredBox(
      color: ClosColors.bone.base,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
