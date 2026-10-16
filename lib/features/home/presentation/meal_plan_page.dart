import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/icons/recipix_icon.dart';
import '../../../shared/motion/entrance.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/pressable.dart';
import '../domain/home_providers.dart';
import 'cook_sheet.dart';

/// Every meal from now to payday: cooked from the fridge first, the rest
/// bought. Recomputed whenever the fridge or the spending log changes.
class MealPlanPage extends ConsumerWidget {
  const MealPlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final plan = ref.watch(mealPlanProvider);
    final today = ref.watch(todayProvider);

    // Group meals by day, keeping order.
    final days = <LocalDate, List<PlannedMeal>>{};
    for (final m in plan.meals) {
      (days[m.date] ??= []).add(m);
    }
    final dayList = days.entries.toList();

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
                    key: const ValueKey('plan-back'),
                    tooltip: S.back,
                    constraints: const BoxConstraints.tightFor(
                      width: RecipixTokens.tapTarget,
                      height: RecipixTokens.tapTarget,
                    ),
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    icon: RecipixIcon(RecipixIcons.chevronLeft, color: t.ink),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(S.planTitle, style: t.title),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(RecipixTokens.space3),
            sliver: SliverToBoxAdapter(child: _PlanSummary(plan: plan)),
          ),
          SliverList.builder(
            itemCount: dayList.length,
            itemBuilder: (context, i) => Entrance(
              index: i,
              child: _DayBlock(
                date: dayList[i].key,
                today: today,
                meals: dayList[i].value,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: RecipixTokens.space5),
          ),
        ],
      ),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final MealPlan plan;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final spoil = plan.willSpoil.map((i) => i.name).toSet().join(', ');
    return Container(
      padding: const EdgeInsets.all(RecipixTokens.space3),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(RecipixTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.planHomeLead, style: t.label.copyWith(color: t.ink2)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CountUp(
                key: const ValueKey('plan-home-meals'),
                value: plan.homeMeals.toDouble(),
                format: (v) => v.round().toString(),
                style: t.display,
              ),
              const SizedBox(width: RecipixTokens.space2),
              Text(S.mealsUnit, style: t.title),
            ],
          ),
          Text(S.planOfTotal(plan.meals.length), style: t.caption),
          const SizedBox(height: RecipixTokens.space3),
          Divider(height: 1, color: t.line),
          const SizedBox(height: RecipixTokens.space3),
          Text(
            S.planEatOut(
              plan.eatOutMeals,
              formatBahtWhole(plan.eatOutCost, roundUp: true),
            ),
            style: t.body,
          ),
          Text(
            S.planBudgetLeft(formatBahtWhole(plan.budget, roundUp: false)),
            style: t.body,
          ),
          const SizedBox(height: RecipixTokens.space2),
          Text(
            plan.shortfall.isZero
                ? S.planCovered
                : S.planShortfall(
                    formatBahtWhole(plan.shortfall, roundUp: true),
                  ),
            style: t.label.copyWith(
              color: plan.shortfall.isZero ? t.accent : t.urgent,
            ),
          ),
          if (spoil.isNotEmpty) ...[
            const SizedBox(height: RecipixTokens.space1),
            Text(
              S.planWillSpoil(spoil),
              style: t.caption.copyWith(color: t.warnText),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({
    required this.date,
    required this.today,
    required this.meals,
  });

  final LocalDate date;
  final LocalDate today;
  final List<PlannedMeal> meals;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final label = date == today
        ? '${S.today} · ${formatThaiDate(date)}'
        : date == today.addDays(1)
        ? '${S.tomorrow} · ${formatThaiDate(date)}'
        : formatThaiDateLong(date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RecipixTokens.space3,
        RecipixTokens.space2,
        RecipixTokens.space3,
        RecipixTokens.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: t.label),
          const SizedBox(height: RecipixTokens.space1),
          for (final m in meals) _MealRow(meal: m),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal});

  final PlannedMeal meal;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final recipe = meal.recipe;
    final uses = meal.uses.map((p) => p.item.name).toSet().join(', ');

    final row = Container(
      constraints: const BoxConstraints(minHeight: RecipixTokens.tapTarget),
      padding: const EdgeInsets.symmetric(vertical: RecipixTokens.space2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: RecipixTokens.space6 + RecipixTokens.space4,
            child: Text(S.mealName(meal.slot), style: t.caption),
          ),
          Expanded(
            child: recipe == null
                ? Text(S.eatOutMeal, style: t.bodyMuted)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.name, style: t.body),
                      Text(S.usesLine(uses), style: t.caption),
                    ],
                  ),
          ),
          if (recipe == null)
            Text(
              '${formatBaht(meal.eatOutCost)} ${S.bahtUnit}',
              style: t.number.copyWith(color: t.ink2),
            )
          else
            RecipixIcon(RecipixIcons.chevronRight, color: t.ink2),
        ],
      ),
    );

    if (recipe == null) return row;
    return Pressable(
      key: ValueKey('plan-meal-${meal.date}-${meal.slot}'),
      semanticLabel: '${S.mealName(meal.slot)} ${recipe.name}',
      onTap: () => showCookSheet(context, meal),
      child: row,
    );
  }
}
