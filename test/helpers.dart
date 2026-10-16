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

/// The whole app with test data and a fixed day.
Widget testApp({String initialLocation = '/home'}) => ProviderScope(
  overrides: [
    catalogProvider.overrideWithValue(testCatalog),
    recipeBookProvider.overrideWithValue(testRecipes),
    eatOutMenuProvider.overrideWithValue(testEatOut),
    randomSourceProvider.overrideWithValue(Random(7)),
    todayProvider.overrideWithValue(testToday),
  ],
  child: RecipixApp(initialLocation: initialLocation),
);
