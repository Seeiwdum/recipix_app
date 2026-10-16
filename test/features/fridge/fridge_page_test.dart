import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/strings.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/fridge/domain/fridge_layout.dart';
import 'package:recipix_app/features/fridge/presentation/fridge_board.dart';

import '../../helpers.dart';

// Sample ids are "<key>-<index>" in sampleFridge order.
const cabbage = 'cabbage-12';
const lime = 'lime-16';
const basil = 'holy_basil-6';
const shrimp = 'shrimp-0';

Finder item(String id) => find.byKey(ValueKey('item-$id'));
Finder cell(String compartment, int col, [int row = 0]) =>
    find.byKey(ValueKey('cell-$compartment-$col-$row'));

FridgeState stateOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(FridgeBoard)))
        .read(fridgeProvider);

Future<void> openFridge(WidgetTester tester, {double width = 390}) async {
  setPhoneSize(tester, width, height: 844);
  await tester.pumpWidget(testApp(initialLocation: '/fridge'));
  await tester.pumpAndSettle();
}

/// Drags in small steps so pan updates fire like a real finger.
Future<void> dragTo(WidgetTester tester, Finder from, Offset to) async {
  final start = tester.getCenter(from);
  final gesture = await tester.startGesture(start);
  await tester.pump();
  for (var i = 1; i <= 12; i++) {
    await gesture.moveTo(Offset.lerp(start, to, i / 12)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('drag a 2-wide item from the basket onto an empty shelf', (
    tester,
  ) async {
    await openFridge(tester);
    expect(stateOf(tester).arrangement.contains(cabbage), isFalse);

    final target = Offset.lerp(
      tester.getCenter(cell('shelf3', 0)),
      tester.getCenter(cell('shelf3', 1)),
      0.5,
    )!;
    await dragTo(tester, item(cabbage), target);

    final p = stateOf(tester).arrangement.placements[cabbage]!;
    expect(p.slot, const Slot(CompartmentId.shelf3, 0));
    expect(p.width, 2);
    // Settled exactly onto the two cells.
    expect(
      tester.getCenter(item(cabbage)).dx,
      moreOrLessEquals(target.dx, epsilon: 1),
    );
  });

  testWidgets('a 2-wide item dropped on the door bounces back', (tester) async {
    await openFridge(tester);
    final origin = tester.getCenter(item(cabbage));
    await dragTo(tester, item(cabbage), tester.getCenter(cell('door', 0, 1)));

    expect(stateOf(tester).arrangement.contains(cabbage), isFalse);
    expect(tester.getCenter(item(cabbage)), offsetMoreOrLessEquals(origin));
  });

  testWidgets('dropping on a full slot bounces back', (tester) async {
    await openFridge(tester);
    // Shelf 1 col 0-1 already holds pork.
    await dragTo(tester, item(lime), tester.getCenter(cell('shelf1', 0)));
    expect(stateOf(tester).arrangement.contains(lime), isFalse);
  });

  testWidgets('move an item from shelf to basket by dragging', (tester) async {
    await openFridge(tester);
    final basket = tester.getCenter(find.textContaining(S.basketHint));
    await dragTo(tester, item(shrimp), basket);
    expect(stateOf(tester).arrangement.contains(shrimp), isFalse);
    expect(stateOf(tester).basket.any((i) => i.id == shrimp), isTrue);
  });

  testWidgets('tap opens the sheet; use removes with an undo toast', (
    tester,
  ) async {
    await openFridge(tester);
    await tester.tap(item(basil), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('กะเพรา'), findsWidgets);
    expect(find.text(S.actionUse), findsOneWidget);

    await tester.tap(find.text(S.actionUse));
    await tester.pumpAndSettle();
    expect(stateOf(tester).byId(basil), isNull);
    expect(find.text(S.toastUsed('กะเพรา')), findsOneWidget);

    await tester.tap(find.text(S.undo));
    await tester.pumpAndSettle();
    final p = stateOf(tester).arrangement.placements[basil]!;
    expect(p.slot, const Slot(CompartmentId.crisper, 0));
  });

  testWidgets('basket sheet can put an item away without dragging', (
    tester,
  ) async {
    await openFridge(tester);
    await tester.tap(item(lime));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.actionAutoPlace));
    await tester.pumpAndSettle();
    final p = stateOf(tester).arrangement.placements[lime]!;
    expect(p.slot.compartment, CompartmentId.crisper);
  });

  testWidgets('filter dims items that do not match', (tester) async {
    await openFridge(tester);
    await tester.tap(find.bySemanticsLabel(S.filterUseSoon));
    await tester.pumpAndSettle();

    double opacityOf(String id) => tester
        .widget<AnimatedOpacity>(
          find
              .ancestor(of: item(id), matching: find.byType(AnimatedOpacity))
              .first,
        )
        .opacity;
    expect(opacityOf(shrimp), 0.25); // fresh
    expect(opacityOf(basil), 1); // 2 days left
  });

  testWidgets('crisper drawer toggles open and closed', (tester) async {
    await openFridge(tester);
    final front = find.byKey(const ValueKey('drawer-front'));
    final closedTop = tester.getTopLeft(front).dy;
    await tester.tap(front);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(front).dy, greaterThan(closedTop));
    await tester.tap(front);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(front).dy, closedTop);
  });

  for (final width in [360.0, 430.0]) {
    testWidgets('board fits without overflow at ${width.toInt()}', (
      tester,
    ) async {
      await openFridge(tester, width: width);
      expect(tester.takeException(), isNull);
      final board = tester.getRect(find.byType(FridgeBoard));
      expect(board.right, lessThanOrEqualTo(width));
    });
  }
}
