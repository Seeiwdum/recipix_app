import 'package:flutter/widgets.dart';

import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../../../shared/widgets/recipix_page.dart';

/// Placeholder until the tab is built in Phase 2. Shows the ingredient art
/// set so it can be reviewed in the running app.
class FridgePage extends StatelessWidget {
  const FridgePage({super.key});

  @override
  Widget build(BuildContext context) => RecipixPage(
    title: S.fridgeTitle,
    children: [
      const ComingSoonNote(
        status: S.underConstruction,
        text: S.fridgeComingSoon,
      ),
      const SizedBox(height: RecipixTokens.space4),
      Wrap(
        spacing: RecipixTokens.space2,
        runSpacing: RecipixTokens.space2,
        children: [
          for (final key in ingredientArtKeys)
            IngredientTile(ingredientKey: key, name: key, size: 56),
          const IngredientTile(
            ingredientKey: 'garlic',
            name: S.sampleGarlic,
            size: 56,
          ),
          const IngredientTile(
            ingredientKey: 'egg',
            name: 'egg',
            size: 56,
            faded: true,
          ),
          const IngredientTile(
            ingredientKey: null,
            name: S.mysteryItem,
            size: 56,
          ),
        ],
      ),
    ],
  );
}
