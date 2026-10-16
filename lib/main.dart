import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'features/fridge/data/ingredient_catalog.dart';
import 'features/random/data/eat_out_menu.dart';
import 'features/random/domain/random_controller.dart';
import 'shared/data/recipe_book.dart';
import 'shared/persistence/app_store.dart';
import 'shared/widgets/ingredient_tile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catalog = IngredientCatalog.fromJsonString(
    await rootBundle.loadString(IngredientCatalog.assetPath),
  );
  final recipes = RecipeBook.fromJsonString(
    await rootBundle.loadString(RecipeBook.assetPath),
  );
  final eatOut = EatOutMenu.fromJsonString(
    await rootBundle.loadString(EatOutMenu.assetPath),
  );
  // Everything the user has entered lives on this device only (ADR-007,
  // ADR-009); read it before the first frame so nothing flickers.
  final store = AppStore(PrefsStore());
  final saved = await store.load();
  // Parse ingredient art up front so the first fridge visit does not stall
  // the tab transition while SVGs decode.
  await Future.wait([
    for (final key in ingredientArtKeys)
      SvgAssetLoader('assets/ingredients/$key.svg').loadBytes(null),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        catalogProvider.overrideWithValue(catalog),
        recipeBookProvider.overrideWithValue(recipes),
        eatOutMenuProvider.overrideWithValue(eatOut),
        appStoreProvider.overrideWithValue(store),
        savedDataProvider.overrideWithValue(saved),
      ],
      child: _FlushOnPause(store: store, child: const RecipixApp()),
    ),
  );
}

/// Writes are already queued on every change; this makes sure the last
/// burst reaches storage when the app goes to the background.
class _FlushOnPause extends StatefulWidget {
  const _FlushOnPause({required this.store, required this.child});

  final AppStore store;
  final Widget child;

  @override
  State<_FlushOnPause> createState() => _FlushOnPauseState();
}

class _FlushOnPauseState extends State<_FlushOnPause> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onPause: widget.store.flush,
      onHide: widget.store.flush,
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
