import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/app/strings.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/home/domain/home_providers.dart';
import 'package:recipix_app/features/home/presentation/home_page.dart';
import 'package:recipix_app/features/home/presentation/recipe_page.dart';
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

Future<ProviderContainer> openRecipe(
  WidgetTester tester,
  String id, {
  double width = 390,
}) async {
  setPhoneSize(tester, width, height: 1400);
  await tester.pumpWidget(testApp(initialLocation: '/home/recipe/$id'));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(RecipePage)));
}

void main() {
  setUpAll(loadAppFonts);

  test('every recipe has steps and a difficulty', () {
    for (final r in testRecipes.recipes) {
      expect(r.steps, isNotEmpty, reason: r.id);
    }
    expect(
      testRecipes.recipes.map((r) => r.difficulty).toSet(),
      contains(RecipeDifficulty.medium),
    );
  });

  test('detail: tofu soup uses urgent pork, so it moves clear-expiring', () {
    final d = make().read(recipeDetailProvider('kaeng_jued_tofu'))!;
    expect(d.match.isJackpot, isTrue);
    expect(d.urgentItemsUsed, greaterThan(0));
    expect(d.badgeGains[BadgeIds.homeCook], 1);
    expect(d.badgeGains[BadgeIds.clearExpiring], d.urgentItemsUsed);
  });

  test('detail: unknown id is null', () {
    expect(make().read(recipeDetailProvider('nope')), isNull);
  });

  testWidgets('home suggestion opens its recipe page', (tester) async {
    setPhoneSize(tester, 390, height: 1600);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(tester.element(find.byType(HomePage)));
    final first = c.read(menuSuggestionsProvider).first.match.recipe;

    await tester.ensureVisible(find.byKey(ValueKey('menu-${first.id}')));
    await tester.tap(find.byKey(ValueKey('menu-${first.id}')));
    await tester.pumpAndSettle();
    expect(find.byType(RecipePage), findsOneWidget);
    expect(find.text(first.name), findsOneWidget);
    expect(find.text(first.steps.first), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recipe-back')));
    await tester.pumpAndSettle();
    expect(find.byType(RecipePage), findsNothing);
  });

  testWidgets('full match: cook from the page, with undo', (tester) async {
    final c = await openRecipe(tester, 'kaeng_jued_tofu');
    expect(find.byKey(const ValueKey('gain-home_cook')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recipe-cook')));
    await tester.pumpAndSettle();
    expect(c.read(fridgeProvider).cookedOn(testToday), 1);
    await tester.tap(find.text(S.undo));
    await tester.pumpAndSettle();
    expect(c.read(fridgeProvider).cooked, isEmpty);
  });

  testWidgets('partial match: no cook button, missing marked', (tester) async {
    final c = await openRecipe(tester, 'pad_pak_boong');
    final d = c.read(recipeDetailProvider('pad_pak_boong'))!;
    expect(d.match.isJackpot, isFalse);
    expect(find.byKey(const ValueKey('recipe-cook')), findsNothing);
    expect(find.text(S.recipeNeed(d.match.missingKeys.length)), findsOneWidget);
  });

  for (final width in [360.0, 430.0]) {
    testWidgets('recipe page fits at ${width.toInt()}', (tester) async {
      await openRecipe(tester, 'kaprao_moo', width: width);
      expect(tester.takeException(), isNull);
    });
  }
}
