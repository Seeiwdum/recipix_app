import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/shell/app_shell.dart';
import 'package:recipix_app/app/strings.dart';
import 'package:recipix_app/features/fridge/presentation/fridge_board.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows five tabs and starts on home', (tester) async {
    setPhoneSize(tester, 390);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    for (final tab in appTabs) {
      expect(find.bySemanticsLabel(tab.label), findsOneWidget);
    }
    expect(find.text(S.homeComingSoon), findsOneWidget);
  });

  testWidgets('tapping a tab switches page and keeps the bar', (tester) async {
    setPhoneSize(tester, 390);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(S.tabRandom));
    await tester.pumpAndSettle();
    expect(find.text(S.randomComingSoon), findsOneWidget);
    expect(find.text(S.homeComingSoon), findsNothing);

    await tester.tap(find.bySemanticsLabel(S.tabDashboard));
    await tester.pumpAndSettle();
    expect(find.text(S.dashboardComingSoon), findsOneWidget);
    expect(find.byType(RecipixTabBar), findsOneWidget);
  });

  testWidgets('tab change animates and finishes within 220ms', (tester) async {
    setPhoneSize(tester, 390);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(S.tabFridge));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Mid-transition: both old and new tab are on stage.
    expect(find.text(S.homeComingSoon), findsOneWidget);
    expect(find.byType(FridgeBoard), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(S.homeComingSoon), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a quick second tap keeps fading the tab it leaves', (
    tester,
  ) async {
    setPhoneSize(tester, 390);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(S.tabFridge));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.bySemanticsLabel(S.tabScan));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    // Fridge is now the outgoing tab and must still be fading, not gone.
    expect(find.byType(FridgeBoard), findsOneWidget);
    expect(find.text(S.scanComingSoon), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(FridgeBoard), findsNothing);
  });

  testWidgets('reduced motion: plain fade, no rise', (tester) async {
    setPhoneSize(tester, 390);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(S.tabScan));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final transform = tester.widget<Transform>(
      find
          .ancestor(
            of: find.text(S.scanComingSoon),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(transform.transform.getTranslation().y, 0);

    await tester.pump(const Duration(milliseconds: 70));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Thai labels fit at 360 without overflow', (tester) async {
    setPhoneSize(tester, 360);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
