import 'package:recipix_core/recipix_core.dart';

final today = LocalDate(2026, 10, 16);

IngredientItem item(
  String id, {
  String? key,
  bool mystery = false,
  int daysLeft = 5,
  Quantity quantity = const Quantity.pieces(1),
  double kcalPerUnit = 100,
}) => IngredientItem(
  id: id,
  name: id,
  key: mystery ? null : (key ?? id),
  quantity: quantity,
  kcalPerUnit: kcalPerUnit,
  expiresOn: today.addDays(daysLeft),
);

Recipe recipe(
  String id,
  List<String> keys, {
  List<String> optional = const [],
}) => Recipe(
  id: id,
  name: id,
  kcalPerServing: 500,
  ingredients: [
    for (final k in keys) RecipeIngredient(k, const Quantity.pieces(1)),
    for (final k in optional)
      RecipeIngredient(k, const Quantity.pieces(1), optional: true),
  ],
);
