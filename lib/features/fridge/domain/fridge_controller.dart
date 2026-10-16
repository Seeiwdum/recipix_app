import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../shared/persistence/app_store.dart';
import '../../../shared/persistence/codecs.dart';
import '../data/sample_fridge.dart';
import 'fridge_layout.dart';
import 'freshness.dart';

enum RemovalKind { used, discarded }

/// Last item taken out, kept so the toast can offer "undo".
final class Removal {
  const Removal(
    this.item,
    this.placement,
    this.kind, {
    this.before,
    this.after,
  });

  final IngredientItem item;
  final Placement? placement;
  final RemovalKind kind;

  /// Arrangements around the removal, so undo can restore neighbours that
  /// slid into the gap.
  final FridgeArrangement? before;
  final FridgeArrangement? after;
}

/// A dish cooked from the fridge, kept for undo and for the plan's
/// "meals already eaten today".
final class CookRecord {
  const CookRecord({
    required this.recipe,
    required this.date,
    this.before,
    this.after,
  });

  final Recipe recipe;
  final LocalDate date;

  /// Undo snapshots; null for history restored from storage.
  final FridgeState? before;
  final FridgeState? after;
}

final class FridgeState {
  FridgeState({
    required List<IngredientItem> items,
    required this.arrangement,
    this.filter = FridgeFilter.all,
    this.lastRemoval,
    List<CookRecord> cooked = const [],
  }) : items = List.unmodifiable(items),
       cooked = List.unmodifiable(cooked);

  final List<IngredientItem> items;
  final FridgeArrangement arrangement;
  final FridgeFilter filter;
  final Removal? lastRemoval;

  /// Dishes cooked, oldest first.
  final List<CookRecord> cooked;

  int cookedOn(LocalDate day) => cooked.where((c) => c.date == day).length;

  List<IngredientItem> get placed =>
      items.where((i) => arrangement.contains(i.id)).toList();

  /// Items not yet put away, in arrival order.
  List<IngredientItem> get basket =>
      items.where((i) => !arrangement.contains(i.id)).toList();

  IngredientItem? byId(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  FridgeState copyWith({
    List<IngredientItem>? items,
    FridgeArrangement? arrangement,
    FridgeFilter? filter,
    Removal? lastRemoval,
    bool clearRemoval = false,
    List<CookRecord>? cooked,
  }) => FridgeState(
    items: items ?? this.items,
    arrangement: arrangement ?? this.arrangement,
    filter: filter ?? this.filter,
    lastRemoval: clearRemoval ? null : (lastRemoval ?? this.lastRemoval),
    cooked: cooked ?? this.cooked,
  );
}

final fridgeProvider = NotifierProvider<FridgeController, FridgeState>(
  FridgeController.new,
);

/// Presenter for the fridge tab (replaces the Unity MVP presenter).
class FridgeController extends Notifier<FridgeState> {
  /// Restores what was saved on the device, or seeds sample contents on
  /// first launch (ADR-009). Every later change is written back.
  @override
  FridgeState build() {
    final store = ref.watch(appStoreProvider);
    if (store != null) {
      listenSelf((_, next) => store.saveFridge(_toSaved(next)));
    }

    final saved = ref.watch(savedDataProvider).fridge;
    if (saved != null) {
      final recipes = {
        for (final r in ref.watch(recipeBookProvider).recipes) r.id: r,
      };
      return FridgeState(
        items: saved.items,
        arrangement: saved.arrangement,
        cooked: [
          for (final c in saved.cooked)
            if (recipes[c.recipeId] case final recipe?)
              CookRecord(recipe: recipe, date: c.date),
        ],
      );
    }
    final seed = sampleFridge(
      ref.watch(catalogProvider),
      ref.watch(todayProvider),
      mysteryName: S.mysteryItem,
    );
    final initial = FridgeState(
      items: seed.items,
      arrangement: seed.arrangement,
    );
    // Save the seed right away so its dates stay fixed on the next launch.
    store?.saveFridge(_toSaved(initial));
    return initial;
  }

  static SavedFridge _toSaved(FridgeState s) => SavedFridge(
    items: s.items,
    arrangement: s.arrangement,
    cooked: [for (final c in s.cooked) (recipeId: c.recipe.id, date: c.date)],
  );

  int widthOf(IngredientItem item) => ref.read(catalogProvider).widthOf(item);

  bool canPlace(String itemId, Slot slot) {
    final item = state.byId(itemId);
    if (item == null) return false;
    return state.arrangement.canPlace(itemId, widthOf(item), slot);
  }

  /// Puts an item at [slot]. Returns false (and changes nothing) when it
  /// does not fit, so the UI can bounce the item back.
  bool place(String itemId, Slot slot) {
    if (!canPlace(itemId, slot)) return false;
    final item = state.byId(itemId)!;
    final next = state.arrangement.place(itemId, widthOf(item), slot);
    final zone = FridgeLayout.of(slot.compartment).zone;
    state = state.copyWith(
      arrangement: next,
      items: [
        for (final i in state.items)
          i.id == itemId ? i.copyWith(zone: zone) : i,
      ],
    );
    return true;
  }

  /// Puts a basket item in the first free slot, trying its usual zone
  /// first. Returns the slot, or null when the fridge is full. This is the
  /// non-drag path (and the accessible one).
  Slot? autoPlace(String itemId) {
    final item = state.byId(itemId);
    if (item == null) return null;
    final slot = state.arrangement.firstFree(
      itemId,
      widthOf(item),
      preferred: item.zone,
    );
    if (slot == null || !place(itemId, slot)) return null;
    return slot;
  }

  void moveToBasket(String itemId) {
    if (!state.arrangement.contains(itemId)) return;
    state = state.copyWith(arrangement: state.arrangement.remove(itemId));
  }

  void use(String itemId) => _remove(itemId, RemovalKind.used);

  void discard(String itemId) => _remove(itemId, RemovalKind.discarded);

  void _remove(String itemId, RemovalKind kind) {
    final item = state.byId(itemId);
    if (item == null) return;
    final placement = state.arrangement.placements[itemId];
    var next = state.arrangement.remove(itemId);
    if (placement != null) next = next.closeGap(placement);
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
      arrangement: next,
      lastRemoval: Removal(
        item,
        placement,
        kind,
        before: state.arrangement,
        after: next,
      ),
    );
  }

  /// Restores the last removed item: back to its old slot if that is still
  /// free, otherwise into the basket.
  void undo() {
    final removal = state.lastRemoval;
    if (removal == null) return;
    final item = removal.item;
    var next = state.arrangement;
    final p = removal.placement;
    if (identical(next, removal.after) && removal.before != null) {
      next = removal.before!;
    } else if (p != null && next.canPlace(item.id, p.width, p.slot)) {
      next = next.place(item.id, p.width, p.slot);
    }
    state = state.copyWith(
      items: [...state.items, item],
      arrangement: next,
      clearRemoval: true,
    );
  }

  /// Cooks one batch of [recipe] now: amounts come off the fridge by
  /// quantity, first-expiring first (recipix_core `InventoryService`).
  /// Items used up leave their shelf. Returns null and changes nothing
  /// when something required is missing.
  CookResult? cook(Recipe recipe) {
    final today = ref.read(todayProvider);
    final result = const InventoryService().cook(
      state.items,
      recipe,
      today: today,
    );
    if (!result.isComplete) return null;
    final left = {for (final i in result.remaining) i.id};
    var arrangement = state.arrangement;
    for (final id in arrangement.placements.keys) {
      if (!left.contains(id)) arrangement = arrangement.remove(id);
    }
    final before = state;
    final after = state.copyWith(
      items: result.remaining,
      arrangement: arrangement,
    );
    state = after.copyWith(
      cooked: [
        ...after.cooked,
        CookRecord(recipe: recipe, date: today, before: before, after: after),
      ],
    );
    return result;
  }

  /// Item lists are re-wrapped on every copy, so compare the items
  /// themselves (immutable, replaced on any change) one by one.
  static bool _sameItems(List<IngredientItem> a, List<IngredientItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  /// Undoes the last cook if nothing changed since.
  void undoCook() {
    if (state.cooked.isEmpty) return;
    final last = state.cooked.last;
    final before = last.before;
    final after = last.after;
    if (before == null || after == null) return;
    if (!_sameItems(state.items, after.items)) return;
    state = before.copyWith(
      filter: state.filter,
      cooked: state.cooked.sublist(0, state.cooked.length - 1),
    );
  }

  void setFilter(FridgeFilter filter) => state = state.copyWith(filter: filter);
}
