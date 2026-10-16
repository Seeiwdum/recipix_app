import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../../../shared/widgets/pressable.dart';
import '../data/ingredient_catalog.dart';
import '../domain/fridge_controller.dart';

/// Pick what was bought; each tap drops one into the basket (ADR-013).
/// Putting it on a shelf stays the fridge game's job.
Future<void> showAddItemSheet(BuildContext context) {
  final t = context.tokens;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.surface,
    elevation: 0,
    showDragHandle: true,
    isScrollControlled: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: RecipixTokens.slow,
      curve: RecipixTokens.enter,
      reverseDuration: RecipixTokens.medium,
      reverseCurve: RecipixTokens.exit,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(RecipixTokens.radiusLg),
      ),
    ),
    builder: (_) => const _AddItemSheet(),
  );
}

class _AddItemSheet extends ConsumerStatefulWidget {
  const _AddItemSheet();

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  IngredientItem? _last;
  int _count = 0;

  void _add(CatalogEntry entry) {
    final item = ref.read(fridgeProvider.notifier).addFromCatalog(entry.key);
    if (item == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _last = item;
      _count++;
    });
  }

  void _takeBack() {
    final last = _last;
    if (last == null) return;
    ref.read(fridgeProvider.notifier).removeAdded(last.id);
    setState(() {
      _last = null;
      _count--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final entries = ref.watch(catalogProvider).entries.toList()
      ..sort((a, b) {
        final c = a.category.index.compareTo(b.category.index);
        return c != 0 ? c : a.name.compareTo(b.name);
      });
    final last = _last;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RecipixTokens.space3,
          0,
          RecipixTokens.space3,
          RecipixTokens.space3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(S.addItemTitle, style: t.title),
                  ),
                ),
                TextButton(
                  key: const ValueKey('add-done'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(S.doneAdding),
                ),
              ],
            ),
            Text(S.addItemHint, style: t.caption),
            const SizedBox(height: RecipixTokens.space2),
            // Fixed height so the grid does not jump when a line appears.
            SizedBox(
              height: RecipixTokens.tapTarget,
              child: last == null
                  ? null
                  : Row(
                      key: const ValueKey('added-line'),
                      children: [
                        Expanded(
                          child: Text(
                            S.addedLine(last.name, _count),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.body.copyWith(color: t.accent),
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('remove-added'),
                          onPressed: _takeBack,
                          child: Text(S.removeAdded),
                        ),
                      ],
                    ),
            ),
            Flexible(
              child: LayoutBuilder(
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
                            child: _Choice(entry: e, onTap: () => _add(e)),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
