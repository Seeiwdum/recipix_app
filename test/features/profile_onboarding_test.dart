import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/app/strings.dart';
import 'package:recipix_app/features/budget/domain/budget_controller.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/fridge/domain/fridge_layout.dart';
import 'package:recipix_app/features/home/domain/home_providers.dart';
import 'package:recipix_app/features/home/presentation/home_page.dart';
import 'package:recipix_app/features/profile/domain/profile_controller.dart';
import 'package:recipix_app/features/profile/presentation/onboarding_page.dart';
import 'package:recipix_app/shared/persistence/app_store.dart';
import 'package:recipix_app/shared/persistence/codecs.dart';
import 'package:recipix_core/recipix_core.dart';

import '../helpers.dart';

ProviderContainer make({SavedData saved = const SavedData()}) {
  final c = ProviderContainer(
    overrides: [
      catalogProvider.overrideWithValue(testCatalog),
      recipeBookProvider.overrideWithValue(testRecipes),
      todayProvider.overrideWithValue(testToday),
      savedDataProvider.overrideWithValue(saved),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(loadAppFonts);

  group('applying the answers', () {
    test('fresh install: empty fridge, no spending, left = the answer', () {
      final c = make();
      // Sample data exists before the questions are answered.
      expect(c.read(fridgeProvider).items, isNotEmpty);
      c
          .read(profileProvider.notifier)
          .complete(
            OnboardingAnswers(
              name: '  มายด์ ',
              favoriteRecipeIds: {'khai_jiao'},
              monthlyFoodSpend: Money.baht(6000),
              moneyLeft: Money.baht(2500),
              paydayDayOfMonth: 25,
            ),
          );
      expect(c.read(fridgeProvider).items, isEmpty);
      expect(c.read(budgetProvider).entries, isEmpty);
      expect(c.read(ledgerProvider).remaining, Money.baht(2500));
      expect(c.read(budgetProvider).paydayDayOfMonth, 25);
      // 6000 / 90 meals = 66.7 -> 65 baht.
      expect(c.read(budgetProvider).prices.mealOutPrice, Money.baht(65));
      final p = c.read(profileProvider);
      expect(p.name, 'มายด์');
      expect(p.isComplete, isTrue);
      expect(p.favoriteRecipeIds, {'khai_jiao'});
    });

    test('existing data is kept; left still matches the answer', () {
      final c = make(
        saved: SavedData(
          fridge: SavedFridge(
            items: const [],
            arrangement: FridgeArrangement(),
            cooked: const [],
          ),
          budget: SavedBudget(
            periodBudget: Money.baht(3000),
            paydayDayOfMonth: null,
            prices: const PriceSettings(),
            quickAmounts: const [],
            entries: [
              SpendingEntry(id: 'x', date: testToday, amount: Money.baht(400)),
            ],
          ),
        ),
      );
      c
          .read(profileProvider.notifier)
          .complete(OnboardingAnswers(name: 'เอ', moneyLeft: Money.baht(1000)));
      expect(c.read(budgetProvider).entries, hasLength(1));
      expect(c.read(ledgerProvider).remaining, Money.baht(1000));
    });

    test('meal price guess stays within everyday prices', () {
      expect(ProfileController.mealPriceFrom(Money.baht(100)), Money.baht(20));
      expect(
        ProfileController.mealPriceFrom(Money.baht(90000)),
        Money.baht(300),
      );
    });

    test('profile survives a save and load', () {
      final saved = SavedProfile(
        name: 'เอ',
        favoriteRecipeIds: const ['kaprao_moo'],
        monthlyFoodSpend: Money.baht(5000),
        completedOn: testToday,
      );
      final back = SavedProfile.fromJson(saved.toJson());
      expect(back.name, 'เอ');
      expect(back.favoriteRecipeIds, ['kaprao_moo']);
      expect(back.monthlyFoodSpend, Money.baht(5000));
      expect(back.completedOn, testToday);
    });

    test('a favourite dish is suggested', () {
      final c = make(
        saved: SavedData(
          profile: SavedProfile(
            name: 'เอ',
            favoriteRecipeIds: const ['kiew_nam'],
            completedOn: testToday,
          ),
        ),
      );
      final ids = c
          .read(menuSuggestionsProvider)
          .map((s) => s.match.recipe.id)
          .toList();
      expect(ids, contains('kiew_nam'));
    });
  });

  testWidgets('first launch: questions first, then home with the name', (
    tester,
  ) async {
    setPhoneSize(tester, 390, height: 844);
    await tester.pumpWidget(testApp(onboarded: false));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);

    FilledButton next() =>
        tester.widget(find.byKey(const ValueKey('onboard-next')));

    // Step 1: name required.
    expect(next().onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey('onboard-name')), 'บี');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboard-next')));
    await tester.pumpAndSettle();

    // Step 2: favourites.
    expect(find.text(S.onboardFoodTitle), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fav-khai_jiao')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboard-next')));
    await tester.pumpAndSettle();

    // Step 3: money left is required.
    expect(find.text(S.onboardMoneyTitle), findsOneWidget);
    expect(next().onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey('onboard-left')), '1800');
    await tester.enterText(
      find.byKey(const ValueKey('onboard-monthly')),
      '6000',
    );
    await tester.tap(find.bySemanticsLabel(S.increase(S.paydaySetting)));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboard-next')));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text(S.greeting('บี')), findsOneWidget);
    final c = ProviderScope.containerOf(tester.element(find.byType(HomePage)));
    expect(c.read(ledgerProvider).remaining, Money.baht(1800));
    expect(c.read(budgetProvider).paydayDayOfMonth, 1);
  });

  testWidgets('back goes to the previous step', (tester) async {
    setPhoneSize(tester, 390, height: 844);
    await tester.pumpWidget(testApp(onboarded: false));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('onboard-name')), 'บี');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboard-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboard-back')));
    await tester.pumpAndSettle();
    expect(find.text(S.onboardWelcome), findsOneWidget);
  });

  for (final width in [360.0, 430.0]) {
    testWidgets('onboarding fits at ${width.toInt()}', (tester) async {
      setPhoneSize(tester, width, height: 700);
      await tester.pumpWidget(testApp(onboarded: false));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('onboard-name')), 'บี');
      await tester.pump();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('onboard-next')));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
