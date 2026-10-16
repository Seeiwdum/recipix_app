import '../common/local_date.dart';
import '../common/money.dart';
import '../entities/ingredient_item.dart';
import '../entities/recipe.dart';

/// Things the user did that badge rules can react to.
sealed class RecipixEvent {
  const RecipixEvent(this.date);

  final LocalDate date;
}

/// An item was eaten or used (not via a recipe).
final class ItemUsed extends RecipixEvent {
  const ItemUsed(super.date, {required this.item, required this.daysLeft});

  final IngredientItem item;
  final int daysLeft;

  bool get wasUrgent => daysLeft >= 0 && daysLeft <= urgentWindowDays;
}

final class ItemDiscarded extends RecipixEvent {
  const ItemDiscarded(super.date, {required this.item});

  final IngredientItem item;
}

final class RecipeCooked extends RecipixEvent {
  const RecipeCooked(
    super.date, {
    required this.recipe,
    required this.urgentItemsUsed,
  });

  final Recipe recipe;
  final int urgentItemsUsed;
}

final class ItemsScanned extends RecipixEvent {
  const ItemsScanned(super.date, {required this.count});

  final int count;
}

/// End-of-day summary, emitted once per calendar day.
final class DayClosed extends RecipixEvent {
  const DayClosed(
    super.date, {
    required this.spent,
    required this.allowance,
    required this.discardedCount,
  });

  final Money spent;
  final Money allowance;
  final int discardedCount;

  bool get withinAllowance => spent <= allowance;
}
