import 'package:recipix_core/recipix_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  const engine = SurvivalEngine();
  final profile = UserBudgetProfile(foodBudget: Money.baht(1600));

  group('calories', () {
    test('sums only unexpired items', () {
      final report = engine.evaluate(
        items: [
          item('rice', kcalPerUnit: 3000),
          item('egg', kcalPerUnit: 1000, daysLeft: 0),
          item('old milk', kcalPerUnit: 5000, daysLeft: -1),
        ],
        profile: profile,
        today: today,
      );
      expect(report.confirmedKcal, 4000);
      expect(report.expiredItems.map((i) => i.id), ['old milk']);
    });

    test('survival days = kcal / 2000', () {
      final report = engine.evaluate(
        items: [item('rice', kcalPerUnit: 4200)],
        profile: profile,
        today: today,
      );
      expect(report.survivalDays, closeTo(2.1, 1e-9));
    });

    test('scales by quantity', () {
      final report = engine.evaluate(
        items: [
          item('rice', quantity: const Quantity.grams(500), kcalPerUnit: 1.3),
        ],
        profile: profile,
        today: today,
      );
      expect(report.confirmedKcal, closeTo(650, 1e-9));
    });

    test('mystery items are estimated, not confirmed', () {
      final report = engine.evaluate(
        items: [
          item('rice', kcalPerUnit: 2000),
          item('box', mystery: true, kcalPerUnit: 1000),
        ],
        profile: profile,
        today: today,
      );
      expect(report.confirmedKcal, 2000);
      expect(report.estimatedKcal, 1000);
      expect(report.survivalDays, 1);
      expect(report.survivalDaysWithEstimate, 1.5);
    });
  });

  group('urgent items', () {
    test('0-2 days left are urgent, sorted soonest first', () {
      final report = engine.evaluate(
        items: [
          item('a', daysLeft: 2),
          item('b', daysLeft: 3),
          item('c', daysLeft: 0),
          item('d', daysLeft: -1),
          item('e', daysLeft: 1),
        ],
        profile: profile,
        today: today,
      );
      expect(report.urgentItems.map((i) => i.id), ['c', 'e', 'a']);
    });
  });

  group('payday and allowance', () {
    test('no payday: budget lasts to end of month', () {
      // 16 Oct -> 1 Nov = 16 days (16th..31st).
      expect(engine.nextPayday(profile, today), LocalDate(2026, 11, 1));
      expect(engine.dailyAllowance(profile, today), Money.baht(100));
    });

    test('last day of month still has one day', () {
      final d = LocalDate(2026, 10, 31);
      expect(engine.dailyAllowance(profile, d), Money.baht(1600));
    });

    test('payday later this month', () {
      final p = profile.copyWith(paydayDayOfMonth: 25);
      expect(engine.nextPayday(p, today), LocalDate(2026, 10, 25));
    });

    test('payday today or passed rolls to next month', () {
      final p = profile.copyWith(paydayDayOfMonth: 16);
      expect(engine.nextPayday(p, today), LocalDate(2026, 11, 16));
      final p2 = profile.copyWith(paydayDayOfMonth: 5);
      expect(engine.nextPayday(p2, today), LocalDate(2026, 11, 5));
    });

    test('payday 31 clamps to short months', () {
      final p = profile.copyWith(paydayDayOfMonth: 31);
      expect(
        engine.nextPayday(p, LocalDate(2026, 11, 2)),
        LocalDate(2026, 11, 30),
      );
      expect(
        engine.nextPayday(p, LocalDate(2027, 1, 31)),
        LocalDate(2027, 2, 28),
      );
    });

    test('December rolls into next year', () {
      expect(
        engine.nextPayday(profile, LocalDate(2026, 12, 20)),
        LocalDate(2027, 1, 1),
      );
    });

    test('allowance rounds down to the satang', () {
      final p = UserBudgetProfile(foodBudget: const Money.satang(1000));
      // 3 days left in month.
      expect(
        engine.dailyAllowance(p, LocalDate(2026, 10, 29)),
        const Money.satang(333),
      );
    });
  });

  group('budget deficit (ADR-002)', () {
    test('zero when the fridge covers every day', () {
      final report = engine.evaluate(
        items: [item('rice', kcalPerUnit: 2000 * 20)],
        profile: UserBudgetProfile(foodBudget: Money.zero),
        today: today,
      );
      expect(report.uncoveredDays, 0);
      expect(report.budgetDeficit, Money.zero);
      expect(report.isCovered, isTrue);
    });

    test('uncovered days priced at eat-out cost minus budget', () {
      // 16 days, fridge covers 6 -> 10 uncovered * 3 meals * 60 = 1800.
      final report = engine.evaluate(
        items: [item('rice', kcalPerUnit: 2000 * 6)],
        profile: UserBudgetProfile(foodBudget: Money.baht(1500)),
        today: today,
      );
      expect(report.uncoveredDays, 10);
      expect(report.costToCoverUncovered, Money.baht(1800));
      expect(report.budgetDeficit, Money.baht(300));
      expect(report.isCovered, isFalse);
    });

    test('uses editable prices', () {
      final report = engine.evaluate(
        items: const [],
        profile: UserBudgetProfile(
          foodBudget: Money.zero,
          prices: PriceSettings(mealOutPrice: Money.baht(40), mealsPerDay: 2),
        ),
        today: LocalDate(2026, 10, 31),
      );
      expect(report.budgetDeficit, Money.baht(80));
    });

    test('mystery calories do not reduce the deficit', () {
      final report = engine.evaluate(
        items: [item('box', mystery: true, kcalPerUnit: 2000 * 30)],
        profile: UserBudgetProfile(foodBudget: Money.zero),
        today: LocalDate(2026, 10, 31),
      );
      expect(report.budgetDeficit, Money.baht(180));
    });
  });
}
