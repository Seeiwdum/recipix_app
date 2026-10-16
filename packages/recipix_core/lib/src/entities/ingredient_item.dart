import '../common/local_date.dart';
import '../common/money.dart';
import '../common/quantity.dart';

enum IngredientCategory {
  vegetable,
  fruit,
  meat,
  seafood,
  eggDairy,
  grain,
  condiment,
  readyMeal,
  drink,
  other,
}

/// Coarse storage area. Exact grid placement in the fridge view belongs to
/// the app layer, not to business rules.
enum StorageZone { shelf, crisper, freezer, door }

/// Default for "expiring soon": items with 0, 1 or 2 days left.
const int urgentWindowDays = 2;

/// One physical item in the user's fridge.
final class IngredientItem {
  const IngredientItem({
    required this.id,
    required this.name,
    required this.key,
    required this.quantity,
    required this.kcalPerUnit,
    required this.expiresOn,
    this.category = IngredientCategory.other,
    this.zone = StorageZone.shelf,
    this.price,
    this.addedOn,
  });

  final String id;

  /// Display name as the user sees it.
  final String name;

  /// Canonical ingredient key used for recipe matching (e.g. `egg`).
  /// `null` means the item has not been identified yet (a "mystery" item):
  /// its calories are only an estimate and it never matches recipes.
  final String? key;

  final Quantity quantity;

  /// Calories per one [quantity.unit]. For mystery items this is an estimate.
  final double kcalPerUnit;

  /// Last day the item is still fine to eat.
  final LocalDate expiresOn;

  final IngredientCategory category;
  final StorageZone zone;
  final Money? price;
  final LocalDate? addedOn;

  bool get isIdentified => key != null;

  double get totalKcal => quantity.amount * kcalPerUnit;

  /// 0 = last day today, negative = already expired.
  int daysUntilExpiry(LocalDate today) => today.daysUntil(expiresOn);

  bool isExpired(LocalDate today) => daysUntilExpiry(today) < 0;

  bool isUrgent(LocalDate today, {int windowDays = urgentWindowDays}) {
    final days = daysUntilExpiry(today);
    return days >= 0 && days <= windowDays;
  }

  IngredientItem copyWith({
    String? name,
    String? key,
    bool clearKey = false,
    Quantity? quantity,
    double? kcalPerUnit,
    LocalDate? expiresOn,
    IngredientCategory? category,
    StorageZone? zone,
    Money? price,
  }) => IngredientItem(
    id: id,
    name: name ?? this.name,
    key: clearKey ? null : (key ?? this.key),
    quantity: quantity ?? this.quantity,
    kcalPerUnit: kcalPerUnit ?? this.kcalPerUnit,
    expiresOn: expiresOn ?? this.expiresOn,
    category: category ?? this.category,
    zone: zone ?? this.zone,
    price: price ?? this.price,
    addedOn: addedOn,
  );

  @override
  String toString() => 'IngredientItem($id, $name, $quantity, exp $expiresOn)';
}
