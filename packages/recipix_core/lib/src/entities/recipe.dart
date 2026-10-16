import '../common/quantity.dart';

final class RecipeIngredient {
  const RecipeIngredient(this.key, this.quantity, {this.optional = false});

  final String key;
  final Quantity quantity;

  /// Optional ingredients are used when present but never count as missing.
  final bool optional;
}

/// How hard a dish is for an everyday home cook.
enum RecipeDifficulty { easy, medium, hard }

final class Recipe {
  Recipe({
    required this.id,
    required this.name,
    required List<RecipeIngredient> ingredients,
    required this.kcalPerServing,
    this.servings = 1,
    this.cookMinutes = 0,
    this.difficulty = RecipeDifficulty.easy,
    List<String> steps = const [],
  }) : ingredients = List.unmodifiable(ingredients),
       steps = List.unmodifiable(steps),
       requiredKeys = Set.unmodifiable({
         for (final i in ingredients)
           if (!i.optional) i.key,
       });

  final String id;
  final String name;

  /// Amounts for one batch of [servings] servings.
  final List<RecipeIngredient> ingredients;
  final int servings;
  final double kcalPerServing;
  final int cookMinutes;
  final RecipeDifficulty difficulty;

  /// Method, one instruction per step, in order.
  final List<String> steps;

  /// Keys that must be present for a 100% match.
  final Set<String> requiredKeys;

  @override
  String toString() => 'Recipe($id, $name)';
}
