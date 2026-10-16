import 'package:recipix_core/recipix_core.dart';

import '../../features/fridge/domain/fridge_controller.dart';
import '../../features/fridge/domain/fridge_layout.dart';

/// JSON shapes for saved data (ADR-009). Money is whole satang, dates are
/// `YYYY-MM-DD`, enums are names. Bump [schemaVersion] and add a migration
/// when a shape changes.
abstract final class Codecs {
  static const schemaVersion = 1;

  // Ingredient items ---------------------------------------------------------

  static Map<String, Object?> item(IngredientItem i) => {
    'id': i.id,
    'name': i.name,
    'key': i.key,
    'amount': i.quantity.amount,
    'unit': i.quantity.unit.name,
    'kcalPerUnit': i.kcalPerUnit,
    'expiresOn': i.expiresOn.toString(),
    'category': i.category.name,
    'zone': i.zone.name,
    'price': i.price?.satang,
    'addedOn': i.addedOn?.toString(),
  };

  static IngredientItem itemFrom(Map<String, Object?> j) => IngredientItem(
    id: j['id']! as String,
    name: j['name']! as String,
    key: j['key'] as String?,
    quantity: Quantity(
      (j['amount']! as num).toDouble(),
      QuantityUnit.values.byName(j['unit']! as String),
    ),
    kcalPerUnit: (j['kcalPerUnit']! as num).toDouble(),
    expiresOn: LocalDate.parse(j['expiresOn']! as String),
    category: IngredientCategory.values.byName(j['category']! as String),
    zone: StorageZone.values.byName(j['zone']! as String),
    price: j['price'] == null ? null : Money.satang(j['price']! as int),
    addedOn: j['addedOn'] == null
        ? null
        : LocalDate.parse(j['addedOn']! as String),
  );

  // Fridge arrangement -------------------------------------------------------

  static Map<String, Object?> arrangement(FridgeArrangement a) => {
    for (final e in a.placements.entries)
      e.key: {
        'compartment': e.value.slot.compartment.name,
        'col': e.value.slot.col,
        'row': e.value.slot.row,
        'width': e.value.width,
      },
  };

  /// Placements that no longer fit (layout changed, overlap) are dropped so
  /// those items land in the basket instead of corrupting the grid.
  static FridgeArrangement arrangementFrom(
    Map<String, Object?> j,
    Set<String> itemIds,
  ) {
    var a = FridgeArrangement();
    for (final e in j.entries) {
      if (!itemIds.contains(e.key)) continue;
      final p = e.value! as Map<String, Object?>;
      final slot = Slot(
        CompartmentId.values.byName(p['compartment']! as String),
        p['col']! as int,
        p['row']! as int,
      );
      final width = p['width']! as int;
      if (a.canPlace(e.key, width, slot)) a = a.place(e.key, width, slot);
    }
    return a;
  }

  // Spending -----------------------------------------------------------------

  static Map<String, Object?> spending(SpendingEntry e) => {
    'id': e.id,
    'date': e.date.toString(),
    'amount': e.amount.satang,
    'category': e.category.name,
  };

  static SpendingEntry spendingFrom(Map<String, Object?> j) => SpendingEntry(
    id: j['id']! as String,
    date: LocalDate.parse(j['date']! as String),
    amount: Money.satang(j['amount']! as int),
    category: SpendCategory.values.byName(j['category']! as String),
  );

  static Map<String, Object?> prices(PriceSettings p) => {
    'mealOutPrice': p.mealOutPrice.satang,
    'mealsPerDay': p.mealsPerDay,
  };

  static PriceSettings pricesFrom(Map<String, Object?> j) => PriceSettings(
    mealOutPrice: Money.satang(j['mealOutPrice']! as int),
    mealsPerDay: j['mealsPerDay']! as int,
  );
}

/// What the fridge section stores. Cook history keeps only what later
/// features need (which dish, which day), not undo snapshots.
final class SavedFridge {
  SavedFridge({
    required this.items,
    required this.arrangement,
    required this.cooked,
    this.activity = const [],
    this.trackingSince,
  });

  /// Missing in saves made before this field existed.
  final LocalDate? trackingSince;

  final List<IngredientItem> items;
  final FridgeArrangement arrangement;
  final List<({String recipeId, LocalDate date, int urgentItemsUsed})> cooked;

  /// Items used or thrown away (for badges). Missing in older saves.
  final List<ActivityEntry> activity;

  Map<String, Object?> toJson() => {
    'v': Codecs.schemaVersion,
    'items': [for (final i in items) Codecs.item(i)],
    'placements': Codecs.arrangement(arrangement),
    'cooked': [
      for (final c in cooked)
        {
          'recipe': c.recipeId,
          'date': c.date.toString(),
          'urgent': c.urgentItemsUsed,
        },
    ],
    'since': trackingSince?.toString(),
    'activity': [
      for (final a in activity)
        {
          'kind': a.kind.name,
          'date': a.date.toString(),
          'item': a.itemId,
          'daysLeft': a.daysLeft,
        },
    ],
  };

  factory SavedFridge.fromJson(Map<String, Object?> j) {
    _checkVersion(j);
    final items = [
      for (final i
          in (j['items']! as List<Object?>).cast<Map<String, Object?>>())
        Codecs.itemFrom(i),
    ];
    return SavedFridge(
      items: items,
      arrangement: Codecs.arrangementFrom(
        j['placements']! as Map<String, Object?>,
        {for (final i in items) i.id},
      ),
      cooked: [
        for (final c
            in (j['cooked'] as List<Object?>? ?? const [])
                .cast<Map<String, Object?>>())
          (
            recipeId: c['recipe']! as String,
            date: LocalDate.parse(c['date']! as String),
            urgentItemsUsed: c['urgent'] as int? ?? 0,
          ),
      ],
      trackingSince: j['since'] == null
          ? null
          : LocalDate.parse(j['since']! as String),
      activity: [
        for (final a
            in (j['activity'] as List<Object?>? ?? const [])
                .cast<Map<String, Object?>>())
          ActivityEntry(
            kind: RemovalKind.values.byName(a['kind']! as String),
            date: LocalDate.parse(a['date']! as String),
            itemId: a['item']! as String,
            daysLeft: a['daysLeft']! as int,
          ),
      ],
    );
  }
}

final class SavedBudget {
  SavedBudget({
    required this.periodBudget,
    required this.paydayDayOfMonth,
    required this.prices,
    required this.quickAmounts,
    required this.entries,
  });

  final Money periodBudget;
  final int? paydayDayOfMonth;
  final PriceSettings prices;
  final List<Money> quickAmounts;
  final List<SpendingEntry> entries;

  Map<String, Object?> toJson() => {
    'v': Codecs.schemaVersion,
    'periodBudget': periodBudget.satang,
    'payday': paydayDayOfMonth,
    'prices': Codecs.prices(prices),
    'quickAmounts': [for (final m in quickAmounts) m.satang],
    'entries': [for (final e in entries) Codecs.spending(e)],
  };

  factory SavedBudget.fromJson(Map<String, Object?> j) {
    _checkVersion(j);
    return SavedBudget(
      periodBudget: Money.satang(j['periodBudget']! as int),
      paydayDayOfMonth: j['payday'] as int?,
      prices: Codecs.pricesFrom(j['prices']! as Map<String, Object?>),
      quickAmounts: [
        for (final s in (j['quickAmounts']! as List<Object?>).cast<int>())
          Money.satang(s),
      ],
      entries: [
        for (final e
            in (j['entries']! as List<Object?>).cast<Map<String, Object?>>())
          Codecs.spendingFrom(e),
      ],
    );
  }
}

void _checkVersion(Map<String, Object?> j) {
  final v = j['v'];
  if (v != Codecs.schemaVersion) {
    throw FormatException('Unsupported schema version: $v');
  }
}
