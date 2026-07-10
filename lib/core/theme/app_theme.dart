import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// Builds the app [ThemeData] entirely from the generated token extensions.
/// Widgets read tokens via the [ClosThemeContext] getters, never raw values.
ThemeData closTheme() {
  const colors = ClosColors.bone;
  const spacing = ClosSpacing();
  const radius = ClosRadius();
  const type = ClosType();
  const layout = ClosLayout();

  return ThemeData(
    useMaterial3: true,
    fontFamily: ClosType.bodyFamily,
    textTheme: type.textTheme,
    scaffoldBackgroundColor: colors.base,
    canvasColor: colors.base,
    dividerColor: colors.border,
    colorScheme: ColorScheme.dark(
      surface: colors.surface,
      onSurface: colors.hi1,
      primary: colors.accent,
      onPrimary: colors.base,
      secondary: colors.accentDim,
      onSecondary: colors.base,
      error: colors.red,
      onError: colors.base,
      outline: colors.border,
      outlineVariant: colors.border2,
    ),
    extensions: const [colors, spacing, radius, type, layout],
  );
}

/// Shorthand token access: `context.closColors.accent`, `context.sp.sp6`.
extension ClosThemeContext on BuildContext {
  ClosColors get closColors => Theme.of(this).extension<ClosColors>()!;
  ClosSpacing get sp => Theme.of(this).extension<ClosSpacing>()!;
  ClosRadius get closRadius => Theme.of(this).extension<ClosRadius>()!;
  ClosType get closType => Theme.of(this).extension<ClosType>()!;
  ClosLayout get closLayout => Theme.of(this).extension<ClosLayout>()!;
}
