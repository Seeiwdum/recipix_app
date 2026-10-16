import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/app/strings.dart';
import 'package:recipix_app/features/budget/domain/budget_controller.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/home/domain/home_providers.dart';
import 'package:recipix_app/features/home/presentation/home_page.dart';
import 'package:recipix_app/features/home/presentation/meal_plan_page.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../helpers.dart';

ProviderContainer makeContainer() {
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

ProviderContainer containerOf(WidgetTester tester, Type page) =>
    ProviderScope.containerOf(tester.element(find.byType(page)));

void main() {
  setUpAll(loadAppFonts);

  group('budget state', () {
    test('sample leaves 1,600 baht at the start of today', () {
      final c = makeContainer();
      final l = c.read(ledgerProvider);
      expect(l.remaining, Money.baht(1600));
      expect(l.allowanceToday, Money.baht(100));
      expect(c.read(budgetProfileProvider).foodBudget, Money.baht(1600));
    });

    test('logging spending lowers what is left but not today\'s allowance', () {
      final c = makeContainer();
      final before = c.read(survivalReportProvider).budgetDeficit;
      c.read(budgetProvider.notifier).add(Money.baht(60), SpendCategory.eatOut);
      final l = c.read(ledgerProvider);
      expect(l.remaining, Money.baht(1540));
      expect(l.allowanceToday, Money.baht(100));
      expect(l.leftToday, Money.baht(40));
      expect(
        c.read(survivalReportProvider).budgetDeficit,
        before + Money.baht(60),
      );
    });

    test('eat-out spending covers a meal slot in the plan', () {
      final c = makeContainer();
      final before = c.read(mealPlanProvider).meals.length;
      c.read(budgetProvider.notifier).add(Money.baht(60), SpendCategory.eatOut);
      expect(c.read(mealPlanProvider).meals.length, before - 1);
      c
          .read(budgetProvider.notifier)
          .add(Money.baht(300), SpendCategory.groceries);
      expect(c.read(mealPlanProvider).meals.length, before - 1);
    });
  });

  group('cooking', () {
    test('cook deducts by quantity, logs the meal, undo restores', () {
      final c = makeContainer();
      final ctrl = c.read(fridgeProvider.notifier);
      final soup = testRecipes.recipes.firstWhere(
        (r) => r.id == 'kaeng_jued_tofu',
      );
      final planBefore = c.read(mealPlanProvider).meals.length;

      expect(ctrl.cook(soup), isNotNull);
      var s = c.read(fridgeProvider);
      final tofu = s.items.firstWhere((i) => i.key == 'tofu');
      final pork = s.items.firstWhere((i) => i.key == 'pork');
      expect(tofu.quantity.amount, 1);
      expect(pork.quantity.amount, 200);
      expect(s.cookedOn(testToday), 1);
      expect(c.read(mealPlanProvider).meals.length, planBefore - 1);

      ctrl.undoCook();
      s = c.read(fridgeProvider);
      expect(s.items.firstWhere((i) => i.key == 'tofu').quantity.amount, 2);
      expect(s.cooked, isEmpty);
    });

    test('used-up items leave their shelf', () {
      final c = makeContainer();
      final ctrl = c.read(fridgeProvider.notifier);
      final basil = c
          .read(fridgeProvider)
          .items
          .firstWhere((i) => i.key == 'holy_basil');
      final omeletteish = Recipe(
        id: 'basil_all',
        name: 'basil',
        kcalPerServing: 10,
        ingredients: const [RecipeIngredient('holy_basil', Quantity.grams(50))],
      );
      ctrl.cook(omeletteish);
      final s = c.read(fridgeProvider);
      expect(s.byId(basil.id), isNull);
      expect(s.arrangement.contains(basil.id), isFalse);
    });

    test('cooking without everything changes nothing', () {
      final c = makeContainer();
      final ctrl = c.read(fridgeProvider.notifier);
      final before = c.read(fridgeProvider);
      final kaprao = testRecipes.recipes.firstWhere(
        (r) => r.id == 'kaprao_moo',
      ); // no garlic in the sample
      expect(ctrl.cook(kaprao), isNull);
      expect(identical(c.read(fridgeProvider), before), isTrue);
    });
  });

  testWidgets('log spending from home; undo removes it', (tester) async {
    setPhoneSize(tester, 390, height: 1400);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('log-spending')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('spend-amount')), '60');
    await tester.pump();
    await tester.tap(find.text(S.spendSave));
    await tester.pumpAndSettle();

    final c = containerOf(tester, HomePage);
    expect(c.read(ledgerProvider).spentToday, Money.baht(60));
    expect(find.text(S.spentToday('60', '40')), findsOneWidget);

    await tester.tap(find.text(S.undo));
    await tester.pumpAndSettle();
    expect(c.read(ledgerProvider).spentToday, Money.zero);
  });

  testWidgets('quick amount and category, save stays disabled at zero', (
    tester,
  ) async {
    setPhoneSize(tester, 390, height: 1400);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('log-spending')));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(FilledButton, S.spendSave);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.tap(find.bySemanticsLabel(S.spendCategories['groceries']!));
    await tester.tap(find.bySemanticsLabel('100 ${S.bahtUnit}'));
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    final entries = containerOf(
      tester,
      HomePage,
    ).read(budgetProvider).entries.where((e) => e.date == testToday);
    expect(entries.single.amount, Money.baht(100));
    expect(entries.single.category, SpendCategory.groceries);
  });

  testWidgets('open the plan, cook a meal from it, undo', (tester) async {
    setPhoneSize(tester, 390, height: 1400);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-plan')));
    await tester.pumpAndSettle();
    expect(find.byType(MealPlanPage), findsOneWidget);

    final c = containerOf(tester, MealPlanPage);
    final plan = c.read(mealPlanProvider);
    expect(plan.homeMeals, greaterThan(0));
    final first = plan.nextHomeMeal!;

    await tester.tap(
      find.byKey(ValueKey('plan-meal-${first.date}-${first.slot}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.cookDone));
    await tester.pumpAndSettle();
    expect(c.read(fridgeProvider).cookedOn(testToday), 1);
    expect(find.text(S.toastCooked(first.recipe!.name)), findsOneWidget);

    await tester.tap(find.text(S.undo));
    await tester.pumpAndSettle();
    expect(c.read(fridgeProvider).cooked, isEmpty);

    await tester.tap(find.byKey(const ValueKey('plan-back')));
    await tester.pumpAndSettle();
    expect(find.byType(MealPlanPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('undo toast goes away after 5 seconds', (tester) async {
    setPhoneSize(tester, 390, height: 1400);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('log-spending')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('spend-amount')), '60');
    await tester.pump();
    await tester.tap(find.text(S.spendSave));
    await tester.pumpAndSettle();
    expect(find.text(S.undo), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text(S.undo), findsNothing);
  });

  for (final width in [360.0, 430.0]) {
    testWidgets('plan page fits at ${width.toInt()}', (tester) async {
      setPhoneSize(tester, width, height: 844);
      await tester.pumpWidget(testApp(initialLocation: '/home/plan'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
