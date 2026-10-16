import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/app/strings.dart';
import 'package:recipix_app/features/dashboard/domain/dashboard_providers.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/scan/data/object_finder.dart';
import 'package:recipix_app/features/scan/domain/photo_scan_controller.dart';
import 'package:recipix_app/features/scan/presentation/scan_page.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../helpers.dart';

const twoBoxes = [
  Rect.fromLTRB(0.05, 0.1, 0.45, 0.5),
  Rect.fromLTRB(0.55, 0.5, 0.95, 0.9),
];

ProviderContainer make(FakeFinder finder) {
  final c = ProviderContainer(
    overrides: [
      catalogProvider.overrideWithValue(testCatalog),
      recipeBookProvider.overrideWithValue(testRecipes),
      todayProvider.overrideWithValue(testToday),
      objectFinderProvider.overrideWithValue(finder),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(loadAppFonts);

  group('controller', () {
    test('photo -> boxes -> pick each box once', () async {
      final c = make(FakeFinder(twoBoxes));
      final ctrl = c.read(photoScanProvider.notifier);
      final basket = c.read(fridgeProvider).basket.length;

      await ctrl.captured('a.jpg');
      expect(c.read(photoScanProvider).phase, PhotoPhase.boxes);
      expect(c.read(photoScanProvider).findings!.boxes, hasLength(2));

      expect(ctrl.pick(0, 'cabbage')!.key, 'cabbage');
      expect(ctrl.pick(0, 'egg'), isNull); // already said what it is
      expect(ctrl.pick(1, 'egg')!.key, 'egg');
      expect(ctrl.pick(2, 'egg'), isNull); // no such box
      expect(c.read(fridgeProvider).basket, hasLength(basket + 2));
      expect(c.read(photoScanProvider).picked, {0: 'cabbage', 1: 'egg'});

      ctrl.retake();
      expect(c.read(photoScanProvider).phase, PhotoPhase.camera);
      expect(c.read(photoScanProvider).picked, isEmpty);
    });

    test('device that cannot look: failed, nothing added', () async {
      final c = make(FakeFinder(null));
      await c.read(photoScanProvider.notifier).captured('a.jpg');
      expect(c.read(photoScanProvider).phase, PhotoPhase.failed);
      expect(c.read(photoScanProvider.notifier).pick(0, 'egg'), isNull);
    });

    test('adding from a photo counts as the first scan', () async {
      final c = make(FakeFinder(twoBoxes));
      final ctrl = c.read(photoScanProvider.notifier);
      await ctrl.captured('a.jpg');
      ctrl.pick(0, 'egg');
      final first = c
          .read(badgeProgressProvider)
          .firstWhere((b) => b.badgeId == BadgeIds.firstScan);
      expect(first.isUnlocked, isTrue);
    });
  });

  group('page', () {
    Future<void> openPhoto(
      WidgetTester tester, {
      FakeFinder? finder,
      double width = 390,
    }) async {
      setPhoneSize(tester, width, height: 844);
      await tester.pumpWidget(
        testApp(initialLocation: '/scan', finder: finder),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(S.scanModePhoto));
      await tester.pumpAndSettle();
    }

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(ScanPage)));

    testWidgets('shoot, tap a box, pick, the box shows the name', (
      tester,
    ) async {
      await openPhoto(tester, finder: FakeFinder(twoBoxes));
      expect(find.text(S.photoHint), findsOneWidget);
      expect(find.byKey(const ValueKey('fake-photo-camera-true')), findsOne);

      await tester.tap(find.byKey(const ValueKey('shutter')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo-box-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-box-1')), findsOneWidget);
      expect(find.text(S.photoTapBox), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('photo-box-1')));
      await tester.pumpAndSettle();
      expect(find.text(S.photoPickTitle), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('add-tomato')));
      await tester.pumpAndSettle();

      final name = testCatalog['tomato']!.name;
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('photo-box-1')),
          matching: find.text(name),
        ),
        findsOneWidget,
      );
      expect(find.text(S.photoAdded(1)), findsOneWidget);
      expect(
        containerOf(tester).read(fridgeProvider).basket.last.key,
        'tomato',
      );
    });

    testWidgets('nothing found: says so; retake goes back to the camera', (
      tester,
    ) async {
      await openPhoto(tester, finder: FakeFinder(const []));
      await tester.tap(find.byKey(const ValueKey('shutter')));
      await tester.pumpAndSettle();
      expect(find.text(S.photoNone), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('photo-retake')));
      await tester.pumpAndSettle();
      expect(find.text(S.photoHint), findsOneWidget);
    });

    testWidgets('cannot look on this device: says so', (tester) async {
      await openPhoto(tester, finder: FakeFinder(null));
      await tester.tap(find.byKey(const ValueKey('shutter')));
      await tester.pumpAndSettle();
      expect(find.text(S.photoFailed), findsOneWidget);
    });

    testWidgets('only one camera at a time; none on another tab', (
      tester,
    ) async {
      final camera = FakeCamera();
      setPhoneSize(tester, 390, height: 844);
      await tester.pumpWidget(
        testApp(initialLocation: '/scan', camera: camera),
      );
      await tester.pumpAndSettle();
      expect(camera.active, isTrue);

      await tester.tap(find.bySemanticsLabel(S.scanModePhoto));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fake-camera')), findsNothing);
      expect(find.byKey(const ValueKey('fake-photo-camera-true')), findsOne);

      await tester.tap(find.bySemanticsLabel(S.tabFridge));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('fake-photo-camera-false'),
          skipOffstage: false,
        ),
        findsOne,
      );
    });

    for (final width in [360.0, 430.0]) {
      testWidgets('photo mode fits at ${width.toInt()}', (tester) async {
        await openPhoto(tester, finder: FakeFinder(twoBoxes), width: width);
        await tester.tap(find.byKey(const ValueKey('shutter')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
