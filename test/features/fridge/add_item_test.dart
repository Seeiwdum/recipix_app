import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/app/strings.dart';
import 'package:recipix_app/features/dashboard/domain/dashboard_providers.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/fridge/presentation/fridge_board.dart';
import 'package:recipix_app/features/home/presentation/home_page.dart';

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

void main() {
  setUpAll(loadAppFonts);

  group('controller', () {
    test('adds a fresh catalog item to the basket', () {
      final c = make();
      final before = c.read(fridgeProvider).basket.length;
      final item = c.read(fridgeProvider.notifier).addFromCatalog('egg')!;
      final s = c.read(fridgeProvider);
      expect(s.basket, hasLength(before + 1));
      expect(s.arrangement.contains(item.id), isFalse);
      expect(item.addedOn, testToday);
      expect(
        item.expiresOn,
        testToday.addDays(testCatalog['egg']!.shelfLifeDays),
      );
    });

    test('two adds of the same kind get different ids', () {
      final c = make();
      final ctrl = c.read(fridgeProvider.notifier);
      final a = ctrl.addFromCatalog('egg')!;
      final b = ctrl.addFromCatalog('egg')!;
      expect(a.id, isNot(b.id));
    });

    test('unknown key adds nothing', () {
      final c = make();
      final n = c.read(fridgeProvider).items.length;
      expect(c.read(fridgeProvider.notifier).addFromCatalog('nope'), isNull);
      expect(c.read(fridgeProvider).items, hasLength(n));
    });

    test('taking back an added item leaves no history', () {
      final c = make();
      final ctrl = c.read(fridgeProvider.notifier);
      final badgesBefore = c.read(badgeProgressProvider);
      final item = ctrl.addFromCatalog('tomato')!;
      ctrl.removeAdded(item.id);
      expect(c.read(fridgeProvider).byId(item.id), isNull);
      expect(c.read(fridgeProvider).activity, isEmpty);
      expect(
        c.read(badgeProgressProvider).map((b) => b.current),
        badgesBefore.map((b) => b.current),
      );
    });

    test('removeAdded ignores items already on a shelf', () {
      final c = make();
      final ctrl = c.read(fridgeProvider.notifier);
      final item = ctrl.addFromCatalog('tomato')!;
      expect(ctrl.autoPlace(item.id), isNotNull);
      ctrl.removeAdded(item.id);
      expect(c.read(fridgeProvider).byId(item.id), isNotNull);
    });
  });

  testWidgets('fridge: add button opens the sheet; taps fill the basket', (
    tester,
  ) async {
    setPhoneSize(tester, 390, height: 844);
    await tester.pumpWidget(testApp(initialLocation: '/fridge'));
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(
      tester.element(find.byType(FridgeBoard)),
    );
    final before = c.read(fridgeProvider).basket.length;

    await tester.tap(find.byKey(const ValueKey('add-item')));
    await tester.pumpAndSettle();
    expect(find.text(S.addItemTitle), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-egg')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('add-egg')));
    await tester.pump();
    expect(c.read(fridgeProvider).basket, hasLength(before + 2));
    expect(find.text(S.addedLine('ไข่ไก่', 2)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('remove-added')));
    await tester.pump();
    expect(c.read(fridgeProvider).basket, hasLength(before + 1));

    await tester.tap(find.byKey(const ValueKey('add-done')));
    await tester.pumpAndSettle();
    expect(find.text(S.addItemTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 430.0]) {
    testWidgets('add sheet fits at ${width.toInt()}', (tester) async {
      setPhoneSize(tester, width, height: 760);
      await tester.pumpWidget(testApp(initialLocation: '/fridge'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-item')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home: empty fridge links to the fridge tab', (tester) async {
    setPhoneSize(tester, 390, height: 1400);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(tester.element(find.byType(HomePage)));
    final ctrl = c.read(fridgeProvider.notifier);
    for (final i in [...c.read(fridgeProvider).items]) {
      ctrl.use(i.id);
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('go-add-items')));
    await tester.pumpAndSettle();
    expect(find.byType(FridgeBoard), findsOneWidget);
  });
}
