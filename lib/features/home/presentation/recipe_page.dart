import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/icons/recipix_icon.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../../../shared/widgets/ledger.dart';
import '../../../shared/widgets/toast.dart';
import '../../dashboard/domain/dashboard_providers.dart';
import '../../fridge/domain/fridge_controller.dart';
import '../domain/home_providers.dart';

/// One dish (ADR-015): what goes in (and what is on hand), how to make
/// it, how hard it is, and which badges cooking it now moves. One primary
/// action, "cook this", only when everything required is in the fridge.
class RecipePage extends ConsumerWidget {
  const RecipePage({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final detail = ref.watch(recipeDetailProvider(recipeId));

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              RecipixTokens.space1,
              RecipixTokens.space1,
              RecipixTokens.space3,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('recipe-back'),
                    tooltip: S.back,
                    constraints: const BoxConstraints.tightFor(
                      width: RecipixTokens.tapTarget,
                      height: RecipixTokens.tapTarget,
                    ),
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    icon: RecipixIcon(RecipixIcons.chevronLeft, color: t.ink),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              RecipixTokens.space3,
              0,
              RecipixTokens.space3,
              RecipixTokens.space5,
            ),
            sliver: detail == null
                ? SliverToBoxAdapter(
                    child: Text(S.recipeNotFound, style: t.bodyMuted),
                  )
                : SliverList.list(children: _body(context, ref, detail)),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context, WidgetRef ref, RecipeDetail d) {
    final t = context.tokens;
    final r = d.recipe;
    final match = d.match;
    return [
      Semantics(header: true, child: Text(r.name, style: t.pageTitle)),
      Text(
        '${S.minutes(r.cookMinutes)} · ${S.kcal(r.kcalPerServing.round())} · '
        '${S.difficulty(r.difficulty.name)}',
        key: const ValueKey('recipe-meta'),
        style: t.caption,
      ),
      const SizedBox(height: RecipixTokens.space3),
      _CookAction(detail: d),
      const SizedBox(height: RecipixTokens.space4),
      _Title(S.recipeIngredients),
      for (final i in r.ingredients)
        _IngredientLine(
          ingredient: i,
          have: match.haveKeys.contains(i.key),
          missing: match.missingKeys.contains(i.key),
        ),
      const SizedBox(height: RecipixTokens.space4),
      _Title(S.recipeSteps),
      if (r.steps.isEmpty)
        Text(S.recipeNoSteps, style: t.bodyMuted)
      else
        for (final (i, step) in r.steps.indexed)
          _StepLine(n: i + 1, text: step),
      const SizedBox(height: RecipixTokens.space4),
      _Title(S.recipeBadges),
      _BadgeGains(gains: d.badgeGains),
    ];
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: RecipixTokens.space1),
    child: Semantics(
      header: true,
      child: Text(text, style: context.tokens.title),
    ),
  );
}

/// Cook now when everything required is on hand; otherwise say how many
/// things are missing (they are marked in the list below).
class _CookAction extends ConsumerWidget {
  const _CookAction({required this.detail});

  final RecipeDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final match = detail.match;
    if (!match.isJackpot) {
      return Text(
        S.recipeNeed(match.missingKeys.length),
        key: const ValueKey('recipe-need'),
        style: t.body.copyWith(color: t.ink2),
      );
    }
    final recipe = detail.recipe;
    return SizedBox(
      width: double.infinity,
      height: RecipixTokens.tapTarget,
      child: FilledButton(
        key: const ValueKey('recipe-cook'),
        onPressed: () {
          final ctrl = ref.read(fridgeProvider.notifier);
          if (ctrl.cook(recipe) == null) {
            showUndoToast(context, S.cookMissing);
            return;
          }
          HapticFeedback.lightImpact();
          showUndoToast(
            context,
            S.toastCooked(recipe.name),
            onUndo: ctrl.undoCook,
          );
        },
        child: Text(S.cookThis),
      ),
    );
  }
}

/// Ingredient ··· amount, and whether it is on hand.
class _IngredientLine extends ConsumerWidget {
  const _IngredientLine({
    required this.ingredient,
    required this.have,
    required this.missing,
  });

  final RecipeIngredient ingredient;
  final bool have;
  final bool missing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final name =
        ref.watch(catalogProvider)[ingredient.key]?.name ?? ingredient.key;
    final status = have
        ? S.recipeHave
        : missing
        ? S.recipeMissing
        : S.recipeOptional;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RecipixTokens.space1),
      child: Row(
        children: [
          IngredientTile(
            ingredientKey: ingredient.key,
            name: name,
            size: 32,
            faded: !have,
          ),
          const SizedBox(width: RecipixTokens.space2),
          Expanded(
            child: LedgerRow(
              key: ValueKey('ingredient-${ingredient.key}'),
              label: name,
              value: Text(
                '${formatQuantity(ingredient.quantity)} · $status',
                style: t.caption.copyWith(
                  color: have
                      ? t.accent
                      : missing
                      ? t.warnText
                      : t.ink2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.n, required this.text});

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RecipixTokens.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: RecipixTokens.space4,
            child: Text(
              S.stepNumber(n),
              style: t.label.copyWith(
                color: t.ink2,
                fontFeatures: RecipixTokens.tabularFigures,
              ),
            ),
          ),
          Expanded(child: Text(text, style: t.body)),
        ],
      ),
    );
  }
}

/// Badge name ··· "+1 · 4/10" (or "ได้เหรียญนี้" when this cook earns it).
class _BadgeGains extends ConsumerWidget {
  const _BadgeGains({required this.gains});

  final Map<String, int> gains;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final progress = {
      for (final p in ref.watch(badgeProgressProvider)) p.badgeId: p,
    };
    return Column(
      children: [
        for (final MapEntry(key: id, value: n) in gains.entries)
          if (progress[id] case final p?)
            LedgerRow(
              key: ValueKey('gain-$id'),
              label: S.badgeNames[id] ?? id,
              ruled: true,
              value: Text(
                p.isUnlocked
                    ? S.badgeGainDone(n)
                    : p.current + n >= p.target
                    ? S.badgeUnlocksNow(n)
                    : S.badgeGain(n, p.current, p.target),
                style: t.number.copyWith(
                  color: !p.isUnlocked && p.current + n >= p.target
                      ? t.accent
                      : t.ink,
                ),
              ),
            ),
      ],
    );
  }
}
