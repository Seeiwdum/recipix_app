import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/icons/recipix_icon.dart';
import '../../../shared/motion/entrance.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/motion/motion.dart';
import '../../../shared/utils/freshness_color.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../../../shared/widgets/ledger.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/toast.dart';
import '../../budget/domain/budget_controller.dart';
import '../../budget/presentation/spending_sheet.dart';
import 'cook_sheet.dart';
import '../../fridge/domain/fridge_controller.dart';
import '../../fridge/presentation/item_sheet.dart';
import '../domain/home_providers.dart';

/// "Daily report": one headline number, a thin coverage line, money in
/// plain words, the items to use first, and at most one dish.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final today = ref.watch(todayProvider);
    final useFirst = ref.watch(useFirstProvider);
    final menus = ref.watch(menuSuggestionsProvider);
    final plan = ref.watch(mealPlanProvider);
    final next = plan.nextHomeMeal;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              RecipixTokens.space3,
              RecipixTokens.space3,
              RecipixTokens.space3,
              RecipixTokens.space3,
            ),
            sliver: SliverList.list(
              children: [
                Text(formatThaiDateLong(today), style: t.caption),
                Semantics(
                  header: true,
                  child: Text(S.homeTitle, style: t.pageTitle),
                ),
                const SizedBox(height: RecipixTokens.space3),
                const _ReportSheet(),
                const SizedBox(height: RecipixTokens.space4),
                if (menus.isNotEmpty) ...[
                  const _SectionHeader(
                    title: S.menuTitle,
                    trailing: S.menuHint,
                  ),
                  for (final (i, m) in menus.indexed)
                    _MenuRow(suggestion: m, first: i == 0),
                  const SizedBox(height: RecipixTokens.space4),
                ],
                _SectionHeader(
                  title: S.useFirstTitle,
                  trailing: useFirst.isEmpty ? null : S.useFirstHint,
                ),
              ],
            ),
          ),
          if (useFirst.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: RecipixTokens.space3,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(S.useFirstEmpty, style: t.bodyMuted),
              ),
            )
          else
            SliverList.builder(
              itemCount: useFirst.length,
              itemBuilder: (context, i) => Entrance(
                key: ValueKey('entrance-${useFirst[i].id}'),
                index: i,
                child: _UseFirstRow(item: useFirst[i], today: today),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              RecipixTokens.space3,
              RecipixTokens.space4,
              RecipixTokens.space3,
              RecipixTokens.space4,
            ),
            sliver: SliverList.list(
              children: [
                if (next != null) ...[
                  const _SectionHeader(title: S.nextMealTitle),
                  _NextMealRow(meal: next),
                  const SizedBox(height: RecipixTokens.space4),
                ],
                const SizedBox(height: RecipixTokens.space2),
                _QuietLink(
                  key: const ValueKey('open-plan'),
                  label: S.planTitle,
                  onTap: () => context.go('/home/plan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The daily report, laid out like a page in a kitchen account book
/// (ADR-012): one big number, no surrounding box, then read-out lines with
/// dot leaders. Both shortfalls are labelled with where they come from, so
/// "781" and "620" no longer look like a contradiction (critique: ฎา, วุฒิ).
class _ReportSheet extends ConsumerWidget {
  const _ReportSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final r = ref.watch(survivalReportProvider);
    final ledger = ref.watch(ledgerProvider);
    final plan = ref.watch(mealPlanProvider);
    final empty = ref.watch(fridgeProvider.select((s) => s.items.isEmpty));
    final reduce = reduceMotionOf(context);
    // Headline in meals, the same unit as the meal plan (founder decision
    // on L3 #2): the number is "meals I can cook from the fridge before
    // payday", so home and plan never disagree.
    final totalMeals = plan.meals.length;
    final coverage = totalMeals == 0
        ? 1.0
        : math.min(1.0, plan.homeMeals / totalMeals);

    Widget baht(Money m, {required bool roundUp}) =>
        Amount(formatBahtWhole(m, roundUp: roundUp), unit: S.bahtUnit);

    Widget shortfall(Money m) => m.isZero
        ? Text(S.enough, style: t.number.copyWith(color: t.accent))
        : baht(m, roundUp: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.planHomeLead, style: t.label.copyWith(color: t.ink2)),
        if (empty) ...[
          Text(S.fridgeEmptyHeadline, style: t.title),
          Text(S.fridgeEmptyHint, style: t.bodyMuted),
          // The way out of an empty fridge (5-second test: new users had
          // none).
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('go-add-items'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => context.go('/fridge'),
              child: Text(S.goAddItems),
            ),
          ),
        ] else ...[
          TweenAnimationBuilder<double>(
            key: const ValueKey('home-meals'),
            tween: Tween(begin: 0, end: plan.homeMeals.toDouble()),
            duration: reduce ? Duration.zero : RecipixTokens.countUp,
            curve: RecipixTokens.enter,
            builder: (context, v, _) => Semantics(
              label: '${plan.homeMeals} ${S.mealsUnit}',
              excludeSemantics: true,
              child: Amount(
                '${v.round()}',
                unit: S.mealsUnit,
                size: AmountSize.display,
              ),
            ),
          ),
          const SizedBox(height: RecipixTokens.space1),
          _ThinBar(fraction: coverage),
          const SizedBox(height: RecipixTokens.space1),
          Text(S.planOfTotal(totalMeals), style: t.caption),
        ],
        const SizedBox(height: RecipixTokens.space3),
        LedgerRow(
          label: S.allowanceLabel,
          value: baht(ledger.allowanceToday, roundUp: false),
          ruled: true,
        ),
        if (!ledger.spentToday.isZero)
          Padding(
            padding: const EdgeInsets.only(top: RecipixTokens.space1),
            child: Text(
              ledger.overToday
                  ? S.overToday(
                      formatBahtWhole(
                        Money.zero - ledger.leftToday,
                        roundUp: true,
                      ),
                    )
                  : S.spentToday(
                      formatBahtWhole(ledger.spentToday, roundUp: true),
                      formatBahtWhole(ledger.leftToday, roundUp: false),
                    ),
              style: t.caption.copyWith(
                color: ledger.overToday ? t.warnText : t.ink2,
              ),
            ),
          ),
        LedgerRow(
          label: S.paydayRow,
          value: Amount('${r.daysUntilPayday}', unit: S.daysUnit),
          ruled: true,
        ),
        LedgerRow(
          label: S.fridgeEnergyRow,
          value: Amount(formatInt(r.confirmedKcal.round()), unit: S.kcalUnit),
          ruled: true,
        ),
        // The plan shortfall is the one to act on; buying every meal is the
        // comparison, so it reads quieter. With an empty fridge they are the
        // same number, so only one is shown.
        if (!empty)
          LedgerRow(
            key: const ValueKey('shortfall-plan'),
            label: S.shortfallPlan,
            labelStyle: t.label,
            value: shortfall(plan.shortfall),
            ruled: true,
          ),
        LedgerRow(
          key: const ValueKey('shortfall-eat-out'),
          label: S.shortfallEatOut,
          labelStyle: t.caption,
          value: r.budgetDeficit.isZero
              ? shortfall(r.budgetDeficit)
              : Amount(
                  formatBahtWhole(r.budgetDeficit, roundUp: true),
                  unit: S.bahtUnit,
                  color: t.ink2,
                ),
          ruled: true,
        ),
        const SizedBox(height: RecipixTokens.space3),
        SizedBox(
          width: double.infinity,
          height: RecipixTokens.tapTarget,
          child: OutlinedButton.icon(
            key: const ValueKey('log-spending'),
            style: OutlinedButton.styleFrom(
              foregroundColor: t.ink,
              side: BorderSide(color: t.line),
              textStyle: t.label,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
              ),
            ),
            onPressed: () => showSpendingSheet(context),
            icon: RecipixIcon(RecipixIcons.plus, color: t.ink),
            label: const Text(S.logSpending),
          ),
        ),
      ],
    );
  }
}

class _ThinBar extends StatelessWidget {
  const _ThinBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
      child: SizedBox(
        width: double.infinity,
        height: RecipixTokens.space1,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: t.surfaceSunken)),
            FractionallySizedBox(
              widthFactor: fraction.clamp(0, 1),
              heightFactor: 1,
              child: ColoredBox(color: t.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section title with an optional hint on the line below (it used to sit
/// right-aligned and compete with the title — critique: มี่).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: RecipixTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: t.title)),
          if (trailing != null) Text(trailing!, style: t.caption),
        ],
      ),
    );
  }
}

/// A row you swipe right to mark used, left to throw away; tap for detail.
class _UseFirstRow extends ConsumerWidget {
  const _UseFirstRow({required this.item, required this.today});

  final IngredientItem item;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final ctrl = ref.read(fridgeProvider.notifier);
    final days = item.daysUntilExpiry(today);
    final place = ref.watch(
      fridgeProvider.select((s) => s.arrangement.placements[item.id]),
    );

    void act(DismissDirection direction) {
      HapticFeedback.lightImpact();
      final used = direction == DismissDirection.startToEnd;
      if (used) {
        ctrl.use(item.id);
      } else {
        ctrl.discard(item.id);
      }
      showUndoToast(
        context,
        used ? S.toastUsed(item.name) : S.toastDiscarded(item.name),
        onUndo: ctrl.undo,
      );
    }

    return Dismissible(
      key: ValueKey('use-first-${item.id}'),
      onDismissed: act,
      background: _SwipeAction(
        color: t.accent,
        foreground: t.onAccent,
        icon: RecipixIcons.check,
        label: S.actionUse,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeAction(
        color: t.urgent,
        foreground: t.onAccent,
        icon: RecipixIcons.trash,
        label: S.actionDiscard,
        alignment: Alignment.centerRight,
      ),
      child: Pressable(
        onTap: () => showItemSheet(context, ref, item),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RecipixTokens.space3,
            vertical: RecipixTokens.space2,
          ),
          decoration: BoxDecoration(
            color: t.bg,
            border: Border(bottom: BorderSide(color: t.line)),
          ),
          child: Row(
            children: [
              IngredientTile(
                ingredientKey: item.key,
                name: item.name,
                size: RecipixTokens.space5 + RecipixTokens.space2,
                faded: days < 0,
              ),
              const SizedBox(width: RecipixTokens.space3),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      flex: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place == null
                                ? S.inBasket
                                : S.compartmentNames[place
                                      .slot
                                      .compartment
                                      .name]!,
                            style: t.caption,
                          ),
                          Text(
                            item.name,
                            style: t.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Expanded(child: DotLeader()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: RecipixTokens.space1 / 2,
                ),
                child: Text(
                  S.daysLeftLong(days),
                  style: t.label.copyWith(
                    color: freshnessColor(t, days) ?? t.ink2,
                    fontFeatures: RecipixTokens.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.color,
    required this.foreground,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final Color foreground;
  final RecipixIcons icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: RecipixTokens.space4),
      child: Align(
        alignment: alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RecipixIcon(icon, color: foreground),
            const SizedBox(width: RecipixTokens.space2),
            Text(
              label,
              style: context.tokens.label.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One suggested dish. Shows the match plainly: "ครบทุกอย่าง" at 100%,
/// otherwise the percentage and what is missing. No fanfare. Tap opens
/// the recipe page (ADR-015).
class _MenuRow extends ConsumerWidget {
  const _MenuRow({required this.suggestion, this.first = false});

  final MenuSuggestion suggestion;

  /// Rows share rules: only the first draws a top line.
  final bool first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final catalog = ref.watch(catalogProvider);
    final match = suggestion.match;
    final r = match.recipe;
    final missing = [for (final k in match.missingKeys) catalog[k]?.name ?? k]
        .join(', ');
    final source = suggestion.source == SuggestionSource.fridge
        ? S.suggestFromFridge
        : S.suggestEasy;

    return Pressable(
      key: ValueKey('menu-${r.id}'),
      semanticLabel: r.name,
      onTap: () => context.go('/home/recipe/${r.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: RecipixTokens.space3),
        // A dish is a line in the day, not a card (ADR-012).
        decoration: BoxDecoration(
          border: Border(
            top: first ? BorderSide(color: t.line) : BorderSide.none,
            bottom: BorderSide(color: t.line),
          ),
        ),
        child: _menuLine(t, r, match, missing, source),
      ),
    );
  }

  Widget _menuLine(
    RecipixTokens t,
    Recipe r,
    RecipeMatch match,
    String missing,
    String source,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.name, style: t.body.copyWith(fontWeight: FontWeight.w600)),
              Text(
                '$source · ${S.minutes(r.cookMinutes)} · '
                '${S.difficulty(r.difficulty.name)}',
                style: t.caption,
              ),
              if (!match.isJackpot)
                Text(S.menuMissing(missing), style: t.caption),
            ],
          ),
        ),
        const SizedBox(width: RecipixTokens.space2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: RecipixTokens.space2),
          decoration: BoxDecoration(
            border: Border.all(color: match.isJackpot ? t.accent : t.line),
            borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
          ),
          child: Text(
            match.isJackpot
                ? S.menuFull
                : S.matchPlain(
                    match.haveKeys.length,
                    match.haveKeys.length + match.missingKeys.length,
                    match.matchPercentage,
                  ),
            style: t.label.copyWith(
              color: match.isJackpot ? t.accent : t.ink2,
              fontFeatures: RecipixTokens.tabularFigures,
            ),
          ),
        ),
      ],
    );
  }
}

/// The next dish the plan will cook from the fridge. Tap to cook it.
class _NextMealRow extends ConsumerWidget {
  const _NextMealRow({required this.meal});

  final PlannedMeal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final today = ref.watch(todayProvider);
    final recipe = meal.recipe!;
    final uses = meal.uses.map((p) => p.item.name).toSet().join(', ');
    final when = meal.date == today
        ? '${S.today} · ${S.mealName(meal.slot)}'
        : meal.date == today.addDays(1)
        ? '${S.tomorrow} · ${S.mealName(meal.slot)}'
        : '${formatThaiDate(meal.date)} · ${S.mealName(meal.slot)}';

    return Pressable(
      key: const ValueKey('next-meal'),
      semanticLabel: '${S.nextMealTitle} ${recipe.name}',
      onTap: () => showCookSheet(context, meal),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: RecipixTokens.space3),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: t.line),
            bottom: BorderSide(color: t.line),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(when, style: t.caption),
                  Text(
                    recipe.name,
                    style: t.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${S.usesLine(uses)} · '
                    '${S.kcal(recipe.kcalPerServing.round())}',
                    style: t.caption,
                  ),
                ],
              ),
            ),
            RecipixIcon(RecipixIcons.chevronRight, color: t.ink2),
          ],
        ),
      ),
    );
  }
}

/// A plain text link row with a chevron, full-width tap target.
class _QuietLink extends StatelessWidget {
  const _QuietLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      semanticLabel: label,
      onTap: onTap,
      child: SizedBox(
        height: RecipixTokens.tapTarget,
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: t.label.copyWith(color: t.accent)),
            ),
            RecipixIcon(RecipixIcons.chevronRight, color: t.accent),
          ],
        ),
      ),
    );
  }
}
