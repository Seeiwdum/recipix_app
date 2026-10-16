import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../budget/domain/budget_controller.dart';
import '../../fridge/domain/fridge_controller.dart';

/// Today's survival report over everything the user owns (shelves and the
/// basket both count: the shopping is in the house either way).
final survivalReportProvider = Provider<SurvivalReport>((ref) {
  return const SurvivalEngine().evaluate(
    items: ref.watch(fridgeProvider).items,
    profile: ref.watch(budgetProfileProvider),
    today: ref.watch(todayProvider),
  );
});

/// Items for the "use first" list: expired first, then by days left.
final useFirstProvider = Provider<List<IngredientItem>>((ref) {
  final report = ref.watch(survivalReportProvider);
  return [...report.expiredItems, ...report.urgentItems];
});

/// One dish to suggest: the best match that uses something urgent, or the
/// best match overall when nothing is urgent. Null when nothing matches.
/// Shown only when the plan has no home meal to offer.
final menuSuggestionProvider = Provider<RecipeMatch?>((ref) {
  final items = ref.watch(fridgeProvider).items;
  final today = ref.watch(todayProvider);
  final recipes = ref.watch(recipeBookProvider).recipes;
  final pool = IngredientSlotMachine.usablePool(items, today);
  final available = {for (final i in pool) i.key!};
  final urgent = {
    for (final i in pool)
      if (i.isUrgent(today)) i.key!,
  };
  const matcher = RecipeMatcher();
  final ranked = matcher.rank(recipes, available, focusKeys: urgent);
  // Never suggest a dish with nothing on hand (it showed "0%" on an empty
  // fridge — critique: ฎา, ธนากร).
  if (ranked.isNotEmpty && ranked.first.haveKeys.isNotEmpty) {
    return ranked.first;
  }
  final any = matcher.rank(recipes, available);
  return any.isEmpty || any.first.haveKeys.isEmpty ? null : any.first;
});

/// Every meal from now to payday (ADR-008). Meals already covered today —
/// dishes cooked here plus eat-out spending logged — are not planned again.
final mealPlanProvider = Provider<MealPlan>((ref) {
  final today = ref.watch(todayProvider);
  final fridge = ref.watch(fridgeProvider);
  return const MealPlanner().plan(
    items: fridge.items,
    recipes: ref.watch(recipeBookProvider).recipes,
    profile: ref.watch(budgetProfileProvider),
    today: today,
    mealsDoneToday:
        fridge.cookedOn(today) + ref.watch(ledgerProvider).eatOutMealsToday,
  );
});
