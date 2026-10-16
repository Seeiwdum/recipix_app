import 'dart:convert';

import 'package:recipix_core/recipix_core.dart';

/// Recipes from `assets/data/recipes.json`, shared by the home and random
/// tabs.
final class RecipeBook {
  RecipeBook(Iterable<Recipe> recipes) : recipes = List.unmodifiable(recipes);

  factory RecipeBook.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    final list = (json['recipes']! as List<Object?>)
        .cast<Map<String, Object?>>();
    return RecipeBook(list.map(_recipe));
  }

  static const assetPath = 'assets/data/recipes.json';

  final List<Recipe> recipes;

  static Recipe _recipe(Map<String, Object?> json) => Recipe(
    id: json['id']! as String,
    name: json['name']! as String,
    kcalPerServing: (json['kcal']! as num).toDouble(),
    cookMinutes: json['minutes'] as int? ?? 0,
    ingredients: [
      for (final i
          in (json['ingredients']! as List<Object?>)
              .cast<Map<String, Object?>>())
        RecipeIngredient(
          i['key']! as String,
          Quantity(
            (i['amount']! as num).toDouble(),
            QuantityUnit.values.byName(i['unit']! as String),
          ),
          optional: i['optional'] as bool? ?? false,
        ),
    ],
  );
}
