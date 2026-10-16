import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/app/strings.dart';
import 'package:recipix_app/features/budget/domain/budget_controller.dart';
import 'package:recipix_app/features/dashboard/domain/dashboard_providers.dart';
import 'package:recipix_app/features/dashboard/presentation/dashboard_page.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/home/domain/home_providers.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../helpers.dart';

ProviderContainer make() {
  final c = ProviderContainer(
    overrides: [
      catalogProvider.overrideWithValue(testCatalog),
      recipeBookProvider.overrideWithValue(testRecipes),
      todayProvider.overrideWithValue(testToday),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

BadgeProgress badge(ProviderContainer c, String id) =>
    c.read(badgeProgressProvider).firstWhere((b) => b.badgeId == id);

Recipe recipe(String id) => testRecipes.recipes.firstWhere((r) => r.id == id);

void main() {
  setUpAll(loadAppFonts);

  group('budget settings', () {
    test('period budget, payday and meal price flow into every number', () {
      final c = make();
      final ctrl = c.read(budgetProvider.notifier);
      final deficit = c.read(survivalReportProvider).budgetDeficit;

      ctrl.setPeriodBudget(
        c.read(budgetProvider).periodBudget + Money.baht(500),
      );
      expect(c.read(ledgerProvider).remaining, Money.baht(2100));
      expect(
        c.read(survivalReportProvider).budgetDeficit,
        Money.max(Money.zero, deficit - Money.baht(500)),
      );

      ctrl.setPayday(20);
      expect(c.read(ledgerProvider).daysUntilPayday, 4);
      expect(c.read(ledgerProvider).periodStart, LocalDate(2026, 9, 20));

      ctrl.setMealOutPrice(Money.baht(45));
      expect(c.read(budgetProvider).prices.mealOutPrice, Money.baht(45));
      expect(
        c.read(mealPlanProvider).meals.first.eatOutCost,
        anyOf(Money.zero, Money.baht(45)),
      );
    });

    test('limits keep values sane', () {
      final c = make();
      final ctrl = c.read(budgetProvider.notifier);
      ctrl.setPeriodBudget(Money.baht(-50));
      expect(c.read(budgetProvider).periodBudget, Money.zero);
      ctrl.setPayday(40);
      expect(c.read(budgetProvider).paydayDayOfMonth, 31);
      ctrl.setPayday(null);
      expect(c.read(budgetProvider).paydayDayOfMonth, isNull);
      ctrl.setMealOutPrice(Money.zero);
      expect(c.read(budgetProvider).prices.mealOutPrice, Money.baht(1));
    });
  });

  group('badges replay history', () {
    test('nothing unlocked from the sample alone', () {
      final c = make();
      expect(c.read(badgeProgressProvider).where((b) => b.isUnlocked), isEmpty);
    });

    test('using urgent items and cooking count toward clear-expiring', () {
      final c = make();
      final fridge = c.read(fridgeProvider.notifier);
      final urgent = c
          .read(useFirstProvider)
          .where((i) => i.daysUntilExpiry(testToday) >= 0);
      for (final i in urgent.take(3)) {
        fridge.use(i.id);
      }
      expect(badge(c, BadgeIds.clearExpiring).current, 3);
      // Undo takes the last one back off the history.
      fridge.undo();
      expect(badge(c, BadgeIds.clearExpiring).current, 2);
    });

    test('cooking counts toward home cook, undo removes it', () {
      final c = make();
      final fridge = c.read(fridgeProvider.notifier);
      fridge.cook(recipe('khai_jiao'));
      expect(badge(c, BadgeIds.homeCook).current, 1);
      fridge.undoCook();
      expect(badge(c, BadgeIds.homeCook).current, 0);
    });

    test(
      'budget streak comes from past days against that day\'s allowance',
      () {
        final c = make();
        final ctrl = c.read(budgetProvider.notifier);
        // A generous budget makes every sample day "within".
        ctrl.setPeriodBudget(Money.baht(100000));
        final p = badge(c, BadgeIds.budgetSaver);
        expect(p.isUnlocked, isTrue);
        expect(p.unlockedOn, LocalDate(2026, 10, 7));
      },
    );

    test('days before tracking began never count toward zero-waste', () {
      final c = make();
      // 15 sample days in the past, but tracking starts today.
      expect(c.read(fridgeProvider).trackingSince, testToday);
      expect(badge(c, BadgeIds.zeroWasteWeek).current, 0);
    });
  });

  group('timeline', () {
    test('one mark per day of the period', () {
      final c = make();
      final days = c.read(timelineProvider);
      expect(days, hasLength(31));
      expect(days.first.date, LocalDate(2026, 10, 1));
      expect(days[15].mark, DayMark.today);
      expect(days.last.mark, DayMark.future);
      // Sample: 180-200 baht a day against ~100-144 allowance.
      expect(days.take(15).every((d) => d.mark == DayMark.over), isTrue);
    });

    test('repeated dishes rank by count', () {
      final c = make();
      final fridge = c.read(fridgeProvider.notifier);
      fridge.cook(recipe('khai_jiao'));
      fridge.cook(recipe('khai_jiao'));
      fridge.cook(recipe('kaeng_jued_tofu'));
      final top = c.read(repeatedDishesProvider);
      expect(top.first.recipe.id, 'khai_jiao');
      expect(top.first.count, 2);
      expect(top, hasLength(2));
    });
  });

  testWidgets('steppers change the budget on screen', (tester) async {
    setPhoneSize(tester, 390, height: 1600);
    await tester.pumpWidget(testApp(initialLocation: '/dashboard'));
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(
      tester.element(find.byType(DashboardPage)),
    );
    final before = c.read(budgetProvider).periodBudget;

    await tester.tap(find.bySemanticsLabel(S.increase(S.periodBudgetLabel)));
    await tester.pump();
    expect(c.read(budgetProvider).periodBudget, before + Money.baht(100));

    await tester.tap(find.bySemanticsLabel(S.increase(S.paydaySetting)));
    await tester.pump();
    expect(find.text(S.paydayDay(1)), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(S.decrease(S.mealPriceSetting)));
    await tester.pump();
    expect(c.read(budgetProvider).prices.mealOutPrice, Money.baht(55));
  });

  testWidgets('holding + repeats and speeds up', (tester) async {
    setPhoneSize(tester, 390, height: 1600);
    await tester.pumpWidget(testApp(initialLocation: '/dashboard'));
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(
      tester.element(find.byType(DashboardPage)),
    );
    final before = c.read(budgetProvider).periodBudget;

    final g = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel(S.increase(S.periodBudgetLabel))),
    );
    await tester.pump(const Duration(milliseconds: 600)); // long press
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    await g.up();
    await tester.pump();
    final steps =
        (c.read(budgetProvider).periodBudget - before).satang ~/ 10000;
    expect(steps, greaterThan(15)); // sped up past x1
  });

  testWidgets('badge tile opens its rule', (tester) async {
    setPhoneSize(tester, 390, height: 1600);
    await tester.pumpWidget(testApp(initialLocation: '/dashboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('badge-home_cook')));
    await tester.pumpAndSettle();
    expect(find.text(S.badgeRules['home_cook']!), findsOneWidget);
    expect(find.text(S.badgeProgress(0, 10)), findsOneWidget);
  });

  for (final width in [360.0, 430.0]) {
    testWidgets('dashboard fits at ${width.toInt()}', (tester) async {
      setPhoneSize(tester, width, height: 1600);
      await tester.pumpWidget(testApp(initialLocation: '/dashboard'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
