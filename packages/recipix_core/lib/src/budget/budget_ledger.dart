import 'dart:math' as math;

import '../common/local_date.dart';
import '../common/money.dart';
import '../survival/survival_engine.dart';
import '../entities/user_budget_profile.dart';

enum SpendCategory {
  /// A meal bought outside. Also counts as one meal eaten that day.
  eatOut,

  /// Shopping for the fridge.
  groceries,
  other,
}

final class SpendingEntry {
  const SpendingEntry({
    required this.id,
    required this.date,
    required this.amount,
    this.category = SpendCategory.eatOut,
  });

  final String id;
  final LocalDate date;
  final Money amount;
  final SpendCategory category;
}

/// Where the money stands today within the current pay period.
final class LedgerSummary {
  const LedgerSummary({
    required this.periodStart,
    required this.nextPayday,
    required this.daysUntilPayday,
    required this.spentInPeriod,
    required this.remaining,
    required this.spentToday,
    required this.allowanceToday,
    required this.eatOutMealsToday,
  });

  final LocalDate periodStart;
  final LocalDate nextPayday;
  final int daysUntilPayday;
  final Money spentInPeriod;

  /// Budget left right now. Negative when overspent.
  final Money remaining;
  final Money spentToday;

  /// Today's share, fixed at the start of the day: what was left this
  /// morning divided by the days to payday. Spending today does not shrink
  /// today's allowance; it shows up in [leftToday] instead.
  final Money allowanceToday;

  final int eatOutMealsToday;

  Money get leftToday => allowanceToday - spentToday;
  bool get overToday => spentToday > allowanceToday;
}

/// Turns a period budget plus logged spending into what is left (ADR-008).
final class BudgetLedger {
  const BudgetLedger();

  /// The day the current pay period began: the last payday on or before
  /// [today], or the 1st of the month when no payday is set.
  LocalDate periodStart(int? paydayDayOfMonth, LocalDate today) {
    if (paydayDayOfMonth == null) return LocalDate(today.year, today.month, 1);
    final thisMonth = _clamped(today.year, today.month, paydayDayOfMonth);
    if (!thisMonth.isAfter(today)) return thisMonth;
    return _clamped(today.year, today.month - 1, paydayDayOfMonth);
  }

  LedgerSummary summarize({
    required Money periodBudget,
    required int? paydayDayOfMonth,
    required Iterable<SpendingEntry> entries,
    required LocalDate today,
  }) {
    final start = periodStart(paydayDayOfMonth, today);
    final payday = const SurvivalEngine().nextPayday(
      UserBudgetProfile(
        foodBudget: Money.zero,
        paydayDayOfMonth: paydayDayOfMonth,
      ),
      today,
    );
    var spent = Money.zero;
    var spentToday = Money.zero;
    var eatOutToday = 0;
    for (final e in entries) {
      if (e.date.isBefore(start) || e.date.isAfter(today)) continue;
      spent += e.amount;
      if (e.date == today) {
        spentToday += e.amount;
        if (e.category == SpendCategory.eatOut) eatOutToday++;
      }
    }
    final remaining = periodBudget - spent;
    final days = today.daysUntil(payday);
    final morning = Money.max(Money.zero, remaining + spentToday);
    return LedgerSummary(
      periodStart: start,
      nextPayday: payday,
      daysUntilPayday: days,
      spentInPeriod: spent,
      remaining: remaining,
      spentToday: spentToday,
      allowanceToday: morning.divideFloor(days),
      eatOutMealsToday: eatOutToday,
    );
  }

  static LocalDate _clamped(int year, int month, int day) {
    final first = LocalDate(year, month, 1);
    return LocalDate(first.year, first.month, math.min(day, first.daysInMonth));
  }
}
