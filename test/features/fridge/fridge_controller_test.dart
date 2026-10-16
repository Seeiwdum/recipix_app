import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/features/fridge/data/ingredient_catalog.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/fridge/domain/fridge_layout.dart';
import 'package:recipix_app/features/fridge/domain/freshness.dart';
import 'package:recipix_core/recipix_core.dart';

final today = LocalDate(2026, 10, 16);

ProviderContainer makeContainer() {
  final catalog = IngredientCatalog.fromJsonString(
    File(IngredientCatalog.assetPath).readAsStringSync(),
  );
  final c = ProviderContainer(
    overrides: [
      catalogProvider.overrideWithValue(catalog),
      todayProvider.overrideWithValue(today),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog ships in the asset bundle', () async {
    // main() loads it through rootBundle, so it must be listed in pubspec.
    final json = await rootBundle.loadString(IngredientCatalog.assetPath);
    expect(IngredientCatalog.fromJsonString(json).entries, isNotEmpty);
  });

  test('catalog parses every entry with width 1 or 2', () {
    final catalog = IngredientCatalog.fromJsonString(
      File(IngredientCatalog.assetPath).readAsStringSync(),
    );
    expect(catalog.entries.length, greaterThanOrEqualTo(15));
    for (final e in catalog.entries) {
      expect([1, 2], contains(e.width), reason: e.key);
      expect(e.kcalPerUnit, greaterThan(0), reason: e.key);
    }
  });

  test('sample starts with placed items and a basket', () {
    final s = makeContainer().read(fridgeProvider);
    expect(s.placed, isNotEmpty);
    expect(s.basket.map((i) => i.key), contains('cabbage'));
    expect(s.items.where((i) => !i.isIdentified), hasLength(1));
  });

  test('placing from the basket sets the zone; full slot is refused', () {
    final c = makeContainer();
    final ctrl = c.read(fridgeProvider.notifier);
    final cabbage = c
        .read(fridgeProvider)
        .basket
        .firstWhere((i) => i.key == 'cabbage');

    // Shelf 1 col 0-1 holds the pork.
    expect(
      ctrl.place(cabbage.id, const Slot(CompartmentId.shelf1, 0)),
      isFalse,
    );
    expect(
      ctrl.place(cabbage.id, const Slot(CompartmentId.door, 0, 1)),
      isFalse,
    );
    expect(ctrl.place(cabbage.id, const Slot(CompartmentId.shelf3, 0)), isTrue);

    final s = c.read(fridgeProvider);
    expect(s.basket.any((i) => i.id == cabbage.id), isFalse);
    expect(s.byId(cabbage.id)!.zone, StorageZone.shelf);
  });

  test('use closes the gap and undo restores exactly', () {
    final c = makeContainer();
    final ctrl = c.read(fridgeProvider.notifier);
    final before = c.read(fridgeProvider);
    final basil = before.placed.firstWhere((i) => i.key == 'holy_basil');
    final chili = before.placed.firstWhere((i) => i.key == 'chili');

    ctrl.use(basil.id);
    var s = c.read(fridgeProvider);
    expect(s.byId(basil.id), isNull);
    expect(s.lastRemoval!.kind, RemovalKind.used);
    expect(s.arrangement.placements[chili.id]!.slot.col, 0);

    ctrl.undo();
    s = c.read(fridgeProvider);
    expect(s.arrangement.placements[basil.id]!.slot.col, 0);
    expect(s.arrangement.placements[chili.id]!.slot.col, 1);
    expect(s.lastRemoval, isNull);
  });

  test('undo after a later move falls back to the basket', () {
    final c = makeContainer();
    final ctrl = c.read(fridgeProvider.notifier);
    final basil = c
        .read(fridgeProvider)
        .placed
        .firstWhere((i) => i.key == 'holy_basil');
    ctrl.discard(basil.id);
    final lime = c
        .read(fridgeProvider)
        .basket
        .firstWhere((i) => i.key == 'lime');
    expect(ctrl.place(lime.id, const Slot(CompartmentId.crisper, 3)), isTrue);
    ctrl.undo();
    final s = c.read(fridgeProvider);
    expect(s.byId(basil.id), isNotNull);
    expect(s.arrangement.contains(basil.id), isFalse);
  });

  test('filters', () {
    final s = makeContainer().read(fridgeProvider);
    final rice = s.items.firstWhere((i) => i.key == 'rice'); // 0 days
    final shrimp = s.items.firstWhere((i) => i.key == 'shrimp');
    final mystery = s.items.firstWhere((i) => !i.isIdentified);
    expect(FridgeFilter.useSoon.matches(rice, today), isTrue);
    expect(FridgeFilter.useSoon.matches(shrimp, today), isFalse);
    expect(FridgeFilter.protein.matches(shrimp, today), isTrue);
    expect(FridgeFilter.unknown.matches(mystery, today), isTrue);
    expect(Freshness.of(rice, today), Freshness.urgent);
    final cucumber = s.items.firstWhere((i) => i.key == 'cucumber');
    expect(Freshness.of(cucumber, today), Freshness.expired);
  });
}
