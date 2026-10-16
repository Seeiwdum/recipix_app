import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/features/budget/domain/budget_controller.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/fridge/domain/fridge_layout.dart';
import 'package:recipix_app/shared/persistence/app_store.dart';
import 'package:recipix_app/shared/persistence/codecs.dart';
import 'package:recipix_core/recipix_core.dart';

import 'helpers.dart';

/// Simulates one app launch: load from [kv], build providers.
Future<ProviderContainer> launch(MemoryStore kv, {LocalDate? today}) async {
  final store = AppStore(kv, clock: () => DateTime.utc(2026, 10, 16, 9));
  final saved = await store.load();
  final c = ProviderContainer(
    overrides: [
      catalogProvider.overrideWithValue(testCatalog),
      recipeBookProvider.overrideWithValue(testRecipes),
      todayProvider.overrideWithValue(today ?? testToday),
      appStoreProvider.overrideWithValue(store),
      savedDataProvider.overrideWithValue(saved),
    ],
  );
  addTearDown(c.dispose);
  // Build both controllers like the app does on first frame.
  c.read(fridgeProvider);
  c.read(budgetProvider);
  return c;
}

Future<void> settle(ProviderContainer c) => c.read(appStoreProvider)!.flush();

void main() {
  test('codecs round-trip items, placements and spending', () {
    final c = ProviderContainer(
      overrides: [
        catalogProvider.overrideWithValue(testCatalog),
        recipeBookProvider.overrideWithValue(testRecipes),
        todayProvider.overrideWithValue(testToday),
      ],
    );
    addTearDown(c.dispose);
    final fridge = c.read(fridgeProvider);
    final saved = SavedFridge(
      items: fridge.items,
      arrangement: fridge.arrangement,
      cooked: [(recipeId: 'khai_jiao', date: testToday, urgentItemsUsed: 2)],
    );
    final back = SavedFridge.fromJson(
      jsonDecode(jsonEncode(saved.toJson())) as Map<String, Object?>,
    );
    expect(back.items.length, fridge.items.length);
    for (var i = 0; i < back.items.length; i++) {
      final a = fridge.items[i];
      final b = back.items[i];
      expect(
        [b.id, b.name, b.key, b.quantity, b.kcalPerUnit, b.expiresOn],
        [a.id, a.name, a.key, a.quantity, a.kcalPerUnit, a.expiresOn],
      );
      expect([b.category, b.zone], [a.category, a.zone]);
    }
    expect(back.arrangement.usedCells, fridge.arrangement.usedCells);
    for (final e in fridge.arrangement.placements.entries) {
      expect(back.arrangement.placements[e.key]!.slot, e.value.slot);
    }
    expect(back.cooked.single.recipeId, 'khai_jiao');

    final budget = c.read(budgetProvider);
    final b = SavedBudget(
      periodBudget: budget.periodBudget,
      paydayDayOfMonth: 25,
      prices: const PriceSettings(),
      quickAmounts: budget.quickAmounts,
      entries: budget.entries,
    );
    final bb = SavedBudget.fromJson(
      jsonDecode(jsonEncode(b.toJson())) as Map<String, Object?>,
    );
    expect(bb.periodBudget, budget.periodBudget);
    expect(bb.paydayDayOfMonth, 25);
    expect(
      bb.entries.map((e) => e.amount),
      budget.entries.map((e) => e.amount),
    );
  });

  test('placements that no longer fit fall back to the basket', () {
    final a = Codecs.arrangementFrom(
      {
        'x': {'compartment': 'shelf1', 'col': 0, 'row': 0, 'width': 2},
        'y': {'compartment': 'shelf1', 'col': 1, 'row': 0, 'width': 1},
        'gone': {'compartment': 'shelf2', 'col': 0, 'row': 0, 'width': 1},
      },
      {'x', 'y'},
    );
    expect(a.contains('x'), isTrue);
    expect(a.contains('y'), isFalse);
    expect(a.contains('gone'), isFalse);
  });

  test('first launch seeds and saves sample data', () async {
    final kv = MemoryStore();
    final c = await launch(kv);
    await settle(c);
    expect(
      kv.values.keys,
      containsAll([AppStore.fridgeKey, AppStore.budgetKey]),
    );
    expect(c.read(fridgeProvider).items, isNotEmpty);
  });

  test('changes survive a relaunch, even on a later day', () async {
    final kv = MemoryStore();
    var c = await launch(kv);
    final fridge = c.read(fridgeProvider.notifier);
    final cabbage = c
        .read(fridgeProvider)
        .basket
        .firstWhere((i) => i.key == 'cabbage');
    final basil = c
        .read(fridgeProvider)
        .items
        .firstWhere((i) => i.key == 'holy_basil');
    expect(
      fridge.place(cabbage.id, const Slot(CompartmentId.shelf3, 0)),
      isTrue,
    );
    fridge.use(basil.id);
    final soup = testRecipes.recipes.firstWhere(
      (r) => r.id == 'kaeng_jued_tofu',
    );
    expect(fridge.cook(soup), isNotNull);
    c.read(budgetProvider.notifier).add(Money.baht(60), SpendCategory.eatOut);
    final itemsBefore = c.read(fridgeProvider).items.length;
    await settle(c);

    // Next morning: same data, not a fresh sample.
    c = await launch(kv, today: testToday.addDays(1));
    final s = c.read(fridgeProvider);
    expect(s.items.length, itemsBefore);
    expect(s.byId(basil.id), isNull);
    expect(
      s.arrangement.placements[cabbage.id]!.slot,
      const Slot(CompartmentId.shelf3, 0),
    );
    expect(s.items.firstWhere((i) => i.key == 'tofu').quantity.amount, 1);
    expect(s.cooked.single.recipe.id, 'kaeng_jued_tofu');
    expect(s.cooked.single.date, testToday);
    expect(s.cooked.single.urgentItemsUsed, greaterThan(0));
    expect(s.activity.single.kind, RemovalKind.used);
    expect(s.activity.single.itemId, basil.id);
    expect(s.trackingSince, testToday);
    final spent = c
        .read(budgetProvider)
        .entries
        .where((e) => e.date == testToday && e.amount == Money.baht(60));
    expect(spent, hasLength(1));
    // Sample dates did not move with the new day.
    final rice = s.items.firstWhere((i) => i.key == 'rice');
    expect(rice.expiresOn, testToday);
  });

  test('restored cook history cannot be undone (no snapshot)', () async {
    final kv = MemoryStore();
    var c = await launch(kv);
    final soup = testRecipes.recipes.firstWhere(
      (r) => r.id == 'kaeng_jued_tofu',
    );
    c.read(fridgeProvider.notifier).cook(soup);
    await settle(c);
    c = await launch(kv);
    c.read(fridgeProvider.notifier).undoCook();
    expect(c.read(fridgeProvider).cooked, hasLength(1));
  });

  test('corrupt data is backed up, never silently lost', () async {
    final kv = MemoryStore()
      ..values[AppStore.fridgeKey] = '{"v": 1, "items": [{"broken": true}]}'
      ..values[AppStore.budgetKey] = 'not json';
    final c = await launch(kv);
    await settle(c);

    final backups = kv.values.keys.where((k) => k.contains('.corrupt.'));
    expect(backups, hasLength(2));
    expect(
      kv.values['${AppStore.budgetKey}.corrupt.${DateTime.utc(2026, 10, 16, 9).millisecondsSinceEpoch}'],
      'not json',
    );
    // App still starts, with sample data.
    expect(c.read(fridgeProvider).items, isNotEmpty);
  });

  test('unknown schema version is treated as unreadable', () async {
    final kv = MemoryStore()
      ..values[AppStore.budgetKey] = jsonEncode({'v': 99});
    await launch(kv);
    expect(kv.values.keys.any((k) => k.contains('.corrupt.')), isTrue);
  });

  test('a burst of changes is written once', () async {
    final writes = <String>[];
    final kv = _CountingStore(writes);
    final store = AppStore(kv);
    for (var i = 0; i < 20; i++) {
      store.saveBudget(
        SavedBudget(
          periodBudget: Money.baht(i),
          paydayDayOfMonth: null,
          prices: const PriceSettings(),
          quickAmounts: const [],
          entries: const [],
        ),
      );
    }
    await store.flush();
    expect(writes, [AppStore.budgetKey]);
    final saved = SavedBudget.fromJson(
      jsonDecode(kv.values[AppStore.budgetKey]!) as Map<String, Object?>,
    );
    expect(saved.periodBudget, Money.baht(19));
  });
}

final class _CountingStore extends MemoryStore {
  _CountingStore(this.writes);

  final List<String> writes;

  @override
  Future<void> write(String key, String value) {
    writes.add(key);
    return super.write(key, value);
  }
}
