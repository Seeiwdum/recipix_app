import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../fridge/domain/fridge_controller.dart';

/// Today's survival report over everything the user owns (shelves and the
/// basket both count: the shopping is in the house either way).
final survivalReportProvider = Provider<SurvivalReport>((ref) {
  return const SurvivalEngine().evaluate(
    items: ref.watch(fridgeProvider).items,
    profile: ref.watch(budgetProvider),
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
  if (ranked.isNotEmpty) return ranked.first;
  final any = matcher.rank(recipes, available);
  return any.isEmpty || any.first.haveKeys.isEmpty ? null : any.first;
});
