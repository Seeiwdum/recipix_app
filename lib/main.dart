import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'features/fridge/data/ingredient_catalog.dart';
import 'shared/widgets/ingredient_tile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catalog = IngredientCatalog.fromJsonString(
    await rootBundle.loadString(IngredientCatalog.assetPath),
  );
  // Parse ingredient art up front so the first fridge visit does not stall
  // the tab transition while SVGs decode.
  await Future.wait([
    for (final key in ingredientArtKeys)
      SvgAssetLoader('assets/ingredients/$key.svg').loadBytes(null),
  ]);

  runApp(
    ProviderScope(
      overrides: [catalogProvider.overrideWithValue(catalog)],
      child: const RecipixApp(),
    ),
  );
}
