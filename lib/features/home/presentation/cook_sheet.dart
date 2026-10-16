import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../../../shared/widgets/toast.dart';
import '../../fridge/domain/fridge_controller.dart';

/// Shows what a planned dish takes from the fridge; "ทำแล้ว" deducts it.
Future<void> showCookSheet(BuildContext context, PlannedMeal meal) {
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
    builder: (_) => _CookSheet(meal: meal, hostContext: context),
  );
}

class _CookSheet extends ConsumerWidget {
  const _CookSheet({required this.meal, required this.hostContext});

  final PlannedMeal meal;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final recipe = meal.recipe!;

    void cook() {
      Navigator.of(context).pop();
      final ctrl = ref.read(fridgeProvider.notifier);
      if (ctrl.cook(recipe) == null) {
        showUndoToast(hostContext, S.cookMissing);
        return;
      }
      HapticFeedback.lightImpact();
      showUndoToast(
        hostContext,
        S.toastCooked(recipe.name),
        onUndo: ctrl.undoCook,
      );
    }

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
            Text(recipe.name, style: t.title),
            Text(
              '${S.minutes(recipe.cookMinutes)} · '
              '${S.kcal(recipe.kcalPerServing.round())}',
              style: t.caption,
            ),
            const SizedBox(height: RecipixTokens.space3),
            Text(S.cookUses, style: t.label.copyWith(color: t.ink2)),
            for (final p in meal.uses)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: RecipixTokens.space2,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.line)),
                ),
                child: Row(
                  children: [
                    IngredientTile(
                      ingredientKey: p.item.key,
                      name: p.item.name,
                      size: RecipixTokens.space5,
                    ),
                    const SizedBox(width: RecipixTokens.space2),
                    Expanded(child: Text(p.item.name, style: t.body)),
                    Text(formatQuantity(p.amount), style: t.number),
                  ],
                ),
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
                onPressed: cook,
                child: const Text(S.cookDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
