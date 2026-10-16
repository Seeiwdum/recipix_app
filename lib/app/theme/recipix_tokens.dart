import 'package:flutter/material.dart';

/// Every color, radius, spacing, type style and motion value the UI may use.
///
/// Widgets read these through `context.tokens`; literal values elsewhere in
/// `lib/` are a rule violation (COMPANY_RULES R2.3) and fail
/// `test/governance_test.dart`.
@immutable
class RecipixTokens extends ThemeExtension<RecipixTokens> {
  const RecipixTokens({
    required this.bg,
    required this.surface,
    required this.surfaceSunken,
    required this.line,
    required this.ink,
    required this.ink2,
    required this.accent,
    required this.onAccent,
    required this.warn,
    required this.warnText,
    required this.urgent,
  });

  /// "Paper kitchen" light palette (MASTER_PROMPT 5.2).
  static const light = RecipixTokens(
    bg: Color(0xFFF7F3EC),
    surface: Color(0xFFFFFDF9),
    surfaceSunken: Color(0xFFEFE9DF),
    line: Color(0xFFE3DBCE),
    ink: Color(0xFF1F1B16),
    ink2: Color(0xFF6B6358),
    accent: Color(0xFF2F6B4F),
    onAccent: Color(0xFFFFFDF9),
    warn: Color(0xFFC98A1B),
    // The spec's warn amber is too light for text (under 3:1 on paper), so
    // text and small labels use this darker shade of the same hue.
    warnText: Color(0xFF8A5A0B),
    urgent: Color(0xFFC4452F),
  );

  final Color bg;
  final Color surface;
  final Color surfaceSunken;
  final Color line;
  final Color ink;
  final Color ink2;

  /// The single accent. Also means "fresh".
  final Color accent;
  final Color onAccent;

  /// Expiring soon. Borders, dots, bars only; use [warnText] for text.
  final Color warn;
  final Color warnText;

  /// Urgent / error.
  final Color urgent;

  // Radii: three steps only.
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;

  // 8px grid; 4 only for hairline gaps.
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 16;
  static const double space4 = 24;
  static const double space5 = 32;
  static const double space6 = 48;

  static const double lineWidth = 1;
  static const double tapTarget = 48;
  static const double iconSize = 24;

  // Motion (MASTER_PROMPT 5.4).
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration countUp = Duration(milliseconds: 400);
  static const Duration staggerStep = Duration(milliseconds: 30);
  static const int staggerMaxItems = 6;
  static const double riseOffset = 8;
  static const double pressScale = 0.97;
  static const Curve enter = Cubic(.2, .8, .2, 1);
  static const Curve exit = Cubic(.4, 0, 1, 1);

  static const String fontFamily = 'IBMPlexSansThai';

  /// Thai needs room above and below the line for vowels and tone marks.
  static const double thaiLineHeight = 1.5;

  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  TextStyle get display => TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: ink,
    fontFeatures: tabularFigures,
  );

  TextStyle get title => TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: thaiLineHeight,
    color: ink,
  );

  TextStyle get body => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: thaiLineHeight,
    color: ink,
  );

  TextStyle get bodyMuted => body.copyWith(color: ink2);

  TextStyle get label => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: thaiLineHeight,
    color: ink,
  );

  TextStyle get caption => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: thaiLineHeight,
    color: ink2,
  );

  /// Numbers inside running text and tables.
  TextStyle get number => label.copyWith(fontFeatures: tabularFigures);

  @override
  RecipixTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceSunken,
    Color? line,
    Color? ink,
    Color? ink2,
    Color? accent,
    Color? onAccent,
    Color? warn,
    Color? warnText,
    Color? urgent,
  }) => RecipixTokens(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surfaceSunken: surfaceSunken ?? this.surfaceSunken,
    line: line ?? this.line,
    ink: ink ?? this.ink,
    ink2: ink2 ?? this.ink2,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    warn: warn ?? this.warn,
    warnText: warnText ?? this.warnText,
    urgent: urgent ?? this.urgent,
  );

  @override
  RecipixTokens lerp(RecipixTokens? other, double t) {
    if (other == null) return this;
    return RecipixTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnText: Color.lerp(warnText, other.warnText, t)!,
      urgent: Color.lerp(urgent, other.urgent, t)!,
    );
  }
}

extension RecipixTokensContext on BuildContext {
  RecipixTokens get tokens => Theme.of(this).extension<RecipixTokens>()!;
}
