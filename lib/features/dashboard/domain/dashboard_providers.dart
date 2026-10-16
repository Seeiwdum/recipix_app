import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../budget/domain/budget_controller.dart';
import '../../fridge/domain/fridge_controller.dart';
import '../../scan/domain/barcode_memory.dart';

/// Badge progress, rebuilt by replaying saved history through the core
/// `AchievementManager` (ADR-010). Deterministic: the same history always
/// gives the same badges, so nothing about badges needs its own storage.
///
/// Per day: items used/discarded, the first barcode scan (ADR-014) and
/// dishes cooked, then — for days that
/// are over — a `DayClosed` with that day's spending against the allowance
/// it had that morning.
final badgeProgressProvider = Provider<List<BadgeProgress>>((ref) {
  final today = ref.watch(todayProvider);
  final fridge = ref.watch(fridgeProvider);
  final budget = ref.watch(budgetProvider);

  final byDay = <LocalDate, List<RecipixEvent>>{};
  void add(RecipixEvent e) => (byDay[e.date] ??= []).add(e);

  for (final a in fridge.activity) {
    add(
      a.kind == RemovalKind.used
          ? ItemUsed(a.date, itemId: a.itemId, daysLeft: a.daysLeft)
          : ItemDiscarded(a.date, itemId: a.itemId),
    );
  }
  final firstScan = ref.watch(barcodeMemoryProvider).firstScanOn;
  if (firstScan != null) add(ItemsScanned(firstScan, count: 1));
  for (final c in fridge.cooked) {
    add(
      RecipeCooked(
        c.date,
        recipe: c.recipe,
        urgentItemsUsed: c.urgentItemsUsed,
      ),
    );
  }

  final dates = [...byDay.keys, for (final e in budget.entries) e.date];
  final since = fridge.trackingSince;
  bool tracked(LocalDate d) => since != null && !d.isBefore(since);
  final manager = AchievementManager();
  if (dates.isNotEmpty) {
    final first = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    const ledger = BudgetLedger();
    for (var d = first; !d.isAfter(today); d = d.addDays(1)) {
      byDay[d]?.forEach(manager.handle);
      if (d == today) break;
      final day = ledger.summarize(
        periodBudget: budget.periodBudget,
        paydayDayOfMonth: budget.paydayDayOfMonth,
        entries: budget.entries,
        today: d,
      );
      manager.handle(
        DayClosed(
          d,
          spent: day.spentToday,
          allowance: day.allowanceToday,
          discardedCount: tracked(d)
              ? fridge.activity
                    .where(
                      (a) => a.date == d && a.kind == RemovalKind.discarded,
                    )
                    .length
              : null,
        ),
      );
    }
  }
  final progress = manager.progress;
  manager.dispose();
  return progress;
});

enum DayMark { within, over, noRecord, today, future }

final class TimelineDay {
  const TimelineDay(this.date, this.mark);

  final LocalDate date;
  final DayMark mark;
}

/// One mark per day of the current pay period.
final timelineProvider = Provider<List<TimelineDay>>((ref) {
  final today = ref.watch(todayProvider);
  final budget = ref.watch(budgetProvider);
  final ledger = ref.watch(ledgerProvider);
  const l = BudgetLedger();
  final days = <TimelineDay>[];
  for (
    var d = ledger.periodStart;
    d.isBefore(ledger.nextPayday);
    d = d.addDays(1)
  ) {
    if (d == today) {
      days.add(TimelineDay(d, DayMark.today));
    } else if (d.isAfter(today)) {
      days.add(TimelineDay(d, DayMark.future));
    } else {
      final s = l.summarize(
        periodBudget: budget.periodBudget,
        paydayDayOfMonth: budget.paydayDayOfMonth,
        entries: budget.entries,
        today: d,
      );
      days.add(
        TimelineDay(
          d,
          s.spentToday.isZero
              ? DayMark.noRecord
              : (s.overToday ? DayMark.over : DayMark.within),
        ),
      );
    }
  }
  return days;
});

/// Dishes cooked most often, most first (ties by name). At most five.
final repeatedDishesProvider = Provider<List<({Recipe recipe, int count})>>((
  ref,
) {
  final counts = <String, ({Recipe recipe, int count})>{};
  for (final c in ref.watch(fridgeProvider).cooked) {
    final prev = counts[c.recipe.id];
    counts[c.recipe.id] = (recipe: c.recipe, count: (prev?.count ?? 0) + 1);
  }
  final list = counts.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.recipe.name.compareTo(b.recipe.name);
    });
  return list.take(5).toList();
});
