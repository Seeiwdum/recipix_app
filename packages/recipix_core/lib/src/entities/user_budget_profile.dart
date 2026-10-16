import '../common/money.dart';

/// Prices the user can edit. These replace numbers that the old HTML demo
/// hard-coded into its screens (e.g. a 60-baht made-to-order meal).
final class PriceSettings {
  const PriceSettings({
    this.mealOutPrice = const Money.satang(6000),
    this.mealsPerDay = 3,
  });

  /// Typical cost of one meal bought outside.
  final Money mealOutPrice;
  final int mealsPerDay;

  Money get dailyEatOutCost => mealOutPrice * mealsPerDay;

  PriceSettings copyWith({Money? mealOutPrice, int? mealsPerDay}) =>
      PriceSettings(
        mealOutPrice: mealOutPrice ?? this.mealOutPrice,
        mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      );
}

final class UserBudgetProfile {
  const UserBudgetProfile({
    required this.foodBudget,
    this.paydayDayOfMonth,
    this.dailyKcalNeed = defaultDailyKcalNeed,
    this.prices = const PriceSettings(),
  });

  static const double defaultDailyKcalNeed = 2000;

  /// Money left for food until the next payday.
  final Money foodBudget;

  /// Day of month salary arrives (1-31). `null` means the budget must last
  /// to the end of the month. Days past the month's length clamp to its
  /// last day.
  final int? paydayDayOfMonth;

  final double dailyKcalNeed;
  final PriceSettings prices;

  UserBudgetProfile copyWith({
    Money? foodBudget,
    int? paydayDayOfMonth,
    bool clearPayday = false,
    double? dailyKcalNeed,
    PriceSettings? prices,
  }) => UserBudgetProfile(
    foodBudget: foodBudget ?? this.foodBudget,
    paydayDayOfMonth: clearPayday
        ? null
        : (paydayDayOfMonth ?? this.paydayDayOfMonth),
    dailyKcalNeed: dailyKcalNeed ?? this.dailyKcalNeed,
    prices: prices ?? this.prices,
  );
}
