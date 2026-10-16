import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../budget/domain/budget_controller.dart';
import '../../fridge/domain/fridge_controller.dart';
import '../../profile/domain/profile_controller.dart';

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

/// Why a dish is on the home suggestion list (ADR-015).
enum SuggestionSource {
  /// Uses something from the fridge (urgent items first).
  fridge,

  /// One of the dishes the user said they like (ADR-017).
  favorite,

  /// An easy everyday dish, to fill the list when the fridge has little.
  easy,
}

final class MenuSuggestion {
  const MenuSuggestion(this.match, this.source);

  final RecipeMatch match;
  final SuggestionSource source;
}

/// Up to [maxMenuSuggestions] dishes for the home page. First dishes that
/// use what is in the fridge — those using something urgent before the
/// rest — then easy dishes, fewest missing first. A dish with nothing on
/// hand is never listed as "from the fridge" (it showed "0%" on an empty
/// fridge — critique: ฎา, ธนากร). The plan's next home meal is left out,
/// it already has its own line.
const maxMenuSuggestions = 3;

final menuSuggestionsProvider = Provider<List<MenuSuggestion>>((ref) {
  final items = ref.watch(fridgeProvider).items;
  final today = ref.watch(todayProvider);
  final recipes = ref.watch(recipeBookProvider).recipes;
  final skip = ref.watch(mealPlanProvider).nextHomeMeal?.recipe?.id;
  final pool = IngredientSlotMachine.usablePool(items, today);
  final available = {for (final i in pool) i.key!};
  final urgent = {
    for (final i in pool)
      if (i.isUrgent(today)) i.key!,
  };
  const matcher = RecipeMatcher();

  final out = <MenuSuggestion>[];
  final seen = <String>{?skip};
  void take(Iterable<RecipeMatch> matches, SuggestionSource source) {
    for (final m in matches) {
      if (out.length == maxMenuSuggestions) return;
      if (seen.add(m.recipe.id)) out.add(MenuSuggestion(m, source));
    }
  }

  bool onHand(RecipeMatch m) => m.haveKeys.isNotEmpty;
  final favorites = ref.watch(profileProvider).favoriteRecipeIds;
  bool fav(RecipeMatch m) => favorites.contains(m.recipe.id);
  final urgentRanked = urgent.isEmpty
      ? const <RecipeMatch>[]
      : matcher.rank(recipes, available, focusKeys: urgent).where(onHand);
  final onHandRanked = matcher.rank(recipes, available).where(onHand);

  // 1. The best dish that saves something about to expire (a favourite if
  //    one does).
  take(
    [...urgentRanked.where(fav), ...urgentRanked].take(1),
    SuggestionSource.fridge,
  );
  // 2. Favourites (ADR-017): on hand first, then the rest.
  take(onHandRanked.where(fav), SuggestionSource.fridge);
  take([
    for (final r in recipes)
      if (favorites.contains(r.id)) matcher.match(r, available),
  ], SuggestionSource.favorite);
  // 3. Other dishes from the fridge, urgent ones first.
  take([...urgentRanked, ...onHandRanked], SuggestionSource.fridge);
  final easy =
      [
        for (final r in recipes)
          if (r.difficulty == RecipeDifficulty.easy)
            matcher.match(r, available),
      ]..sort((a, b) {
        final byMissing = a.missingKeys.length.compareTo(b.missingKeys.length);
        return byMissing != 0
            ? byMissing
            : a.recipe.cookMinutes.compareTo(b.recipe.cookMinutes);
      });
  take(easy, SuggestionSource.easy);
  return out;
});

/// Everything the recipe page shows for one dish (ADR-015).
final class RecipeDetail {
  const RecipeDetail({
    required this.match,
    required this.urgentItemsUsed,
    required this.badgeGains,
  });

  final RecipeMatch match;
  Recipe get recipe => match.recipe;

  /// Items within 0-2 days of expiry that cooking it now would use up.
  final int urgentItemsUsed;

  /// Badge id -> how far cooking it now moves that badge.
  final Map<String, int> badgeGains;
}

final recipeDetailProvider = Provider.family<RecipeDetail?, String>((
  ref,
  recipeId,
) {
  Recipe? recipe;
  for (final r in ref.watch(recipeBookProvider).recipes) {
    if (r.id == recipeId) recipe = r;
  }
  if (recipe == null) return null;
  final items = ref.watch(fridgeProvider).items;
  final today = ref.watch(todayProvider);
  final available = {
    for (final i in IngredientSlotMachine.usablePool(items, today)) i.key!,
  };
  final urgent = const InventoryService()
      .cook(items, recipe, today: today)
      .urgentItemsUsed;
  return RecipeDetail(
    match: const RecipeMatcher().match(recipe, available),
    urgentItemsUsed: urgent,
    badgeGains: badgeGains(
      RecipeCooked(today, recipe: recipe, urgentItemsUsed: urgent),
    ),
  );
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
