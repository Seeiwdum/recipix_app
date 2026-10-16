import 'package:recipix_core/recipix_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  const planner = MealPlanner();
  // Payday on the 19th: plan covers the 16th, 17th and 18th.
  final profile = UserBudgetProfile(
    foodBudget: Money.baht(300),
    paydayDayOfMonth: 19,
  );

  Recipe omelette() => Recipe(
    id: 'omelette',
    name: 'omelette',
    kcalPerServing: 350,
    ingredients: const [RecipeIngredient('egg', Quantity.pieces(2))],
  );
  Recipe basilPork() => Recipe(
    id: 'basil_pork',
    name: 'basil pork',
    kcalPerServing: 600,
    ingredients: const [
      RecipeIngredient('pork', Quantity.grams(150)),
      RecipeIngredient('basil', Quantity.grams(20)),
    ],
  );

  test('one slot per meal from now to the day before payday', () {
    final plan = planner.plan(
      items: const [],
      recipes: [omelette()],
      profile: profile,
      today: today,
    );
    expect(plan.meals, hasLength(9));
    expect(plan.eatOutMeals, 9);
    expect(plan.eatOutCost, Money.baht(540));
    expect(plan.shortfall, Money.baht(240));
  });

  test('meals already eaten today are skipped', () {
    final plan = planner.plan(
      items: const [],
      recipes: const [],
      profile: profile,
      today: today,
      mealsDoneToday: 2,
    );
    expect(plan.meals, hasLength(7));
    expect(plan.meals.first.slot, 2);
  });

  test('cooks from the fridge by quantity until it runs out', () {
    final plan = planner.plan(
      items: [item('egg', quantity: const Quantity.pieces(5), daysLeft: 20)],
      recipes: [omelette()],
      profile: profile,
      today: today,
    );
    // 5 eggs = two omelettes; the rest is bought.
    expect(plan.homeMeals, 2);
    expect(plan.eatOutMeals, 7);
  });

  test('uses urgent food first and never cooks with expired food', () {
    final plan = planner.plan(
      items: [
        item('egg', quantity: const Quantity.pieces(2), daysLeft: 20),
        item('pork', quantity: const Quantity.grams(150), daysLeft: 0),
        item('basil', quantity: const Quantity.grams(20), daysLeft: 0),
      ],
      recipes: [omelette(), basilPork()],
      profile: profile,
      today: today,
    );
    expect(plan.meals.first.recipe!.id, 'basil_pork');
    for (final m in plan.meals.where((m) => m.isHome)) {
      for (final p in m.uses) {
        expect(p.item.isExpired(m.date), isFalse);
      }
    }
  });

  test('food that expires before it can be used is reported', () {
    final plan = planner.plan(
      items: [
        item('basil', quantity: const Quantity.grams(20), daysLeft: 1),
        item('egg', quantity: const Quantity.pieces(12), daysLeft: 30),
      ],
      recipes: [omelette(), basilPork()],
      profile: profile,
      today: today,
    );
    expect(plan.willSpoil.map((i) => i.key), ['basil']);
  });

  test('food no recipe uses is not reported as spoiling', () {
    final plan = planner.plan(
      items: [item('yogurt', daysLeft: 1)],
      recipes: [omelette()],
      profile: profile,
      today: today,
    );
    expect(plan.willSpoil, isEmpty);
  });

  test('avoids the same dish twice in a row when there is a choice', () {
    final plan = planner.plan(
      items: [
        item('egg', quantity: const Quantity.pieces(4), daysLeft: 20),
        item('pork', quantity: const Quantity.grams(300), daysLeft: 20),
        item('basil', quantity: const Quantity.grams(40), daysLeft: 20),
      ],
      recipes: [omelette(), basilPork()],
      profile: profile,
      today: today,
    );
    final home = plan.meals.take(4).map((m) => m.recipe?.id).toList();
    for (var i = 1; i < home.length; i++) {
      expect(home[i], isNot(home[i - 1]));
    }
    expect(plan.nextHomeMeal, same(plan.meals.first));
  });

  test('mystery items are never planned', () {
    final plan = planner.plan(
      items: [item('box', mystery: true)],
      recipes: [omelette()],
      profile: profile,
      today: today,
    );
    expect(plan.homeMeals, 0);
  });
}
