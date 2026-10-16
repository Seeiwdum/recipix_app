import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../../../shared/widgets/pressable.dart';
import '../data/ingredient_catalog.dart';

/// Every catalog ingredient as a tap-to-pick grid, grouped by category.
/// Used by "add by hand" (ADR-013) and by the barcode result (ADR-014).
/// Scrolls on its own; give it bounded height.
class CatalogGrid extends ConsumerWidget {
  const CatalogGrid({super.key, required this.onPick});

  final ValueChanged<CatalogEntry> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(catalogProvider).entries.toList()
      ..sort((a, b) {
        final c = a.category.index.compareTo(b.category.index);
        return c != 0 ? c : a.name.compareTo(b.name);
      });
    return LayoutBuilder(
      builder: (context, c) {
        const gap = RecipixTokens.space2;
        final cols = c.maxWidth >= 400 ? 5 : 4;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return SingleChildScrollView(
          child: Wrap(
            spacing: gap,
            runSpacing: RecipixTokens.space3,
            children: [
              for (final e in entries)
                SizedBox(
                  width: w,
                  child: _Choice(entry: e, onTap: () => onPick(e)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.entry, required this.onTap});

  final CatalogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      key: ValueKey('add-${entry.key}'),
      semanticLabel: S.addSemantics(entry.name),
      onTap: onTap,
      child: Column(
        children: [
          IngredientTile(ingredientKey: entry.key, name: entry.name, size: 56),
          const SizedBox(height: RecipixTokens.space1),
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: t.caption.copyWith(color: t.ink),
          ),
          Text(
            S.keepsFor(entry.shelfLifeDays),
            maxLines: 1,
            textAlign: TextAlign.center,
            style: t.micro,
          ),
        ],
      ),
    );
  }
}
