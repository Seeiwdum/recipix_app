import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/toast.dart';
import '../../budget/domain/budget_controller.dart';
import '../../fridge/domain/fridge_controller.dart';
import '../data/eat_out_menu.dart';

Future<void> _sheet(BuildContext context, WidgetBuilder builder) {
  final t = context.tokens;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
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
    builder: builder,
  );
}

FilledButton _primary(BuildContext context, String label, VoidCallback? onTap) {
  final t = context.tokens;
  return FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: t.accent,
      foregroundColor: t.onAccent,
      textStyle: t.label,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
      ),
    ),
    onPressed: onTap,
    child: Text(label),
  );
}

/// Cook-mode result: match %, what you have and what is missing. A full
/// match shows only the quiet "ครบทุกอย่าง" label — no fireworks — and
/// can be cooked straight away.
Future<void> showCookResultSheet(BuildContext context, SlotSpinResult result) =>
    _sheet(context, (_) => _CookResult(result: result, hostContext: context));

class _CookResult extends ConsumerStatefulWidget {
  const _CookResult({required this.result, required this.hostContext});

  final SlotSpinResult result;
  final BuildContext hostContext;

  @override
  ConsumerState<_CookResult> createState() => _CookResultState();
}

class _CookResultState extends ConsumerState<_CookResult> {
  late RecipeMatch? _match = widget.result.bestMatch;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final catalog = ref.watch(catalogProvider);
    final match = _match;
    final others = [
      ?widget.result.bestMatch,
      ...widget.result.alternatives,
    ].where((m) => !identical(m, match)).toList();

    String name(String key) => catalog[key]?.name ?? key;

    void cook() {
      final recipe = match!.recipe;
      Navigator.of(context).pop();
      final ctrl = ref.read(fridgeProvider.notifier);
      if (ctrl.cook(recipe) == null) {
        showUndoToast(widget.hostContext, S.cookMissing);
        return;
      }
      HapticFeedback.lightImpact();
      showUndoToast(
        widget.hostContext,
        S.toastCooked(recipe.name),
        onUndo: ctrl.undoCook,
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          RecipixTokens.space3,
          0,
          RecipixTokens.space3,
          RecipixTokens.space3,
        ),
        child: match == null
            ? Text(S.noMatch, style: t.body)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(match.recipe.name, style: t.title)),
                      const SizedBox(width: RecipixTokens.space2),
                      _MatchLabel(match: match),
                    ],
                  ),
                  Text(
                    '${S.minutes(match.recipe.cookMinutes)} · '
                    '${S.kcal(match.recipe.kcalPerServing.round())}',
                    style: t.caption,
                  ),
                  const SizedBox(height: RecipixTokens.space3),
                  Text(S.haveTitle, style: t.label.copyWith(color: t.ink2)),
                  const SizedBox(height: RecipixTokens.space1),
                  Wrap(
                    spacing: RecipixTokens.space2,
                    runSpacing: RecipixTokens.space2,
                    children: [
                      for (final k in match.haveKeys)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IngredientTile(
                              ingredientKey: k,
                              name: name(k),
                              size: RecipixTokens.space6,
                            ),
                            Text(name(k), style: t.caption),
                          ],
                        ),
                    ],
                  ),
                  if (match.missingKeys.isNotEmpty) ...[
                    const SizedBox(height: RecipixTokens.space3),
                    Text(
                      S.missingTitle,
                      style: t.label.copyWith(color: t.ink2),
                    ),
                    Text(match.missingKeys.map(name).join(', '), style: t.body),
                  ],
                  if (match.isJackpot) ...[
                    const SizedBox(height: RecipixTokens.space3),
                    SizedBox(
                      height: RecipixTokens.tapTarget,
                      child: _primary(context, S.cookThis, cook),
                    ),
                  ],
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: RecipixTokens.space3),
                    Text(
                      S.otherMatches,
                      style: t.label.copyWith(color: t.ink2),
                    ),
                    for (final m in others)
                      Pressable(
                        semanticLabel: m.recipe.name,
                        onTap: () => setState(() => _match = m),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: RecipixTokens.tapTarget,
                          ),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: t.line)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(m.recipe.name, style: t.body),
                              ),
                              _MatchLabel(match: m),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _MatchLabel extends StatelessWidget {
  const _MatchLabel({required this.match});

  final RecipeMatch match;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final full = match.isJackpot;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: RecipixTokens.space2),
      decoration: BoxDecoration(
        border: Border.all(color: full ? t.accent : t.line),
        borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
      ),
      child: Text(
        full ? S.menuFull : S.matchPercent(match.matchPercentage),
        style: t.label.copyWith(
          color: full ? t.accent : t.ink2,
          fontFeatures: RecipixTokens.tabularFigures,
        ),
      ),
    );
  }
}

/// Eat-out result: the dish, its price, what that leaves of today's
/// budget; one tap logs it as today's spending.
Future<void> showEatOutResultSheet(
  BuildContext context,
  EatOutDish dish, {
  required bool overBudget,
}) => _sheet(
  context,
  (_) =>
      _EatOutResult(dish: dish, overBudget: overBudget, hostContext: context),
);

class _EatOutResult extends ConsumerWidget {
  const _EatOutResult({
    required this.dish,
    required this.overBudget,
    required this.hostContext,
  });

  final EatOutDish dish;
  final bool overBudget;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final left = ref.watch(ledgerProvider).leftToday - dish.price;
    final price = formatBaht(dish.price);

    void eat() {
      Navigator.of(context).pop();
      final ctrl = ref.read(budgetProvider.notifier);
      final entry = ctrl.add(dish.price, SpendCategory.eatOut);
      showUndoToast(
        hostContext,
        S.spendSaved(price),
        onUndo: () => ctrl.remove(entry.id),
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
            Text(dish.name, style: t.title),
            Text(S.priceBaht(price), style: t.number.copyWith(fontSize: 16)),
            const SizedBox(height: RecipixTokens.space2),
            if (overBudget)
              Text(S.nothingFits, style: t.caption.copyWith(color: t.warnText)),
            Text(
              left.isNegative
                  ? S.overAfter(
                      formatBahtWhole(Money.zero - left, roundUp: true),
                    )
                  : S.leftAfter(formatBahtWhole(left, roundUp: false)),
              style: t.label.copyWith(
                color: left.isNegative ? t.urgent : t.ink2,
              ),
            ),
            const SizedBox(height: RecipixTokens.space3),
            SizedBox(
              height: RecipixTokens.tapTarget,
              child: _primary(context, S.eatThis(price), eat),
            ),
          ],
        ),
      ),
    );
  }
}
