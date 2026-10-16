import 'package:flutter/material.dart';

import 'recipix_tokens.dart';

/// Material theme built from [RecipixTokens]. Material defaults that clash
/// with the design system (ripples, tinted elevation, shadows) are off.
ThemeData buildRecipixTheme([RecipixTokens t = RecipixTokens.light]) {
  final scheme = ColorScheme.light(
    primary: t.accent,
    onPrimary: t.onAccent,
    secondary: t.accent,
    onSecondary: t.onAccent,
    error: t.urgent,
    onError: t.onAccent,
    surface: t.surface,
    onSurface: t.ink,
    onSurfaceVariant: t.ink2,
    outline: t.line,
    outlineVariant: t.line,
    surfaceTint: t.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.bg,
    fontFamily: RecipixTokens.fontFamily,
    dividerColor: t.line,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    textTheme: TextTheme(
      displayLarge: t.display,
      titleLarge: t.title,
      titleMedium: t.title.copyWith(fontSize: 17),
      bodyLarge: t.body,
      bodyMedium: t.body.copyWith(fontSize: 15),
      labelLarge: t.label,
      bodySmall: t.caption,
      labelSmall: t.caption,
    ),
    extensions: [t],
  );
}
