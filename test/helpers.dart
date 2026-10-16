import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/app.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/features/fridge/data/ingredient_catalog.dart';
import 'package:recipix_app/shared/data/recipe_book.dart';
import 'package:recipix_app/features/random/data/eat_out_menu.dart';
import 'package:recipix_app/features/random/domain/random_controller.dart';
import 'package:recipix_app/features/scan/data/object_finder.dart';
import 'package:recipix_app/features/scan/data/product_lookup.dart';
import 'package:recipix_app/features/scan/presentation/photo_camera.dart';
import 'package:recipix_app/features/scan/presentation/scan_camera.dart';
import 'package:recipix_app/shared/persistence/app_store.dart';
import 'package:recipix_app/shared/persistence/codecs.dart';
import 'package:recipix_core/recipix_core.dart';

/// Fixed day so freshness labels and goldens never drift.
final testToday = LocalDate(2026, 10, 16);

final testCatalog = IngredientCatalog.fromJsonString(
  File(IngredientCatalog.assetPath).readAsStringSync(),
);

final testRecipes = RecipeBook.fromJsonString(
  File(RecipeBook.assetPath).readAsStringSync(),
);

final testEatOut = EatOutMenu.fromJsonString(
  File(EatOutMenu.assetPath).readAsStringSync(),
);

/// Loads the bundled Thai font so goldens show real glyphs instead of the
/// test font's boxes.
Future<void> loadAppFonts() async {
  final loader = FontLoader('IBMPlexSansThai');
  for (final weight in ['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/IBMPlexSansThai-$weight.ttf')
        .readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Sets a phone-sized logical viewport for the current test.
void setPhoneSize(WidgetTester tester, double width, {double height = 800}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The whole app with test data and a fixed day. No real camera and no
/// network: the scan tab gets [camera] and [lookup] (fresh fakes by
/// default).
Widget testApp({
  String initialLocation = '/home',
  FakeCamera? camera,
  ProductLookup? lookup,
  FakeFinder? finder,
  bool onboarded = true,
}) => ProviderScope(
  overrides: [
    // Already through the first-launch questions unless a test is about
    // them (ADR-017).
    if (onboarded)
      savedDataProvider.overrideWithValue(
        SavedData(
          profile: SavedProfile(
            name: 'เอ',
            favoriteRecipeIds: const [],
            completedOn: testToday,
          ),
        ),
      ),
    catalogProvider.overrideWithValue(testCatalog),
    recipeBookProvider.overrideWithValue(testRecipes),
    eatOutMenuProvider.overrideWithValue(testEatOut),
    randomSourceProvider.overrideWithValue(Random(7)),
    todayProvider.overrideWithValue(testToday),
    scanCameraProvider.overrideWithValue((camera ?? FakeCamera()).build),
    productLookupProvider.overrideWithValue(lookup ?? FakeLookup()),
    photoCameraProvider.overrideWithValue(fakePhotoCamera),
    photoImageProvider.overrideWithValue(
      (path) => SizedBox.expand(key: ValueKey('photo-$path')),
    ),
    objectFinderProvider.overrideWithValue(finder ?? FakeFinder()),
  ],
  child: RecipixApp(initialLocation: initialLocation),
);

/// Stands in for the camera: tests call [see] to "show" it a barcode.
final class FakeCamera {
  ValueChanged<String>? _onCode;

  /// Whether the page currently wants the camera running.
  bool active = false;

  Widget build(
    BuildContext context, {
    required bool active,
    required ValueChanged<String> onCode,
  }) {
    this.active = active;
    _onCode = onCode;
    return const SizedBox.expand(key: ValueKey('fake-camera'));
  }

  void see(String barcode) => _onCode!(barcode);
}

/// Photo camera stand-in: the real shutter widget, which "takes"
/// `fake.jpg` straight away. Shows whether it is active in its key.
Widget fakePhotoCamera(
  BuildContext context, {
  required bool active,
  required ValueChanged<String> onCaptured,
}) => Stack(
  key: ValueKey('fake-photo-camera-$active'),
  children: [
    Align(
      alignment: Alignment.bottomCenter,
      child: ShutterButton(onTap: () => onCaptured('fake.jpg')),
    ),
  ],
);

/// Finds [boxes] in any photo (null = this device cannot look).
final class FakeFinder implements ObjectFinder {
  FakeFinder([this.boxes = const [Rect.fromLTRB(0.1, 0.1, 0.4, 0.5)]]);

  final List<Rect>? boxes;

  @override
  Future<PhotoFindings?> find(String imagePath) async => boxes == null
      ? null
      : PhotoFindings(imageSize: const Size(300, 400), boxes: boxes!);
}

/// Answers lookups from [results] (unknown barcodes: not found) and counts
/// the calls.
final class FakeLookup implements ProductLookup {
  FakeLookup([this.results = const {}]);

  final Map<String, LookupResult> results;
  int calls = 0;

  @override
  Future<LookupResult> find(String barcode) async {
    calls++;
    return results[barcode] ?? const ProductNotFound();
  }
}

/// The random tab waits a beat with all reels in view before the result
/// sheet opens. That pause is a plain timer, which pumpAndSettle does not
/// wait for, so step past it explicitly.
Future<void> settleSpin(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}
