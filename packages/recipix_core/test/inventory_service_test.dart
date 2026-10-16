import 'package:recipix_core/recipix_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  const service = InventoryService();

  Recipe friedRice() => Recipe(
    id: 'fried-rice',
    name: 'fried rice',
    kcalPerServing: 600,
    ingredients: const [
      RecipeIngredient('rice', Quantity.grams(200)),
      RecipeIngredient('egg', Quantity.pieces(2)),
      RecipeIngredient('chili', Quantity.pieces(1), optional: true),
    ],
  );

  test('deducts by quantity instead of removing whole items', () {
    final result = service.cook(
      [
        item('rice', quantity: const Quantity(1, QuantityUnit.kilogram)),
        item('egg', quantity: const Quantity.pieces(10)),
      ],
      friedRice(),
      today: today,
    );
    expect(result.isComplete, isTrue);
    final rice = result.remaining.firstWhere((i) => i.id == 'rice');
    expect(rice.quantity.unit, QuantityUnit.kilogram);
    expect(rice.quantity.amount, closeTo(0.8, 1e-9));
    final eggs = result.remaining.firstWhere((i) => i.id == 'egg');
    expect(eggs.quantity.amount, 8);
  });

  test('uses earliest-expiring stock first and removes used-up items', () {
    final result = service.cook(
      [
        item(
          'egg-late',
          key: 'egg',
          daysLeft: 9,
          quantity: const Quantity.pieces(6),
        ),
        item(
          'egg-soon',
          key: 'egg',
          daysLeft: 1,
          quantity: const Quantity.pieces(1),
        ),
        item('rice', quantity: const Quantity.grams(500)),
      ],
      friedRice(),
      today: today,
    );
    expect(result.remaining.map((i) => i.id), ['egg-late', 'rice']);
    expect(result.remaining.first.quantity.amount, 5);
    expect(result.consumed.map((p) => p.item.id), [
      'rice',
      'egg-soon',
      'egg-late',
    ]);
    expect(result.urgentItemsUsed, 1);
  });

  test('reports shortfall in recipe units; optional items never short', () {
    final result = service.cook(
      [item('rice', quantity: const Quantity.grams(50))],
      friedRice(),
      today: today,
    );
    expect(result.isComplete, isFalse);
    expect(result.shortfall['rice']!.amount, 150);
    expect(result.shortfall['egg']!.amount, 2);
    expect(result.shortfall.containsKey('chili'), isFalse);
    expect(result.remaining, isEmpty);
  });

  test('skips expired and unit-incompatible stock', () {
    final result = service.cook(
      [
        item('rice', daysLeft: -1, quantity: const Quantity.grams(1000)),
        item('rice-bag', key: 'rice', quantity: const Quantity.pieces(1)),
        item('egg', quantity: const Quantity.pieces(2)),
      ],
      friedRice(),
      today: today,
    );
    expect(result.shortfall['rice']!.amount, 200);
    expect(result.remaining.map((i) => i.id), ['rice', 'rice-bag']);
  });

  test('batches multiply amounts', () {
    final result = service.cook(
      [
        item('rice', quantity: const Quantity.grams(1000)),
        item('egg', quantity: const Quantity.pieces(10)),
      ],
      friedRice(),
      today: today,
      batches: 2,
    );
    expect(
      result.remaining.firstWhere((i) => i.id == 'egg').quantity.amount,
      6,
    );
  });
}
