import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../../../shared/widgets/toast.dart';
import '../../fridge/data/ingredient_catalog.dart';
import '../../fridge/presentation/catalog_grid.dart';
import '../data/product_lookup.dart';
import '../domain/scan_controller.dart';

/// What the scanned barcode is. Known barcode: one button to add it.
/// Otherwise: the product name if the database had one, and the catalog
/// to pick from (the choice is remembered).
Future<void> showScanResultSheet(BuildContext context) {
  final t = context.tokens;
  final container = ProviderScope.containerOf(context);
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
    builder: (_) => _ScanResultSheet(hostContext: context),
  ).whenComplete(() {
    // Closed without adding (drag down, tap outside): back to the camera.
    if (container.read(scanProvider).phase == ScanPhase.picked) {
      container.read(scanProvider.notifier).dismiss();
    }
  });
}

class _ScanResultSheet extends ConsumerStatefulWidget {
  const _ScanResultSheet({required this.hostContext});

  /// The page's context, which outlives the sheet (for the toast).
  final BuildContext hostContext;

  @override
  ConsumerState<_ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends ConsumerState<_ScanResultSheet> {
  bool _choosing = false;

  void _add(CatalogEntry entry) {
    final item = ref.read(scanProvider.notifier).add(entry.key);
    Navigator.of(context).pop();
    if (item != null) {
      showUndoToast(widget.hostContext, S.scanAdded(item.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scan = ref.watch(scanProvider);
    final catalog = ref.watch(catalogProvider);
    final known = scan.knownKey == null ? null : catalog[scan.knownKey!];
    final lookup = scan.lookup;

    final (headline, sub) = switch (lookup) {
      _ when known != null => (known.name, S.scanKnown),
      ProductFound(:final name, :final brand) when name.isNotEmpty => (
        name,
        brand,
      ),
      ProductFound() => (S.scanNoName, null),
      ProductNotFound() => (S.scanNotFound, null),
      LookupFailed() || null => (S.scanOffline, null),
    };

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
            Semantics(
              header: true,
              child: Text(
                headline,
                key: const ValueKey('scan-headline'),
                style: t.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sub != null) Text(sub, style: t.caption),
            Text(S.scanBarcode(scan.barcode ?? ''), style: t.micro),
            const SizedBox(height: RecipixTokens.space3),
            if (known != null && !_choosing) ...[
              Center(
                child: IngredientTile(
                  ingredientKey: known.key,
                  name: known.name,
                  size: 72,
                ),
              ),
              const SizedBox(height: RecipixTokens.space3),
              SizedBox(
                height: RecipixTokens.tapTarget,
                child: FilledButton(
                  key: const ValueKey('scan-add-known'),
                  onPressed: () => _add(known),
                  child: Text(S.scanAddKnown(known.name)),
                ),
              ),
              TextButton(
                key: const ValueKey('scan-pick-other'),
                onPressed: () => setState(() => _choosing = true),
                child: Text(S.scanPickOther),
              ),
            ] else ...[
              Text(S.scanPickHint, style: t.bodyMuted),
              const SizedBox(height: RecipixTokens.space2),
              Flexible(child: CatalogGrid(onPick: _add)),
            ],
          ],
        ),
      ),
    );
  }
}
