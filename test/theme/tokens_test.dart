import 'dart:convert';
import 'dart:io';

import 'package:closero_app/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract tests: the generated token extensions must match
/// context/design-tokens.json exactly, and the type scale must obey the
/// family and letter-spacing rules.
void main() {
  final tokens = jsonDecode(
    File('context/design-tokens.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  group('ClosColors', () {
    const c = ClosColors.bone;
    final byName = <String, Color>{
      'base': c.base,
      'sidebar': c.sidebar,
      'surface': c.surface,
      'surface2': c.surface2,
      'border': c.border,
      'border2': c.border2,
      'dim3': c.dim3,
      'dim2': c.dim2,
      'dim1': c.dim1,
      'body': c.body,
      'mid': c.mid,
      'hi2': c.hi2,
      'hi1': c.hi1,
      'accent': c.accent,
      'accentDim': c.accentDim,
      'green': c.green,
      'warn': c.warn,
      'red': c.red,
      'destructive': c.destructive,
      'onDestructive': c.onDestructive,
      'flame': c.flame,
    };

    test('covers every token in design-tokens.json, by name and value', () {
      final jsonColors = tokens['color'] as Map<String, dynamic>;
      expect(byName.keys, containsAll(jsonColors.keys));
      expect(jsonColors.keys, containsAll(byName.keys));
      for (final entry in jsonColors.entries) {
        final hex = ((entry.value as Map<String, dynamic>)['value'] as String)
            .substring(1);
        expect(
          byName[entry.key]!.toARGB32(),
          0xFF000000 | int.parse(hex, radix: 16),
          reason: 'color token ${entry.key}',
        );
      }
    });
  });

  group('ClosSpacing', () {
    const s = ClosSpacing();
    final byName = <String, double>{
      'sp1': s.sp1,
      'sp2': s.sp2,
      'sp3': s.sp3,
      'sp4': s.sp4,
      'sp5': s.sp5,
      'sp6': s.sp6,
      'sp8': s.sp8,
      'sp10': s.sp10,
      'sp12': s.sp12,
      'sp16': s.sp16,
      'sp20': s.sp20,
      'sp24': s.sp24,
    };

    test('matches the JSON 4px scale exactly', () {
      final scale = (tokens['spacing'] as Map<String, dynamic>)['scale']
          as Map<String, dynamic>;
      expect(byName.keys, containsAll(scale.keys));
      expect(scale.keys, containsAll(byName.keys));
      for (final entry in scale.entries) {
        expect(byName[entry.key], (entry.value as num).toDouble(),
            reason: 'spacing token ${entry.key}');
        expect(byName[entry.key]! % 4, 0,
            reason: '${entry.key} must sit on the 4px scale');
      }
    });

    test('rule helpers: headline gap is sp3, section gap is sp6', () {
      expect(s.headlineToSubtext, s.sp3);
      expect(s.headlineToSubtext, 12);
      expect(s.sectionGap, s.sp6);
      expect(s.sectionGap, 24);
    });
  });

  group('ClosRadius', () {
    const r = ClosRadius();

    test('card 6, button 5, full for circles and end-caps only', () {
      expect(r.card, 6);
      expect(r.button, 5);
      expect(r.full, greaterThan(100));
    });
  });

  group('ClosType', () {
    const t = ClosType();

    test('every style in the scale obeys the family rule', () {
      final theme = t.textTheme;
      final styles = <String, TextStyle>{
        'displayLarge': theme.displayLarge!,
        'displayMedium': theme.displayMedium!,
        'displaySmall': theme.displaySmall!,
        'headlineLarge': theme.headlineLarge!,
        'headlineMedium': theme.headlineMedium!,
        'headlineSmall': theme.headlineSmall!,
        'titleLarge': theme.titleLarge!,
        'titleMedium': theme.titleMedium!,
        'titleSmall': theme.titleSmall!,
        'bodyLarge': theme.bodyLarge!,
        'bodyMedium': theme.bodyMedium!,
        'bodySmall': theme.bodySmall!,
        'labelLarge': theme.labelLarge!,
        'labelMedium': theme.labelMedium!,
        'labelSmall': theme.labelSmall!,
      };
      for (final entry in styles.entries) {
        final style = entry.value;
        final expected =
            ClosType.familyFor(style.fontSize!, style.fontWeight!);
        expect(style.fontFamily, expected, reason: entry.key);
      }
    });

    test('familyFor: 18px+ AND bold is display, everything else body', () {
      expect(ClosType.familyFor(18, FontWeight.w700), ClosType.displayFamily);
      expect(ClosType.familyFor(24, FontWeight.w600), ClosType.displayFamily);
      expect(ClosType.familyFor(17, FontWeight.w700), ClosType.bodyFamily);
      expect(ClosType.familyFor(18, FontWeight.w500), ClosType.bodyFamily);
      expect(ClosType.familyFor(40, FontWeight.w400), ClosType.bodyFamily);
    });

    test('letter-spacing rules: titles -0.02em, buttons -0.01em', () {
      expect(t.displayLarge.letterSpacing, closeTo(-0.02 * 40, 1e-9));
      expect(t.headlineSmall.letterSpacing, closeTo(-0.02 * 18, 1e-9));
      expect(t.labelLarge.letterSpacing, closeTo(-0.01 * 14, 1e-9));
      expect(t.labelSmall.letterSpacing, greaterThanOrEqualTo(0.05 * 10));
    });

    test('body copy sizes never drop below the 12px minimum', () {
      expect(t.bodySmall.fontSize, greaterThanOrEqualTo(12));
      expect(t.bodyMedium.fontSize, greaterThanOrEqualTo(12));
      expect(t.bodyLarge.fontSize, greaterThanOrEqualTo(12));
    });

    test('body copy uses the body token, never dim1/dim2', () {
      const c = ClosColors.bone;
      for (final style in [t.bodyLarge, t.bodyMedium, t.bodySmall]) {
        expect(style.color, c.body);
        expect(style.color, isNot(c.dim1));
        expect(style.color, isNot(c.dim2));
      }
    });
  });

  group('closTheme', () {
    test('exposes all four extensions and the base background', () {
      final theme = closTheme();
      expect(theme.extension<ClosColors>(), isNotNull);
      expect(theme.extension<ClosSpacing>(), isNotNull);
      expect(theme.extension<ClosRadius>(), isNotNull);
      expect(theme.extension<ClosType>(), isNotNull);
      expect(theme.scaffoldBackgroundColor, ClosColors.bone.base);
    });
  });
}
