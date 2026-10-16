// Goldens at the three checklist widths. Regenerate deliberately with:
//   flutter test --update-goldens test/golden
@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/app.dart';
import 'package:recipix_app/features/fridge/presentation/fridge_board.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('fridge item sheet at 390', (tester) async {
    setPhoneSize(tester, 390, height: 844);
    await tester.pumpWidget(testApp(initialLocation: '/fridge'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-holy_basil-6')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RecipixApp),
      matchesGoldenFile('goldens/fridge_sheet_390.png'),
    );
  });

  testWidgets('fridge mid-drag at 390', (tester) async {
    setPhoneSize(tester, 390, height: 844);
    await tester.pumpWidget(testApp(initialLocation: '/fridge'));
    await tester.pumpAndSettle();
    final from = tester.getCenter(
      find.byKey(const ValueKey('item-cabbage-12')),
    );
    final to = tester.getCenter(find.byKey(const ValueKey('cell-shelf3-1-0')));
    final gesture = await tester.startGesture(from);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(from, to, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
      find.byType(RecipixApp),
      matchesGoldenFile('goldens/fridge_drag_390.png'),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('home shell at ${width.toInt()}', (tester) async {
      setPhoneSize(tester, width, height: 844);
      await tester.pumpWidget(testApp());
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RecipixApp),
        matchesGoldenFile('goldens/home_${width.toInt()}.png'),
      );
    });

    testWidgets('fridge board at ${width.toInt()}', (tester) async {
      setPhoneSize(tester, width, height: 844);
      await tester.pumpWidget(testApp(initialLocation: '/fridge'));
      await tester.pumpAndSettle();
      expect(find.byType(FridgeBoard), findsOneWidget);
      await expectLater(
        find.byType(RecipixApp),
        matchesGoldenFile('goldens/fridge_${width.toInt()}.png'),
      );
    });
  }
}
