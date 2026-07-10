import 'package:closero_app/core/theme/theme.dart';
import 'package:closero_app/core/widgets/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(Widget child) => MaterialApp(
      theme: closTheme(),
      home: Scaffold(body: Center(child: child)),
    );

Future<TestGesture> hoverOver(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(finder));
  await tester.pump(const Duration(milliseconds: 300));
  return gesture;
}

AnimatedContainer buttonBox(WidgetTester tester, Type buttonType) =>
    tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(buttonType),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

void main() {
  group('button hover lift', () {
    testWidgets('primary lifts 1px and gains an accent shadow on hover',
        (tester) async {
      await tester.pumpWidget(
        harness(PrimaryButton(label: 'Start session', onPressed: () {})),
      );

      var box = buttonBox(tester, PrimaryButton);
      expect(box.transform!.getTranslation().y, 0);
      expect((box.decoration! as BoxDecoration).boxShadow, isEmpty);

      await hoverOver(tester, find.byType(PrimaryButton));

      box = buttonBox(tester, PrimaryButton);
      expect(box.transform!.getTranslation().y, -1);
      final shadow = (box.decoration! as BoxDecoration).boxShadow!.single;
      expect(shadow.color, ClosColors.bone.accent.withValues(alpha: 0.16));
    });

    testWidgets('ghost brightens text and border on hover', (tester) async {
      await tester.pumpWidget(
        harness(GhostButton(label: 'Preview scenario', onPressed: () {})),
      );

      Text label() => tester.widget<Text>(find.text('Preview scenario'));
      expect(label().style!.color, ClosColors.bone.mid);

      await hoverOver(tester, find.byType(GhostButton));

      expect(label().style!.color, ClosColors.bone.hi2);
      final box = buttonBox(tester, GhostButton);
      expect(box.transform!.getTranslation().y, -1);
      final border = (box.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, ClosColors.bone.dim1);
    });

    testWidgets('pressed cancels the lift', (tester) async {
      await tester.pumpWidget(
        harness(PrimaryButton(label: 'Start session', onPressed: () {})),
      );
      await hoverOver(tester, find.byType(PrimaryButton));

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(PrimaryButton)));
      await tester.pump(const Duration(milliseconds: 300));

      final box = buttonBox(tester, PrimaryButton);
      expect(box.transform!.getTranslation().y, 0);
      expect((box.decoration! as BoxDecoration).boxShadow, isEmpty);
      await gesture.up();
    });
  });

  group('button activation', () {
    testWidgets('tap invokes onPressed once', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        harness(PrimaryButton(label: 'Start session', onPressed: () => taps++)),
      );
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 1);
    });

    testWidgets('disabled and loading buttons ignore taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        harness(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PrimaryButton(label: 'Disabled'),
              PrimaryButton(
                label: 'Loading',
                loading: true,
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Disabled'), warnIfMissed: false);
      await tester.tap(find.text('Loading'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 0);
    });

    testWidgets('meets the 44px minimum tap target', (tester) async {
      await tester.pumpWidget(
        harness(
          PrimaryButton(
            label: 'Go',
            size: ClosButtonSize.medium,
            onPressed: () {},
          ),
        ),
      );
      final size = tester.getSize(find.byType(PrimaryButton));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
    });
  });

  group('ClosToggle', () {
    testWidgets('tap flips the value and exposes toggle semantics',
        (tester) async {
      bool? received;
      await tester.pumpWidget(
        harness(
          ClosToggle(
            value: false,
            onChanged: (v) => received = v,
            semanticLabel: 'Daily streak reminder',
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(ClosToggle)),
        matchesSemantics(
          label: 'Daily streak reminder',
          hasToggledState: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      await tester.tap(find.byType(ClosToggle));
      expect(received, true);
    });

    testWidgets('hit target is at least 44x44 around the 36x20 visual',
        (tester) async {
      await tester.pumpWidget(
        harness(
          ClosToggle(
            value: false,
            onChanged: (_) {},
            semanticLabel: 'Daily streak reminder',
          ),
        ),
      );
      final size = tester.getSize(find.byType(ClosToggle));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('SideNav', () {
    SideNav nav({bool collapsed = false, VoidCallback? onSimulations}) =>
        SideNav(
          collapsed: collapsed,
          user: SideNavUser(name: 'Osman Cruz', plan: 'Closer', onTap: () {}),
          groups: [
            SideNavGroup(
              label: 'Training',
              items: [
                SideNavItem(
                  label: 'Dashboard',
                  icon: const Icon(Icons.grid_view),
                  active: true,
                  onTap: () {},
                ),
                SideNavItem(
                  label: 'Simulations',
                  icon: const Icon(Icons.timer_outlined),
                  onTap: onSimulations,
                ),
              ],
            ),
          ],
        );

    testWidgets('hover shifts an inactive label from dim2 to mid',
        (tester) async {
      await tester.pumpWidget(
        harness(SizedBox(height: 480, child: nav(onSimulations: () {}))),
      );

      Text label() => tester.widget<Text>(find.text('Simulations'));
      expect(label().style!.color, ClosColors.bone.dim2);

      await hoverOver(tester, find.text('Simulations'));
      expect(label().style!.color, ClosColors.bone.mid);
    });

    testWidgets('tap on an item invokes its onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        harness(
          SizedBox(height: 480, child: nav(onSimulations: () => taps++)),
        ),
      );
      await tester.tap(find.text('Simulations'));
      expect(taps, 1);
    });

    testWidgets('collapsed rail still exposes item labels to semantics',
        (tester) async {
      await tester.pumpWidget(
        harness(
          SizedBox(
            height: 480,
            child: nav(collapsed: true, onSimulations: () {}),
          ),
        ),
      );
      expect(find.text('Simulations'), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Simulations')),
        matchesSemantics(
          label: 'Simulations',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasSelectedState: true,
        ),
      );
    });

    testWidgets('shouldCollapse follows the collapseBelow token',
        (tester) async {
      final breakpoint = const ClosLayout().collapseBelow;
      Widget probe(double width) => MaterialApp(
            theme: closTheme(),
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 800)),
              child: Builder(
                builder: (context) => Text(
                  SideNav.shouldCollapse(context) ? 'collapsed' : 'expanded',
                ),
              ),
            ),
          );

      await tester.pumpWidget(probe(breakpoint - 1));
      expect(find.text('collapsed'), findsOneWidget);
      await tester.pumpWidget(probe(breakpoint + 1));
      expect(find.text('expanded'), findsOneWidget);
    });
  });
}
