import 'package:recipix_core/recipix_core.dart';

import '../domain/fridge_layout.dart';
import 'ingredient_catalog.dart';

/// Starting contents until persistence lands (Phase 3): a lived-in fridge
/// plus a basket of fresh shopping to put away.
({List<IngredientItem> items, FridgeArrangement arrangement}) sampleFridge(
  IngredientCatalog catalog,
  LocalDate today, {
  required String mysteryName,
}) {
  final items = <IngredientItem>[];
  var arrangement = FridgeArrangement();

  void add(String key, {int? daysLeft, Slot? at}) {
    final entry = catalog[key];
    if (entry == null) return;
    final item = entry.toItem(
      '$key-${items.length}',
      today,
      daysLeft: daysLeft,
    );
    items.add(item);
    if (at != null) {
      arrangement = arrangement.place(item.id, entry.width, at);
    }
  }

  // Already in the fridge.
  add('shrimp', at: const Slot(CompartmentId.freezer, 0));
  add(
    'frozen_dumpling',
    daysLeft: 60,
    at: const Slot(CompartmentId.freezer, 2),
  );
  add('pork', daysLeft: 1, at: const Slot(CompartmentId.shelf1, 0));
  add('tofu', daysLeft: 4, at: const Slot(CompartmentId.shelf1, 2));
  add('rice', daysLeft: 0, at: const Slot(CompartmentId.shelf2, 0));
  add('yogurt', daysLeft: 9, at: const Slot(CompartmentId.shelf2, 1));
  add('holy_basil', daysLeft: 2, at: const Slot(CompartmentId.crisper, 0));
  add('chili', daysLeft: 6, at: const Slot(CompartmentId.crisper, 1));
  add('cucumber', daysLeft: -1, at: const Slot(CompartmentId.crisper, 3));
  add('egg', daysLeft: 12, at: const Slot(CompartmentId.door, 0, 0));
  add('fish_sauce', at: const Slot(CompartmentId.door, 0, 2));

  // Leftover box nobody labelled: calories are only an estimate.
  final mystery = IngredientItem(
    id: 'mystery-${items.length}',
    name: mysteryName,
    key: null,
    quantity: const Quantity.pieces(1),
    kcalPerUnit: 300,
    expiresOn: today.addDays(1),
    zone: StorageZone.shelf,
  );
  items.add(mystery);
  arrangement = arrangement.place(
    mystery.id,
    1,
    const Slot(CompartmentId.shelf3, 3),
  );

  // Fresh shopping still in the basket.
  add('cabbage');
  add('tomato');
  add('milk');
  add('chicken_breast');
  add('lime');

  return (items: items, arrangement: arrangement);
}
