import 'package:recipix_core/recipix_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  const ledger = BudgetLedger();

  SpendingEntry spend(
    LocalDate date,
    num baht, [
    SpendCategory c = SpendCategory.eatOut,
  ]) => SpendingEntry(
    id: '$date-$baht',
    date: date,
    amount: Money.baht(baht),
    category: c,
  );

  group('period start', () {
    test('no payday: 1st of the month', () {
      expect(ledger.periodStart(null, today), LocalDate(2026, 10, 1));
    });

    test('payday passed this month starts this month', () {
      expect(ledger.periodStart(10, today), LocalDate(2026, 10, 10));
      expect(ledger.periodStart(16, today), today);
    });

    test('payday later this month: last month', () {
      expect(ledger.periodStart(25, today), LocalDate(2026, 9, 25));
    });

    test('clamps to short months and crosses years', () {
      expect(
        ledger.periodStart(31, LocalDate(2026, 3, 15)),
        LocalDate(2026, 2, 28),
      );
      expect(
        ledger.periodStart(25, LocalDate(2027, 1, 5)),
        LocalDate(2026, 12, 25),
      );
    });
  });

  group('summary', () {
    test('subtracts only spending inside the period', () {
      final s = ledger.summarize(
        periodBudget: Money.baht(3000),
        paydayDayOfMonth: null,
        entries: [
          spend(LocalDate(2026, 9, 30), 999), // last period
          spend(LocalDate(2026, 10, 2), 400),
          spend(LocalDate(2026, 10, 17), 50), // future, ignored
        ],
        today: today,
      );
      expect(s.spentInPeriod, Money.baht(400));
      expect(s.remaining, Money.baht(2600));
      expect(s.daysUntilPayday, 16);
    });

    test("today's allowance is fixed at the start of the day", () {
      final s = ledger.summarize(
        periodBudget: Money.baht(1600),
        paydayDayOfMonth: null,
        entries: [spend(today, 60), spend(today, 300, SpendCategory.groceries)],
        today: today,
      );
      // 1600 this morning / 16 days.
      expect(s.allowanceToday, Money.baht(100));
      expect(s.spentToday, Money.baht(360));
      expect(s.leftToday, Money.baht(-260));
      expect(s.overToday, isTrue);
      expect(s.remaining, Money.baht(1240));
      expect(s.eatOutMealsToday, 1);
    });

    test('overspent period: allowance is zero, remaining negative', () {
      final s = ledger.summarize(
        periodBudget: Money.baht(100),
        paydayDayOfMonth: null,
        entries: [spend(LocalDate(2026, 10, 3), 500)],
        today: today,
      );
      expect(s.remaining, Money.baht(-400));
      expect(s.allowanceToday, Money.zero);
    });
  });
}
