import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/app/strings.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/home/domain/home_providers.dart';
import 'package:recipix_app/features/home/presentation/home_page.dart';
import 'package:recipix_app/shared/utils/format.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../helpers.dart';

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(HomePage)));

Future<void> openHome(WidgetTester tester, {double width = 390}) async {
  setPhoneSize(tester, width, height: 1400);
  await tester.pumpWidget(testApp());
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('format', () {
    test('numbers, baht, days, dates', () {
      expect(formatInt(6054), '6,054');
      expect(formatInt(999), '999');
      expect(formatInt(-1200), '-1,200');
      expect(formatBaht(Money.baht(1600)), '1,600');
      expect(formatBaht(const Money.satang(9950)), '99.50');
      expect(formatBahtWhole(const Money.satang(78010), roundUp: true), '781');
      expect(formatBahtWhole(const Money.satang(10099), roundUp: false), '100');
      expect(formatDays(2.96), '2.9');
      expect(formatDays(3), '3.0');
      expect(formatThaiDateLong(testToday), 'วันศุกร์ 16 ต.ค.');
    });
  });

  group('providers', () {
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

    test('recipes reference only catalog keys', () {
      for (final r in testRecipes.recipes) {
        for (final i in r.ingredients) {
          expect(testCatalog[i.key], isNotNull, reason: '${r.id}: ${i.key}');
        }
      }
    });

    test('use-first lists expired before urgent, soonest first', () {
      final list = make().read(useFirstProvider);
      expect(list.first.key, 'cucumber'); // expired yesterday
      expect(list[1].key, 'rice'); // last day today
      expect(list.every((i) => i.daysUntilExpiry(testToday) <= 2), isTrue);
    });

    test('menu suggestion uses something urgent and prefers a full match', () {
      final m = make().read(menuSuggestionProvider)!;
      // Tofu soup with minced pork: pork expires tomorrow, tofu is in.
      expect(m.recipe.id, 'kaeng_jued_tofu');
      expect(m.isJackpot, isTrue);
    });

    test('report counts basket shopping and keeps mystery separate', () {
      final c = make();
      final r = c.read(survivalReportProvider);
      final items = c.read(fridgeProvider).items;
      final expected = items
          .where((i) => i.isIdentified && !i.isExpired(testToday))
          .fold(0.0, (s, i) => s + i.totalKcal);
      expect(r.confirmedKcal, closeTo(expected, 1e-6));
      expect(r.estimatedKcal, 300);
      expect(r.daysUntilPayday, 16);
    });
  });

  testWidgets('shows the headline number, money and deficit', (tester) async {
    await openHome(tester);
    final r = containerOf(tester).read(survivalReportProvider);

    expect(find.text(formatDays(r.survivalDays)), findsOneWidget);
    expect(find.text(formatThaiDateLong(testToday)), findsOneWidget);
    expect(
      find.text(
        r.isCovered
            ? S.budgetCovered
            : S.deficit(formatBahtWhole(r.budgetDeficit, roundUp: true)),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('next-meal')), findsOneWidget);
  });

  testWidgets('swipe right marks used; undo brings it back', (tester) async {
    await openHome(tester);
    final rice = containerOf(tester)
        .read(useFirstProvider)
        .firstWhere((i) => i.key == 'rice');

    await tester.drag(
      find.byKey(ValueKey('use-first-${rice.id}')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(fridgeProvider).byId(rice.id), isNull);
    expect(
      containerOf(tester).read(fridgeProvider).lastRemoval!.kind,
      RemovalKind.used,
    );

    await tester.tap(find.text(S.undo));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(fridgeProvider).byId(rice.id), isNotNull);
  });

  testWidgets('swipe left discards', (tester) async {
    await openHome(tester);
    final pork = containerOf(tester)
        .read(useFirstProvider)
        .firstWhere((i) => i.key == 'pork');
    await tester.drag(
      find.byKey(ValueKey('use-first-${pork.id}')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(
      containerOf(tester).read(fridgeProvider).lastRemoval!.kind,
      RemovalKind.discarded,
    );
    expect(find.text(S.toastDiscarded(pork.name)), findsOneWidget);
  });

  testWidgets('using the headline item updates the number', (tester) async {
    await openHome(tester);
    final before = containerOf(tester).read(survivalReportProvider);
    final pork = containerOf(tester)
        .read(useFirstProvider)
        .firstWhere((i) => i.key == 'pork');
    containerOf(tester).read(fridgeProvider.notifier).use(pork.id);
    await tester.pumpAndSettle();
    final after = containerOf(tester).read(survivalReportProvider);
    expect(after.survivalDays, lessThan(before.survivalDays));
    expect(find.text(formatDays(after.survivalDays)), findsOneWidget);
  });

  testWidgets('tap a row opens the item sheet', (tester) async {
    await openHome(tester);
    await tester.tap(find.text(S.daysLeftLong(0)));
    await tester.pumpAndSettle();
    expect(find.text(S.actionUse), findsOneWidget);
  });

  for (final width in [360.0, 430.0]) {
    testWidgets('no overflow at ${width.toInt()}', (tester) async {
      await openHome(tester, width: width);
      expect(tester.takeException(), isNull);
    });
  }
}
