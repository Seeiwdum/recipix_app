import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/app/strings.dart';
import 'package:recipix_app/features/dashboard/domain/dashboard_providers.dart';
import 'package:recipix_app/features/fridge/domain/fridge_controller.dart';
import 'package:recipix_app/features/scan/data/product_lookup.dart';
import 'package:recipix_app/features/scan/domain/barcode_memory.dart';
import 'package:recipix_app/features/scan/domain/scan_controller.dart';
import 'package:recipix_app/features/scan/presentation/scan_page.dart';
import 'package:recipix_app/shared/persistence/app_store.dart';
import 'package:recipix_app/shared/persistence/codecs.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../helpers.dart';

const milk = '8850329100011';
const egg = '8851234567890';

ProviderContainer make({ProductLookup? lookup, SavedData? saved}) {
  final c = ProviderContainer(
    overrides: [
      catalogProvider.overrideWithValue(testCatalog),
      recipeBookProvider.overrideWithValue(testRecipes),
      todayProvider.overrideWithValue(testToday),
      productLookupProvider.overrideWithValue(lookup ?? FakeLookup()),
      if (saved != null) savedDataProvider.overrideWithValue(saved),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(loadAppFonts);

  group('Open Food Facts parsing', () {
    test('found: Thai name first, first brand only', () {
      final r = OpenFoodFactsLookup.parse({
        'status': 'success',
        'product': {
          'product_name': 'Fresh milk',
          'product_name_th': 'นมสด',
          'brands': 'Meiji, CP',
        },
      });
      expect(r, isA<ProductFound>());
      expect((r as ProductFound).name, 'นมสด');
      expect(r.brand, 'Meiji');
    });

    test('found without any name', () {
      final r = OpenFoodFactsLookup.parse({
        'status': 'success',
        'product': {'product_name': '  '},
      });
      expect((r as ProductFound).name, isEmpty);
    });

    test('not found vs. other failures', () {
      expect(
        OpenFoodFactsLookup.parse({
          'status': 'failure',
          'result': {'id': 'product_not_found'},
        }),
        isA<ProductNotFound>(),
      );
      expect(
        OpenFoodFactsLookup.parse({'status': 'failure'}),
        isA<LookupFailed>(),
      );
      expect(OpenFoodFactsLookup.parse('nonsense'), isA<LookupFailed>());
    });

    test('sends only the barcode, with the app user agent', () async {
      late http.Request sent;
      final lookup = OpenFoodFactsLookup(
        MockClient((req) async {
          sent = req;
          return http.Response(
            '{"status":"failure","result":{"id":"product_not_found"}}',
            404,
          );
        }),
      );
      expect(await lookup.find(milk), isA<ProductNotFound>());
      expect(sent.url.host, 'world.openfoodfacts.org');
      expect(sent.url.path, '/api/v3/product/$milk');
      expect(sent.headers['User-Agent'], OpenFoodFactsLookup.userAgent);
    });

    test('server error or no network is a failure, not a crash', () async {
      final down = OpenFoodFactsLookup(
        MockClient((_) async => http.Response('oops', 503)),
      );
      expect(await down.find(milk), isA<LookupFailed>());
      final offline = OpenFoodFactsLookup(
        MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(await offline.find(milk), isA<LookupFailed>());
    });
  });

  group('controller', () {
    test('only retail product codes are looked up', () async {
      final lookup = FakeLookup();
      final c = make(lookup: lookup);
      final ctrl = c.read(scanProvider.notifier);
      await ctrl.onBarcode('https://example.com/qr');
      await ctrl.onBarcode('123');
      expect(lookup.calls, 0);
      expect(c.read(scanProvider).phase, ScanPhase.scanning);
    });

    test('unknown barcode: lookup, pick, remembered for next time', () async {
      final lookup = FakeLookup({milk: const ProductFound(name: 'นมสด')});
      final c = make(lookup: lookup);
      final ctrl = c.read(scanProvider.notifier);
      final basket = c.read(fridgeProvider).basket.length;

      await ctrl.onBarcode(milk);
      final s = c.read(scanProvider);
      expect(s.phase, ScanPhase.picked);
      expect((s.lookup! as ProductFound).name, 'นมสด');

      final item = ctrl.add('milk')!;
      expect(item.key, 'milk');
      expect(c.read(fridgeProvider).basket, hasLength(basket + 1));
      expect(c.read(barcodeMemoryProvider).keys[milk], 'milk');
      expect(c.read(scanProvider).phase, ScanPhase.scanning);

      // Second scan: known, no network.
      await ctrl.onBarcode(milk);
      expect(lookup.calls, 1);
      expect(c.read(scanProvider).knownKey, 'milk');
    });

    test('codes seen while one is being handled are ignored', () async {
      final lookup = FakeLookup();
      final c = make(lookup: lookup);
      final ctrl = c.read(scanProvider.notifier);
      await ctrl.onBarcode(milk);
      await ctrl.onBarcode(egg);
      expect(lookup.calls, 1);
      expect(c.read(scanProvider).barcode, milk);
    });

    test('remembered barcodes come back from storage', () async {
      final c = make(
        saved: SavedData(
          barcodes: SavedBarcodes({egg: 'egg'}, firstScanOn: testToday),
        ),
      );
      await c.read(scanProvider.notifier).onBarcode(egg);
      expect(c.read(scanProvider).knownKey, 'egg');
    });

    test('first scan unlocks the first-scan badge', () async {
      final c = make();
      BadgeProgress first() => c
          .read(badgeProgressProvider)
          .firstWhere((b) => b.badgeId == BadgeIds.firstScan);
      expect(first().isUnlocked, isFalse);
      final ctrl = c.read(scanProvider.notifier);
      await ctrl.onBarcode(milk);
      ctrl.add('milk');
      expect(first().isUnlocked, isTrue);
      expect(first().unlockedOn, testToday);
    });

    test('barcode book survives a save and load', () {
      final saved = SavedBarcodes({milk: 'milk'}, firstScanOn: testToday);
      final back = SavedBarcodes.fromJson(saved.toJson());
      expect(back.keys, {milk: 'milk'});
      expect(back.firstScanOn, testToday);
    });
  });

  group('page', () {
    Future<FakeCamera> openScan(
      WidgetTester tester, {
      FakeLookup? lookup,
      double width = 390,
    }) async {
      setPhoneSize(tester, width, height: 844);
      final camera = FakeCamera();
      await tester.pumpWidget(
        testApp(initialLocation: '/scan', camera: camera, lookup: lookup),
      );
      await tester.pumpAndSettle();
      return camera;
    }

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(ScanPage)));

    testWidgets('unknown barcode: pick from the grid, toast, camera back', (
      tester,
    ) async {
      final camera = await openScan(
        tester,
        lookup: FakeLookup({
          milk: const ProductFound(name: 'นมสด', brand: 'Meiji'),
        }),
      );
      expect(camera.active, isTrue);

      camera.see(milk);
      await tester.pumpAndSettle();
      expect(find.text('นมสด'), findsOneWidget);
      expect(find.text('Meiji'), findsOneWidget);
      expect(camera.active, isFalse);

      await tester.tap(find.byKey(const ValueKey('add-milk')));
      await tester.pumpAndSettle();
      final name = testCatalog['milk']!.name;
      expect(find.text(S.scanAdded(name)), findsOneWidget);
      expect(
        containerOf(tester).read(barcodeMemoryProvider).keys[milk],
        'milk',
      );
      expect(camera.active, isTrue);
    });

    testWidgets('known barcode: one button adds it', (tester) async {
      final lookup = FakeLookup();
      final camera = await openScan(tester, lookup: lookup);
      containerOf(tester)
          .read(barcodeMemoryProvider.notifier)
          .remember(egg, 'egg');

      camera.see(egg);
      await tester.pumpAndSettle();
      expect(find.text(S.scanKnown), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scan-add-known')));
      await tester.pumpAndSettle();
      expect(lookup.calls, 0);
      expect(containerOf(tester).read(fridgeProvider).basket.last.key, 'egg');
    });

    testWidgets('closing the sheet without adding goes back to scanning', (
      tester,
    ) async {
      final camera = await openScan(tester);
      camera.see(milk);
      await tester.pumpAndSettle();
      expect(find.text(S.scanNotFound), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(containerOf(tester).read(scanProvider).phase, ScanPhase.scanning);
      expect(camera.active, isTrue);
    });

    testWidgets('camera stops when another tab is shown', (tester) async {
      final camera = await openScan(tester);
      expect(camera.active, isTrue);
      await tester.tap(find.bySemanticsLabel(S.tabFridge));
      await tester.pumpAndSettle();
      expect(camera.active, isFalse);
    });

    testWidgets('no barcode: add by hand opens the add sheet', (tester) async {
      await openScan(tester);
      await tester.tap(find.byKey(const ValueKey('scan-add-by-hand')));
      await tester.pumpAndSettle();
      expect(find.text(S.addItemTitle), findsOneWidget);
    });

    for (final width in [360.0, 430.0]) {
      testWidgets('scan tab and sheet fit at ${width.toInt()}', (tester) async {
        final camera = await openScan(tester, width: width);
        expect(tester.takeException(), isNull);
        camera.see(milk);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
