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
import '../../../shared/widgets/ingredient_tile.dart';
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
    final menu = ref.watch(menuSuggestionProvider);
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
                  child: Text(
                    S.homeTitle,
                    style: t.title.copyWith(fontSize: 24),
                  ),
                ),
                const SizedBox(height: RecipixTokens.space3),
                const _ReportSheet(),
                const SizedBox(height: RecipixTokens.space4),
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
                  _SectionHeader(
                    title: S.nextMealTitle,
                    trailing: S.planHomeSummary(
                      plan.homeMeals,
                      plan.meals.length,
                    ),
                  ),
                  _NextMealRow(meal: next),
                ] else if (menu != null) ...[
                  const _SectionHeader(title: S.menuTitle),
                  _MenuRow(match: menu),
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

class _ReportSheet extends ConsumerWidget {
  const _ReportSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final r = ref.watch(survivalReportProvider);
    final profile = ref.watch(budgetProfileProvider);
    final ledger = ref.watch(ledgerProvider);
    final coverage = r.daysUntilPayday == 0
        ? 1.0
        : math.min(1.0, r.survivalDays / r.daysUntilPayday);

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
          Text(S.survivalLead, style: t.label.copyWith(color: t.ink2)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CountUp(
                key: const ValueKey('survival-days'),
                value: r.survivalDays,
                format: formatDays,
                style: t.display,
              ),
              const SizedBox(width: RecipixTokens.space2),
              Text(S.daysUnit, style: t.title),
            ],
          ),
          Text(
            S.survivalBasis(
              formatInt(r.confirmedKcal.round()),
              formatInt(profile.dailyKcalNeed.round()),
            ),
            style: t.caption,
          ),
          if (r.estimatedKcal > 0)
            Text(
              S.survivalEstimate(formatDays(r.survivalDaysWithEstimate)),
              style: t.caption,
            ),
          const SizedBox(height: RecipixTokens.space3),
          _ThinBar(fraction: coverage),
          const SizedBox(height: RecipixTokens.space1),
          Text(
            S.coverage(formatDays(r.survivalDays), r.daysUntilPayday),
            style: t.caption,
          ),
          const SizedBox(height: RecipixTokens.space3),
          Divider(height: 1, thickness: RecipixTokens.lineWidth, color: t.line),
          const SizedBox(height: RecipixTokens.space3),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: S.allowanceLabel,
                  value: formatBahtWhole(ledger.allowanceToday, roundUp: false),
                  unit: S.bahtUnit,
                ),
              ),
              Expanded(
                child: _Figure(
                  label: S.paydayLabel,
                  value: '${r.daysUntilPayday}',
                  unit: S.daysUnit,
                ),
              ),
            ],
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
                  color: ledger.overToday ? t.urgent : t.ink2,
                ),
              ),
            ),
          const SizedBox(height: RecipixTokens.space2),
          Text(
            r.isCovered
                ? S.budgetCovered
                : S.deficit(formatBahtWhole(r.budgetDeficit, roundUp: true)),
            style: t.label.copyWith(color: r.isCovered ? t.accent : t.urgent),
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
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.caption),
        Text.rich(
          TextSpan(
            text: value,
            style: t.title.copyWith(fontFeatures: RecipixTokens.tabularFigures),
            children: [TextSpan(text: ' $unit', style: t.bodyMuted)],
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: RecipixTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Semantics(header: true, child: Text(title, style: t.title)),
          const SizedBox(width: RecipixTokens.space2),
          if (trailing != null)
            Expanded(
              child: Text(
                trailing!,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.caption,
              ),
            ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: t.body),
                    Text(
                      place == null
                          ? S.inBasket
                          : S.compartmentNames[place.slot.compartment.name]!,
                      style: t.caption,
                    ),
                  ],
                ),
              ),
              Text(
                S.daysLeftLong(days),
                style: t.label.copyWith(
                  color: days <= 0 ? t.urgent : t.warnText,
                  fontFeatures: RecipixTokens.tabularFigures,
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
/// otherwise the percentage and what is missing. No fanfare.
class _MenuRow extends ConsumerWidget {
  const _MenuRow({required this.match});

  final RecipeMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final catalog = ref.watch(catalogProvider);
    final r = match.recipe;
    final missing = [for (final k in match.missingKeys) catalog[k]?.name ?? k]
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(RecipixTokens.space3),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  style: t.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${S.minutes(r.cookMinutes)} · ${S.kcal(r.kcalPerServing.round())}',
                  style: t.caption,
                ),
                if (!match.isJackpot)
                  Text(S.menuMissing(missing), style: t.caption),
              ],
            ),
          ),
          const SizedBox(width: RecipixTokens.space2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RecipixTokens.space2,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: match.isJackpot ? t.accent : t.line),
              borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
            ),
            child: Text(
              match.isJackpot
                  ? S.menuFull
                  : S.matchPercent(match.matchPercentage),
              style: t.label.copyWith(
                color: match.isJackpot ? t.accent : t.ink2,
                fontFeatures: RecipixTokens.tabularFigures,
              ),
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(RecipixTokens.space3),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.line),
          borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
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
