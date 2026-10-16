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
