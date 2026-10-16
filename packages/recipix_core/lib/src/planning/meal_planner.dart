import '../common/local_date.dart';
import '../common/money.dart';
import '../entities/ingredient_item.dart';
import '../entities/recipe.dart';
import '../entities/user_budget_profile.dart';
import '../inventory/inventory_service.dart';
import '../survival/survival_engine.dart';

/// One meal slot in the plan: cooked at home from the fridge, or bought.
final class PlannedMeal {
  PlannedMeal({
    required this.date,
    required this.slot,
    required this.recipe,
    required List<ConsumedPortion> uses,
    required this.eatOutCost,
  }) : uses = List.unmodifiable(uses);

  final LocalDate date;

  /// 0-based meal of the day.
  final int slot;

  /// Null for a meal bought outside.
  final Recipe? recipe;

  /// What cooking it takes out of the fridge.
  final List<ConsumedPortion> uses;

  /// Zero for home meals.
  final Money eatOutCost;

  bool get isHome => recipe != null;
}

final class MealPlan {
  MealPlan({
    required List<PlannedMeal> meals,
    required this.budget,
    required List<IngredientItem> willSpoil,
  }) : meals = List.unmodifiable(meals),
       willSpoil = List.unmodifiable(willSpoil);

  final List<PlannedMeal> meals;

  /// Budget left when the plan was made.
  final Money budget;

  /// Items that would still expire unused before payday, even on this plan.
  final List<IngredientItem> willSpoil;

  int get homeMeals => meals.where((m) => m.isHome).length;
  int get eatOutMeals => meals.length - homeMeals;

  Money get eatOutCost =>
      meals.fold(Money.zero, (sum, m) => sum + m.eatOutCost);

  /// Money still missing if the user eats exactly as planned.
  Money get shortfall => Money.max(Money.zero, eatOutCost - budget);

  PlannedMeal? get nextHomeMeal {
    for (final m in meals) {
      if (m.isHome) return m;
    }
    return null;
  }
}

/// Plans every meal from now to payday, cooking from the fridge first and
/// buying the rest (ADR-008).
///
/// Greedy and deterministic: each slot takes the fully cookable recipe that
/// uses the most urgent food (weight 1/(daysLeft+1) per ingredient used),
/// avoiding the same dish twice in a row. Cooking is simulated with
/// [InventoryService], so quantities and expiry dates stay real.
final class MealPlanner {
  const MealPlanner({this.inventory = const InventoryService()});

  final InventoryService inventory;

  MealPlan plan({
    required List<IngredientItem> items,
    required List<Recipe> recipes,
    required UserBudgetProfile profile,
    required LocalDate today,
    int mealsDoneToday = 0,
  }) {
    final payday = const SurvivalEngine().nextPayday(profile, today);
    final perDay = profile.prices.mealsPerDay;
    final mealPrice = profile.prices.mealOutPrice;
    var stock = [...items.where((i) => i.isIdentified)];
    final meals = <PlannedMeal>[];
    String? previous;

    for (var day = today; day.isBefore(payday); day = day.addDays(1)) {
      final first = day == today ? mealsDoneToday.clamp(0, perDay) : 0;
      final usedToday = <String>{};
      for (var slot = first; slot < perDay; slot++) {
        CookResult? best;
        Recipe? bestRecipe;
        var bestScore = double.negativeInfinity;
        for (final r in recipes) {
          final result = inventory.cook(stock, r, today: day);
          if (!result.isComplete || result.consumed.isEmpty) continue;
          var score = 0.0;
          for (final p in result.consumed) {
            score += 1 / (p.item.daysUntilExpiry(day) + 1);
          }
          if (r.id == previous) score -= 10;
          if (usedToday.contains(r.id)) score -= 1;
          if (score > bestScore ||
              (score == bestScore && r.id.compareTo(bestRecipe!.id) < 0)) {
            best = result;
            bestRecipe = r;
            bestScore = score;
          }
        }
        if (best != null && bestRecipe != null) {
          stock = best.remaining;
          meals.add(
            PlannedMeal(
              date: day,
              slot: slot,
              recipe: bestRecipe,
              uses: best.consumed,
              eatOutCost: Money.zero,
            ),
          );
          previous = bestRecipe.id;
          usedToday.add(bestRecipe.id);
        } else {
          meals.add(
            PlannedMeal(
              date: day,
              slot: slot,
              recipe: null,
              uses: const [],
              eatOutCost: mealPrice,
            ),
          );
          previous = null;
        }
      }
    }

    // Only food some recipe could use counts as spoiling: milk or yogurt
    // that no dish calls for is eaten as it is, not wasted.
    final cookable = {
      for (final r in recipes)
        for (final i in r.ingredients) i.key,
    };
    return MealPlan(
      meals: meals,
      budget: profile.foodBudget,
      willSpoil: [
        for (final i in stock)
          if (cookable.contains(i.key) &&
              i.expiresOn.isBefore(payday) &&
              !i.isExpired(today))
            i,
      ],
    );
  }
}
