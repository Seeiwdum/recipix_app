import 'package:recipix_core/recipix_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('cooking moves home cook, and clear-expiring by urgent items used', () {
    final gains = badgeGains(
      RecipeCooked(today, recipe: recipe('r', ['x']), urgentItemsUsed: 2),
    );
    expect(gains, {BadgeIds.homeCook: 1, BadgeIds.clearExpiring: 2});
  });

  test('nothing urgent: only home cook', () {
    final gains = badgeGains(
      RecipeCooked(today, recipe: recipe('r', ['x']), urgentItemsUsed: 0),
    );
    expect(gains, {BadgeIds.homeCook: 1});
  });

  test('streak badges are never previewed', () {
    final gains = badgeGains(
      DayClosed(
        today,
        spent: Money.baht(10),
        allowance: Money.baht(100),
        discardedCount: 0,
      ),
    );
    expect(gains, isEmpty);
  });

  test('recipes default to easy with no steps', () {
    final r = recipe('r', ['x']);
    expect(r.difficulty, RecipeDifficulty.easy);
    expect(r.steps, isEmpty);
  });
}
