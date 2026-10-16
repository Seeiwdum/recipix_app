import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/app/strings.dart';
import 'package:recipix_app/features/budget/domain/budget_controller.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/random/data/eat_out_menu.dart';
import 'package:recipix_app/features/random/domain/random_controller.dart';
import 'package:recipix_app/features/random/presentation/random_page.dart';
import 'package:recipix_app/features/random/presentation/random_result_sheets.dart';
import 'package:recipix_app/shared/utils/format.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../helpers.dart';

ProviderContainer make({int seed = 7}) {
  final c = ProviderContainer(
    overrides: [
      catalogProvider.overrideWithValue(testCatalog),
      recipeBookProvider.overrideWithValue(testRecipes),
      eatOutMenuProvider.overrideWithValue(testEatOut),
      randomSourceProvider.overrideWithValue(Random(seed)),
      todayProvider.overrideWithValue(testToday),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(RandomPage)));

Future<void> openRandom(WidgetTester tester, {double width = 390}) async {
  setPhoneSize(tester, width, height: 1000);
  await tester.pumpWidget(testApp(initialLocation: '/random'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('pickEatOut', () {
    final dishes = [
      EatOutDish(id: 'a', name: 'a', price: Money.baht(40)),
      EatOutDish(id: 'b', name: 'b', price: Money.baht(60)),
      EatOutDish(id: 'c', name: 'c', price: Money.baht(90)),
    ];

    test('stays within the limit', () {
      final r = Random(1);
      for (var i = 0; i < 50; i++) {
        final p = pickEatOut(dishes, limit: Money.baht(60), random: r)!;
        expect(p.dish.price <= Money.baht(60), isTrue);
        expect(p.overBudget, isFalse);
      }
    });

    test('nothing fits: cheapest, flagged', () {
      final p = pickEatOut(dishes, limit: Money.baht(10), random: Random(1))!;
      expect(p.dish.id, 'a');
      expect(p.overBudget, isTrue);
    });

    test('avoids repeating the last dish when there is a choice', () {
      final r = Random(3);
      for (var i = 0; i < 30; i++) {
        final p = pickEatOut(
          dishes,
          limit: Money.baht(100),
          random: r,
          avoidId: 'b',
        )!;
        expect(p.dish.id, isNot('b'));
      }
    });
  });

  group('controller', () {
    test('a spin fills three reels from the fridge and decides the result', () {
      final c = make();
      final r = c.read(randomProvider.notifier).spinCook();
      final s = c.read(randomProvider);
      expect(s.reels.whereType<IngredientItem>(), hasLength(3));
      expect(identical(s.result, r), isTrue);
      expect(s.spins, 1);
      final keys = s.reels.map((i) => i!.key).toSet();
      expect(keys, hasLength(3)); // distinct
    });

    test('locked reels keep their item across spins', () {
      final c = make();
      final ctrl = c.read(randomProvider.notifier);
      ctrl.spinCook();
      final kept = c.read(randomProvider).reels[1]!;
      ctrl.toggleLock(1);
      for (var i = 0; i < 5; i++) {
        ctrl.spinCook();
        expect(c.read(randomProvider).reels[1]!.id, kept.id);
      }
      ctrl.toggleLock(1);
      expect(c.read(randomProvider).locked, isEmpty);
    });

    test('a locked item used up in the meantime loses its lock', () {
      final c = make();
      final ctrl = c.read(randomProvider.notifier);
      ctrl.spinCook();
      final item = c.read(randomProvider).reels[0]!;
      ctrl.toggleLock(0);
      c.read(fridgeProvider.notifier).use(item.id);
      ctrl.spinCook();
      final s = c.read(randomProvider);
      expect(s.locked, isEmpty);
      expect(s.reels.any((i) => i?.id == item.id), isFalse);
    });

    test('eat-out spin respects what is left today', () {
      final c = make();
      c.read(budgetProvider.notifier).add(Money.baht(55), SpendCategory.eatOut);
      // 100 allowance - 55 spent = 45 left today.
      final ctrl = c.read(randomProvider.notifier);
      for (var i = 0; i < 10; i++) {
        final d = ctrl.spinEatOut()!;
        expect(d.price <= Money.baht(45), isTrue);
      }
    });
  });

  testWidgets('spin: reels stop one by one, then the result sheet opens', (
    tester,
  ) async {
    await openRandom(tester);
    await tester.tap(find.byKey(const ValueKey('spin')));
    await tester.pump();
    // Result already decided while the reels are still moving.
    expect(containerOf(tester).read(randomProvider).result, isNotNull);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BottomSheet), findsNothing);
    // Labels do not give the result away while reels still move.
    expect(find.text(S.reelSpinning), findsWidgets);
    final spinButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('spin')),
    );
    expect(spinButton.onPressed, isNull); // no double spin

    await settleSpin(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('tap a reel to lock it; locked reel shows the lock', (
    tester,
  ) async {
    await openRandom(tester);
    await tester.tap(find.byKey(const ValueKey('spin')));
    await settleSpin(tester);
    await tester.tapAt(const Offset(10, 10)); // close sheet
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reel-frame-2')));
    await tester.pump();
    final c = containerOf(tester);
    expect(c.read(randomProvider).locked, {2});
    final kept = c.read(randomProvider).reels[2]!.id;

    await tester.tap(find.byKey(const ValueKey('spin')));
    await settleSpin(tester);
    expect(c.read(randomProvider).reels[2]!.id, kept);
  });

  testWidgets('full match cooks from the sheet with undo', (tester) async {
    await openRandom(tester);
    final c = containerOf(tester);
    final soup = testRecipes.recipes.firstWhere(
      (r) => r.id == 'kaeng_jued_tofu',
    );
    final result = SlotSpinResult(
      reels: const [null, null, null],
      bestMatch: RecipeMatch(
        recipe: soup,
        haveKeys: soup.requiredKeys,
        missingKeys: const {},
      ),
      alternatives: const [],
    );
    showCookResultSheet(tester.element(find.byType(RandomPage)), result);
    await tester.pumpAndSettle();
    expect(find.text(S.menuFull), findsOneWidget);
    await tester.tap(find.text(S.cookThis));
    await tester.pumpAndSettle();
    expect(c.read(fridgeProvider).cookedOn(testToday), 1);
    await tester.tap(find.text(S.undo));
    await tester.pumpAndSettle();
    expect(c.read(fridgeProvider).cooked, isEmpty);
  });

  testWidgets('partial match shows what is missing and no cook button', (
    tester,
  ) async {
    await openRandom(tester);
    final kaprao = testRecipes.recipes.firstWhere((r) => r.id == 'kaprao_moo');
    final result = SlotSpinResult(
      reels: const [null, null, null],
      bestMatch: RecipeMatch(
        recipe: kaprao,
        haveKeys: {'pork', 'holy_basil', 'chili', 'rice'},
        missingKeys: {'garlic'},
      ),
      alternatives: const [],
    );
    showCookResultSheet(tester.element(find.byType(RandomPage)), result);
    await tester.pumpAndSettle();
    expect(find.text(S.matchPlain(4, 5, 80)), findsOneWidget);
    expect(find.text('กระเทียม'), findsOneWidget);
    expect(find.text(S.cookThis), findsNothing);
  });

  testWidgets('eat-out: spin a dish and log it as spending', (tester) async {
    await openRandom(tester);
    await tester.tap(find.bySemanticsLabel(S.modeEatOut));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('spin')));
    await settleSpin(tester);

    final c = containerOf(tester);
    final dish = c.read(randomProvider).dish!;
    expect(find.text(dish.name), findsWidgets);
    await tester.tap(find.text(S.eatThis(formatBaht(dish.price))));
    await tester.pumpAndSettle();
    expect(c.read(ledgerProvider).spentToday, dish.price);
    expect(c.read(ledgerProvider).eatOutMealsToday, 1);
  });

  testWidgets('reduced motion: result shows without the reel scroll', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openRandom(tester);
    await tester.tap(find.byKey(const ValueKey('spin')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  for (final width in [360.0, 430.0]) {
    testWidgets('random tab fits at ${width.toInt()}', (tester) async {
      await openRandom(tester, width: width);
      await tester.tap(find.byKey(const ValueKey('spin')));
      await settleSpin(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
