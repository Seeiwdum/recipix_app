import 'dart:math';

import '../common/local_date.dart';
import '../entities/ingredient_item.dart';
import '../entities/recipe.dart';
import 'recipe_matcher.dart';
import 'slot_roll_strategy.dart';

/// Outcome of one spin. It is fully decided before any animation starts;
/// the UI only plays it back.
final class SlotSpinResult {
  SlotSpinResult({
    required List<IngredientItem?> reels,
    required this.bestMatch,
    required List<RecipeMatch> alternatives,
  }) : reels = List.unmodifiable(reels),
       alternatives = List.unmodifiable(alternatives);

  /// One entry per reel; `null` when the fridge had too few items.
  final List<IngredientItem?> reels;

  final RecipeMatch? bestMatch;

  /// Next-best matches, best first. Excludes [bestMatch].
  final List<RecipeMatch> alternatives;

  int get matchPercentage => bestMatch?.matchPercentage ?? 0;
  bool get isJackpot => bestMatch?.isJackpot ?? false;
}

/// Port of the Unity `IngredientSlotMachine`.
final class IngredientSlotMachine {
  IngredientSlotMachine({
    required this.strategy,
    required List<Recipe> recipes,
    Random? random,
    this.reelCount = 3,
    this.alternativeCount = 3,
    this.matcher = const RecipeMatcher(),
  }) : recipes = List.unmodifiable(recipes),
       _random = random ?? Random();

  final SlotRollStrategy strategy;
  final List<Recipe> recipes;
  final int reelCount;
  final int alternativeCount;
  final RecipeMatcher matcher;
  final Random _random;

  /// Spins the reels. [locked] maps reel index to an item the user pinned;
  /// those reels keep their item and the rest are rolled.
  SlotSpinResult spin({
    required List<IngredientItem> fridge,
    required LocalDate today,
    Map<int, IngredientItem> locked = const {},
  }) {
    final pool = usablePool(fridge, today);
    final lockedKeys = {for (final i in locked.values) i.key};
    final rollable = pool.where((i) => !lockedKeys.contains(i.key)).toList();

    final openReels = [
      for (var r = 0; r < reelCount; r++)
        if (!locked.containsKey(r)) r,
    ];
    final rolled = strategy.pick(rollable, openReels.length, _random, today);

    final reels = List<IngredientItem?>.filled(reelCount, null);
    locked.forEach((index, item) {
      if (index >= 0 && index < reelCount) reels[index] = item;
    });
    for (var i = 0; i < rolled.length; i++) {
      reels[openReels[i]] = rolled[i];
    }

    final focus = {for (final i in reels) ?i?.key};
    final available = {for (final i in pool) i.key!};
    final ranked = focus.isEmpty
        ? const <RecipeMatch>[]
        : matcher.rank(recipes, available, focusKeys: focus, weighFocus: true);

    return SlotSpinResult(
      reels: reels,
      bestMatch: ranked.isEmpty ? null : ranked.first,
      alternatives: ranked.skip(1).take(alternativeCount).toList(),
    );
  }

  /// Identified, unexpired items, one per key (the one expiring soonest).
  static List<IngredientItem> usablePool(
    List<IngredientItem> fridge,
    LocalDate today,
  ) {
    final byKey = <String, IngredientItem>{};
    for (final item in fridge) {
      final key = item.key;
      if (key == null || item.isExpired(today) || item.quantity.isEmpty) {
        continue;
      }
      final current = byKey[key];
      if (current == null || item.expiresOn.isBefore(current.expiresOn)) {
        byKey[key] = item;
      }
    }
    return byKey.values.toList();
  }
}
