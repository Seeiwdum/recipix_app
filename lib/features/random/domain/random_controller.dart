import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../budget/domain/budget_controller.dart';
import '../../fridge/domain/fridge_controller.dart';
import '../data/eat_out_menu.dart';

enum RandomMode { cook, eatOut }

/// Loaded in `main()` like the recipe book.
final eatOutMenuProvider = Provider<EatOutMenu>(
  (ref) => throw UnimplementedError('eatOutMenuProvider must be overridden'),
);

/// Injected so tests get repeatable spins.
final randomSourceProvider = Provider<Random>((ref) => Random());

const int reelCount = 3;

final class RandomState {
  RandomState({
    this.mode = RandomMode.cook,
    List<IngredientItem?>? reels,
    Set<int> locked = const {},
    this.result,
    this.dish,
    this.overBudget = false,
    this.expiringFirst = true,
    this.spins = 0,
  }) : reels = List.unmodifiable(
         reels ?? List<IngredientItem?>.filled(reelCount, null),
       ),
       locked = Set.unmodifiable(locked);

  final RandomMode mode;
  final List<IngredientItem?> reels;

  /// Reel indexes the user pinned; they keep their item on the next spin.
  final Set<int> locked;

  /// Last cook-mode spin, decided before any animation (spec 3.1).
  final SlotSpinResult? result;

  /// Last eat-out pick.
  final EatOutDish? dish;

  /// Nothing affordable within what is left today; [dish] is the cheapest.
  final bool overBudget;

  /// Expiring-first strategy (default) or pure random.
  final bool expiringFirst;

  /// Bumped on every spin so the UI knows to play the animation.
  final int spins;

  RandomState copyWith({
    RandomMode? mode,
    List<IngredientItem?>? reels,
    Set<int>? locked,
    SlotSpinResult? result,
    EatOutDish? dish,
    bool? overBudget,
    bool? expiringFirst,
    int? spins,
  }) => RandomState(
    mode: mode ?? this.mode,
    reels: reels ?? this.reels,
    locked: locked ?? this.locked,
    result: result ?? this.result,
    dish: dish ?? this.dish,
    overBudget: overBudget ?? this.overBudget,
    expiringFirst: expiringFirst ?? this.expiringFirst,
    spins: spins ?? this.spins,
  );
}

final randomProvider = NotifierProvider<RandomController, RandomState>(
  RandomController.new,
);

class RandomController extends Notifier<RandomState> {
  @override
  RandomState build() => RandomState();

  void setMode(RandomMode mode) => state = state.copyWith(mode: mode);

  void setExpiringFirst(bool value) =>
      state = state.copyWith(expiringFirst: value);

  void toggleLock(int reel) {
    if (state.reels[reel] == null) return;
    final locked = {...state.locked};
    if (!locked.remove(reel)) locked.add(reel);
    state = state.copyWith(locked: locked);
  }

  /// Spins the ingredient reels through recipix_core. Locked reels keep
  /// their item, refreshed from the fridge; a locked item that has since
  /// been used up loses its lock.
  SlotSpinResult spinCook() {
    final items = ref.read(fridgeProvider).items;
    final byId = {for (final i in items) i.id: i};
    final locked = <int, IngredientItem>{};
    for (final r in state.locked) {
      final item = byId[state.reels[r]?.id];
      if (item != null) locked[r] = item;
    }
    final machine = IngredientSlotMachine(
      strategy: state.expiringFirst
          ? const ExpiringFirstRollStrategy()
          : const PureRandomRollStrategy(),
      recipes: ref.read(recipeBookProvider).recipes,
      random: ref.read(randomSourceProvider),
      reelCount: reelCount,
    );
    final result = machine.spin(
      fridge: items,
      today: ref.read(todayProvider),
      locked: locked,
    );
    state = state.copyWith(
      reels: result.reels,
      locked: locked.keys.toSet(),
      result: result,
      spins: state.spins + 1,
    );
    return result;
  }

  /// Picks one dish to buy that fits what is left of today's budget.
  EatOutDish? spinEatOut() {
    final pick = pickEatOut(
      ref.read(eatOutMenuProvider).dishes,
      limit: ref.read(ledgerProvider).leftToday,
      random: ref.read(randomSourceProvider),
      avoidId: state.dish?.id,
    );
    if (pick == null) return null;
    state = state.copyWith(
      dish: pick.dish,
      overBudget: pick.overBudget,
      spins: state.spins + 1,
    );
    return pick.dish;
  }
}

/// A random dish priced within [limit]. When nothing fits, the cheapest
/// dishes are offered instead and [overBudget] is true. Avoids repeating
/// [avoidId] when there is a choice.
({EatOutDish dish, bool overBudget})? pickEatOut(
  List<EatOutDish> dishes, {
  required Money limit,
  required Random random,
  String? avoidId,
}) {
  if (dishes.isEmpty) return null;
  var pool = dishes.where((d) => d.price <= limit).toList();
  final over = pool.isEmpty;
  if (over) {
    final cheapest = dishes.map((d) => d.price).reduce(Money.min);
    pool = dishes.where((d) => d.price == cheapest).toList();
  }
  if (pool.length > 1) pool.removeWhere((d) => d.id == avoidId);
  return (dish: pool[random.nextInt(pool.length)], overBudget: over);
}
