import 'dart:math';

import '../common/local_date.dart';
import '../entities/ingredient_item.dart';

/// Chooses which ingredients land on the reels (port of `ISlotRollStrategy`).
abstract interface class SlotRollStrategy {
  /// Picks up to [count] distinct items from [pool]. The pool is already
  /// filtered to usable, identified, unexpired items with unique keys.
  List<IngredientItem> pick(
    List<IngredientItem> pool,
    int count,
    Random random,
    LocalDate today,
  );
}

/// Uniform random pick without replacement.
final class PureRandomRollStrategy implements SlotRollStrategy {
  const PureRandomRollStrategy();

  @override
  List<IngredientItem> pick(
    List<IngredientItem> pool,
    int count,
    Random random,
    LocalDate today,
  ) {
    final shuffled = [...pool]..shuffle(random);
    return shuffled.take(count).toList();
  }
}

/// Weighted pick that favours items close to expiry, to cut food waste.
///
/// Weight is `1 / (daysLeft + 1)^2`: an item expiring today is 4x as
/// likely as one with a day left and 64x as likely as one with a week left.
/// Items still appear at random so the reels do not repeat every spin.
final class ExpiringFirstRollStrategy implements SlotRollStrategy {
  const ExpiringFirstRollStrategy();

  static double weightFor(int daysLeft) {
    final d = daysLeft < 0 ? 0 : daysLeft;
    return 1 / ((d + 1) * (d + 1));
  }

  @override
  List<IngredientItem> pick(
    List<IngredientItem> pool,
    int count,
    Random random,
    LocalDate today,
  ) {
    final remaining = [...pool];
    final picked = <IngredientItem>[];
    while (picked.length < count && remaining.isNotEmpty) {
      final weights = [
        for (final item in remaining) weightFor(item.daysUntilExpiry(today)),
      ];
      final total = weights.fold(0.0, (a, b) => a + b);
      var target = random.nextDouble() * total;
      var index = remaining.length - 1;
      for (var i = 0; i < weights.length; i++) {
        target -= weights[i];
        if (target < 0) {
          index = i;
          break;
        }
      }
      picked.add(remaining.removeAt(index));
    }
    return picked;
  }
}
