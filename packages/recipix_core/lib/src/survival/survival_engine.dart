import 'dart:math' as math;

import '../common/local_date.dart';
import '../common/money.dart';
import '../entities/ingredient_item.dart';
import '../entities/user_budget_profile.dart';

/// Snapshot of how long the user can last until payday.
///
/// Every number here comes from the rules in [SurvivalEngine]; the old
/// demo's blended "survival chance" score is intentionally not reproduced.
final class SurvivalReport {
  SurvivalReport({
    required this.today,
    required this.nextPayday,
    required this.daysUntilPayday,
    required this.confirmedKcal,
    required this.estimatedKcal,
    required this.survivalDays,
    required this.survivalDaysWithEstimate,
    required this.dailyAllowance,
    required this.uncoveredDays,
    required this.costToCoverUncovered,
    required this.budgetDeficit,
    required List<IngredientItem> urgentItems,
    required List<IngredientItem> expiredItems,
  }) : urgentItems = List.unmodifiable(urgentItems),
       expiredItems = List.unmodifiable(expiredItems);

  final LocalDate today;
  final LocalDate nextPayday;

  /// Days the budget must cover: today up to the day before payday.
  final int daysUntilPayday;

  /// Calories of identified, unexpired items.
  final double confirmedKcal;

  /// Calories of unidentified ("mystery") unexpired items. Shown apart
  /// because the type, and therefore the number, is a guess.
  final double estimatedKcal;

  /// [confirmedKcal] divided by the daily need.
  final double survivalDays;

  /// Same, but also counting [estimatedKcal]. Upper bound only.
  final double survivalDaysWithEstimate;

  final Money dailyAllowance;

  /// Days the fridge cannot feed, which have to be bought.
  final double uncoveredDays;

  /// Cost of eating out for [uncoveredDays].
  final Money costToCoverUncovered;

  /// How much more money is needed to reach payday. Zero when covered.
  final Money budgetDeficit;

  /// Unexpired items with at most [urgentWindowDays] days left, soonest first.
  final List<IngredientItem> urgentItems;

  final List<IngredientItem> expiredItems;

  bool get isCovered => budgetDeficit.isZero;
}

/// Pure survival rules (ported from the Unity `SurvivalEngine`).
///
/// * Total calories = sum over unexpired items.
/// * Survival days = total calories / daily need (2,000 kcal by default).
/// * Daily allowance = food budget / days until payday.
/// * Budget deficit: see ADR-002. Uncovered days are priced at the user's
///   eat-out cost; whatever the budget cannot pay is the deficit.
final class SurvivalEngine {
  const SurvivalEngine();

  SurvivalReport evaluate({
    required List<IngredientItem> items,
    required UserBudgetProfile profile,
    required LocalDate today,
  }) {
    var confirmedKcal = 0.0;
    var estimatedKcal = 0.0;
    final urgent = <IngredientItem>[];
    final expired = <IngredientItem>[];

    for (final item in items) {
      if (item.isExpired(today)) {
        expired.add(item);
        continue;
      }
      if (item.isIdentified) {
        confirmedKcal += item.totalKcal;
      } else {
        estimatedKcal += item.totalKcal;
      }
      if (item.isUrgent(today)) urgent.add(item);
    }
    urgent.sort((a, b) => a.expiresOn.compareTo(b.expiresOn));

    final payday = nextPayday(profile, today);
    final days = today.daysUntil(payday);
    final survivalDays = confirmedKcal / profile.dailyKcalNeed;
    final uncovered = math.max(0.0, days - survivalDays);
    final cost = profile.prices.dailyEatOutCost * uncovered;
    final deficit = Money.max(Money.zero, cost - profile.foodBudget);

    return SurvivalReport(
      today: today,
      nextPayday: payday,
      daysUntilPayday: days,
      confirmedKcal: confirmedKcal,
      estimatedKcal: estimatedKcal,
      survivalDays: survivalDays,
      survivalDaysWithEstimate:
          (confirmedKcal + estimatedKcal) / profile.dailyKcalNeed,
      dailyAllowance: profile.foodBudget.divideFloor(days),
      uncoveredDays: uncovered,
      costToCoverUncovered: cost,
      budgetDeficit: deficit,
      urgentItems: urgent,
      expiredItems: expired,
    );
  }

  /// Food budget divided by the days left until payday.
  Money dailyAllowance(UserBudgetProfile profile, LocalDate today) => profile
      .foodBudget
      .divideFloor(today.daysUntil(nextPayday(profile, today)));

  /// The first day new money arrives, strictly after [today].
  ///
  /// Without a payday the budget runs to the end of the month, so the
  /// "payday" is the 1st of next month. Always at least one day away.
  LocalDate nextPayday(UserBudgetProfile profile, LocalDate today) {
    final payday = profile.paydayDayOfMonth;
    if (payday == null) return LocalDate(today.year, today.month + 1, 1);

    final thisMonth = _clampedDay(today.year, today.month, payday);
    if (thisMonth.isAfter(today)) return thisMonth;
    return _clampedDay(today.year, today.month + 1, payday);
  }

  static LocalDate _clampedDay(int year, int month, int day) {
    final first = LocalDate(year, month, 1);
    return LocalDate(first.year, first.month, math.min(day, first.daysInMonth));
  }
}
