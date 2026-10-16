import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/theme/recipix_tokens.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  const t = RecipixTokens.light;

  group('text contrast >= 4.5:1 (checklist 5.5)', () {
    final pairs = {
      'ink on bg': (t.ink, t.bg),
      'ink on surface': (t.ink, t.surface),
      'ink on sunken': (t.ink, t.surfaceSunken),
      'ink2 on bg': (t.ink2, t.bg),
      'ink2 on surface': (t.ink2, t.surface),
      'accent on surface': (t.accent, t.surface),
      'accent on bg': (t.accent, t.bg),
      'onAccent on accent': (t.onAccent, t.accent),
      'warnText on surface': (t.warnText, t.surface),
      'warnText on bg': (t.warnText, t.bg),
      'urgent on surface': (t.urgent, t.surface),
    };
    pairs.forEach((name, pair) {
      test(name, () {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      });
    });
  });

  test('warn amber is not text-safe, which is why warnText exists', () {
    expect(contrast(t.warn, t.surface), lessThan(4.5));
  });

  test('ink2 stays readable on sunken surfaces (>= 4.5:1)', () {
    expect(contrast(t.ink2, t.surfaceSunken), greaterThanOrEqualTo(4.5));
  });

  test('radii are 10/16/24 only', () {
    expect(
      [RecipixTokens.radiusSm, RecipixTokens.radiusMd, RecipixTokens.radiusLg],
      [10, 16, 24],
    );
  });

  test('motion durations match the spec', () {
    expect(RecipixTokens.fast.inMilliseconds, 120);
    expect(RecipixTokens.medium.inMilliseconds, 220);
    expect(RecipixTokens.slow.inMilliseconds, 360);
  });

  test('Thai line height is at least 1.5 for body text', () {
    for (final style in [t.title, t.body, t.label, t.caption]) {
      expect(style.height, greaterThanOrEqualTo(1.5));
    }
  });
}
