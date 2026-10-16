import '../common/local_date.dart';
import '../common/quantity.dart';
import '../entities/ingredient_item.dart';
import '../entities/recipe.dart';

/// A portion taken from one fridge item while cooking.
final class ConsumedPortion {
  const ConsumedPortion({
    required this.item,
    required this.amount,
    required this.daysLeft,
  });

  /// The item as it was before cooking.
  final IngredientItem item;

  /// Amount taken, in the item's own unit.
  final Quantity amount;

  final int daysLeft;

  bool get wasUrgent => daysLeft >= 0 && daysLeft <= urgentWindowDays;
}

final class CookResult {
  CookResult({
    required List<IngredientItem> remaining,
    required List<ConsumedPortion> consumed,
    required Map<String, Quantity> shortfall,
  }) : remaining = List.unmodifiable(remaining),
       consumed = List.unmodifiable(consumed),
       shortfall = Map.unmodifiable(shortfall);

  /// Fridge contents after cooking. Items used up are removed.
  final List<IngredientItem> remaining;

  final List<ConsumedPortion> consumed;

  /// Required amounts that could not be found, keyed by ingredient key,
  /// in the recipe's unit.
  final Map<String, Quantity> shortfall;

  bool get isComplete => shortfall.isEmpty;

  int get urgentItemsUsed => {
    for (final p in consumed)
      if (p.wasUrgent) p.item.id,
  }.length;
}

/// Deducts recipe amounts from the fridge.
///
/// Fixes the old demo, which removed whole items regardless of amount:
/// here each ingredient is taken by quantity, first-expiring-first-out,
/// across every matching item with a compatible unit.
final class InventoryService {
  const InventoryService();

  CookResult cook(
    List<IngredientItem> fridge,
    Recipe recipe, {
    required LocalDate today,
    double batches = 1,
  }) {
    final stock = {for (final item in fridge) item.id: item};
    final consumed = <ConsumedPortion>[];
    final shortfall = <String, Quantity>{};

    for (final need in recipe.ingredients) {
      var left = Quantity(need.quantity.amount * batches, need.quantity.unit);
      final candidates =
          stock.values
              .where(
                (i) =>
                    i.key == need.key &&
                    !i.isExpired(today) &&
                    !i.quantity.isEmpty &&
                    i.quantity.isCompatibleWith(need.quantity),
              )
              .toList()
            ..sort((a, b) => a.expiresOn.compareTo(b.expiresOn));

      for (final item in candidates) {
        if (left.isEmpty) break;
        final available = item.quantity.convertTo(left.unit);
        final take = available.amount < left.amount
            ? available
            : Quantity(left.amount, left.unit);
        final takeInItemUnit = take.convertTo(item.quantity.unit);

        consumed.add(
          ConsumedPortion(
            item: item,
            amount: takeInItemUnit,
            daysLeft: item.daysUntilExpiry(today),
          ),
        );
        final rest = item.quantity - takeInItemUnit;
        if (rest.isEmpty) {
          stock.remove(item.id);
        } else {
          stock[item.id] = item.copyWith(quantity: rest);
        }
        left = left - take;
      }

      if (!left.isEmpty && !need.optional) {
        shortfall.update(need.key, (q) => q + left, ifAbsent: () => left);
      }
    }

    return CookResult(
      remaining: [for (final item in fridge) ?stock[item.id]],
      consumed: consumed,
      shortfall: shortfall,
    );
  }
}
