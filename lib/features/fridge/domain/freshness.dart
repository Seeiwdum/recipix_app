import 'package:recipix_core/recipix_core.dart';

/// How an item's freshness is shown: label, edge color and fade.
enum Freshness {
  fresh,

  /// 3-5 days left.
  soon,

  /// 0-2 days left (recipix_core `urgentWindowDays`).
  urgent,
  expired;

  static const int soonWindowDays = 5;

  static Freshness of(IngredientItem item, LocalDate today) {
    final days = item.daysUntilExpiry(today);
    if (days < 0) return expired;
    if (days <= urgentWindowDays) return urgent;
    if (days <= soonWindowDays) return soon;
    return fresh;
  }
}

/// Filters highlight matching items and dim the rest.
enum FridgeFilter {
  all,
  useSoon,
  produce,
  protein,
  unknown;

  bool matches(IngredientItem item, LocalDate today) => switch (this) {
    all => true,
    useSoon => Freshness.of(item, today) != Freshness.fresh,
    produce =>
      item.category == IngredientCategory.vegetable ||
          item.category == IngredientCategory.fruit,
    protein =>
      item.category == IngredientCategory.meat ||
          item.category == IngredientCategory.seafood ||
          item.category == IngredientCategory.eggDairy,
    unknown => !item.isIdentified,
  };
}
