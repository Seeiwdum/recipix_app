import 'dart:convert';

import 'package:recipix_core/recipix_core.dart';

/// One known ingredient type from `assets/data/ingredients.json`.
final class CatalogEntry {
  const CatalogEntry({
    required this.key,
    required this.name,
    required this.category,
    required this.unit,
    required this.defaultAmount,
    required this.kcalPerUnit,
    required this.shelfLifeDays,
    required this.zone,
    required this.width,
  });

  factory CatalogEntry.fromJson(Map<String, Object?> json) => CatalogEntry(
    key: json['key']! as String,
    name: json['name']! as String,
    category: IngredientCategory.values.byName(json['category']! as String),
    unit: QuantityUnit.values.byName(json['unit']! as String),
    defaultAmount: (json['defaultAmount']! as num).toDouble(),
    kcalPerUnit: (json['kcalPerUnit']! as num).toDouble(),
    shelfLifeDays: json['shelfLifeDays']! as int,
    zone: StorageZone.values.byName(json['zone']! as String),
    width: json['width']! as int,
  );

  final String key;
  final String name;
  final IngredientCategory category;
  final QuantityUnit unit;
  final double defaultAmount;
  final double kcalPerUnit;
  final int shelfLifeDays;
  final StorageZone zone;

  /// Cells the item takes on a shelf: 1 or 2.
  final int width;

  /// A fresh item bought on [today] with the default amount.
  IngredientItem toItem(String id, LocalDate today, {int? daysLeft}) =>
      IngredientItem(
        id: id,
        name: name,
        key: key,
        quantity: Quantity(defaultAmount, unit),
        kcalPerUnit: kcalPerUnit,
        expiresOn: today.addDays(daysLeft ?? shelfLifeDays),
        category: category,
        zone: zone,
        addedOn: today,
      );
}

final class IngredientCatalog {
  IngredientCatalog(Iterable<CatalogEntry> entries)
    : _byKey = {for (final e in entries) e.key: e};

  factory IngredientCatalog.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    final list = (json['ingredients']! as List<Object?>)
        .cast<Map<String, Object?>>();
    return IngredientCatalog(list.map(CatalogEntry.fromJson));
  }

  static const assetPath = 'assets/data/ingredients.json';

  final Map<String, CatalogEntry> _byKey;

  Iterable<CatalogEntry> get entries => _byKey.values;

  CatalogEntry? operator [](String key) => _byKey[key];

  /// Shelf width for [item]; unknown and mystery items take one cell.
  int widthOf(IngredientItem item) {
    final key = item.key;
    return key == null ? 1 : (_byKey[key]?.width ?? 1);
  }
}
