import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/freshness_color.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../domain/fridge_controller.dart';

/// Detail sheet for one item. One primary action: "used" for items on a
/// shelf, "put it away for me" for items still in the basket.
Future<void> showItemSheet(
  BuildContext context,
  WidgetRef ref,
  IngredientItem item,
) {
  final t = context.tokens;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.surface,
    elevation: 0,
    showDragHandle: true,
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
    builder: (sheetContext) => _ItemSheet(item: item, hostContext: context),
  );
}

class _ItemSheet extends ConsumerWidget {
  const _ItemSheet({required this.item, required this.hostContext});

  final IngredientItem item;

  /// The page's context, which outlives the sheet (for the toast).
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final today = ref.watch(todayProvider);
    final state = ref.watch(fridgeProvider);
    final ctrl = ref.read(fridgeProvider.notifier);
    final placement = state.arrangement.placements[item.id];
    final days = item.daysUntilExpiry(today);
    final kcal = item.totalKcal.round();

    void close() => Navigator.of(context).pop();

    void remove(RemovalKind kind) {
      close();
      if (kind == RemovalKind.used) {
        ctrl.use(item.id);
      } else {
        ctrl.discard(item.id);
      }
      showUndoToast(
        hostContext,
        kind == RemovalKind.used
            ? S.toastUsed(item.name)
            : S.toastDiscarded(item.name),
        onUndo: ctrl.undo,
      );
    }

    // Same scale as every other screen (ADR-012): red only expired/today.
    final expiryColor = freshnessColor(t, days) ?? t.ink;

    return SafeArea(
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
                IngredientTile(
                  ingredientKey: item.key,
                  name: item.name,
                  size: RecipixTokens.space6 + RecipixTokens.space2,
                ),
                const SizedBox(width: RecipixTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: t.title),
                      Text(formatQuantity(item.quantity), style: t.bodyMuted),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: RecipixTokens.space3),
            _InfoRow(
              label: S.sheetExpiry,
              value: S.expiryLine(formatThaiDate(item.expiresOn), days),
              valueColor: expiryColor,
            ),
            _InfoRow(
              label: S.sheetEnergy,
              value: item.isIdentified ? S.kcal(kcal) : S.kcalEstimate(kcal),
            ),
            _InfoRow(
              label: S.sheetPlace,
              value: placement == null
                  ? S.inBasket
                  : S.compartmentNames[placement.slot.compartment.name]!,
            ),
            const SizedBox(height: RecipixTokens.space3),
            SizedBox(
              height: RecipixTokens.tapTarget,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.onAccent,
                  textStyle: t.label,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
                  ),
                ),
                onPressed: placement != null
                    ? () => remove(RemovalKind.used)
                    : () {
                        close();
                        if (ctrl.autoPlace(item.id) == null) {
                          showUndoToast(hostContext, S.fridgeFull);
                        }
                      },
                child: Text(
                  placement != null ? S.actionUse : S.actionAutoPlace,
                ),
              ),
            ),
            const SizedBox(height: RecipixTokens.space1),
            Row(
              children: [
                if (placement != null)
                  Expanded(
                    child: _QuietButton(
                      label: S.actionToBasket,
                      color: t.ink,
                      onTap: () {
                        close();
                        ctrl.moveToBasket(item.id);
                      },
                    ),
                  ),
                Expanded(
                  child: _QuietButton(
                    label: S.actionDiscard,
                    color: t.urgent,
                    onTap: () => remove(RemovalKind.discarded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: RecipixTokens.space2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: RecipixTokens.space6 * 2,
            child: Text(label, style: t.bodyMuted),
          ),
          Expanded(
            child: Text(
              value,
              style: t.body.copyWith(
                color: valueColor,
                fontFeatures: RecipixTokens.tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: RecipixTokens.tapTarget,
    child: TextButton(
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: context.tokens.label,
      ),
      onPressed: onTap,
      child: Text(label),
    ),
  );
}
