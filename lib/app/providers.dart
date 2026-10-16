import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../features/fridge/data/ingredient_catalog.dart';
import '../shared/data/recipe_book.dart';

/// The calendar day everything is computed against. Tests override it.
final todayProvider = Provider<LocalDate>(
  (ref) => LocalDate.fromDateTime(DateTime.now()),
);

/// Loaded once in `main()` before the first frame and injected with
/// `catalogProvider.overrideWithValue(...)`.
final catalogProvider = Provider<IngredientCatalog>(
  (ref) => throw UnimplementedError('catalogProvider must be overridden'),
);

/// Loaded in `main()` like [catalogProvider].
final recipeBookProvider = Provider<RecipeBook>(
  (ref) => throw UnimplementedError('recipeBookProvider must be overridden'),
);

/// The user's food budget. Starts with sample values until the dashboard
/// lets the user edit them and persistence lands (Phase 3).
final budgetProvider = NotifierProvider<BudgetController, UserBudgetProfile>(
  BudgetController.new,
);

class BudgetController extends Notifier<UserBudgetProfile> {
  static final sample = UserBudgetProfile(foodBudget: Money.baht(1600));

  @override
  UserBudgetProfile build() => sample;

  void update(UserBudgetProfile profile) => state = profile;
}
