import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/icons/recipix_icon.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/dashed_rrect.dart';
import '../../../shared/widgets/ledger.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/value_stepper.dart';
import '../../budget/domain/budget_controller.dart';
import '../domain/dashboard_providers.dart';

/// Budget you can edit, the pay period at a glance, what the money left
/// buys, badges (concept kept from the old app), and dishes cooked most.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(RecipixTokens.space3),
        children: [
          Semantics(
            header: true,
            child: Text(S.dashboardTitle, style: t.pageTitle),
          ),
          const SizedBox(height: RecipixTokens.space3),
          const _BudgetSheet(),
          const SizedBox(height: RecipixTokens.space4),
          const _SectionTitle(S.timelineTitle),
          const _Timeline(),
          const SizedBox(height: RecipixTokens.space4),
          const _SectionTitle(S.buysTitle),
          const _BuysTable(),
          const SizedBox(height: RecipixTokens.space4),
          const _SectionTitle(S.badgesTitle),
          const _BadgeGrid(),
          const SizedBox(height: RecipixTokens.space4),
          const _SectionTitle(S.repeatsTitle),
          const _Repeats(),
          const SizedBox(height: RecipixTokens.space4),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: RecipixTokens.space2),
    child: Semantics(
      header: true,
      child: Text(text, style: context.tokens.title),
    ),
  );
}

/// The account-book page for this pay period (ADR-012): the one big number
/// is what is **left** (critique: ฎา — the total budget used to be the big
/// number), then the three settings as plain ruled rows with steppers.
/// The shortfall lives on the home page only, so it is not repeated here.
class _BudgetSheet extends ConsumerWidget {
  const _BudgetSheet();

  static final _budgetStep = Money.baht(100);
  static final _priceStep = Money.baht(5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final budget = ref.watch(budgetProvider);
    final ledger = ref.watch(ledgerProvider);
    final ctrl = ref.read(budgetProvider.notifier);
    final payday = budget.paydayDayOfMonth;
    final over = ledger.remaining.isNegative;

    Widget ruled(Widget child) => Container(
      padding: const EdgeInsets.symmetric(vertical: RecipixTokens.space2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          over ? S.overspentLabel : S.remainingLabel,
          style: t.label.copyWith(color: t.ink2),
        ),
        Amount(
          formatBahtWhole(
            over ? Money.zero - ledger.remaining : ledger.remaining,
            roundUp: over,
          ),
          unit: S.bahtUnit,
          size: AmountSize.display,
          color: over ? t.warnText : null,
        ),
        Text(
          S.spentOfBudget(
            formatBahtWhole(ledger.spentInPeriod, roundUp: true),
            formatBahtWhole(budget.periodBudget, roundUp: false),
          ),
          style: t.caption,
        ),
        const SizedBox(height: RecipixTokens.space3),
        Divider(height: 1, color: t.line),
        ruled(
          ValueStepper(
            key: const ValueKey('budget-stepper'),
            label: S.periodBudgetLabel,
            value: formatBaht(budget.periodBudget),
            unit: S.bahtUnit,
            decreaseLabel: S.decrease(S.periodBudgetLabel),
            increaseLabel: S.increase(S.periodBudgetLabel),
            canDecrease: budget.periodBudget > Money.zero,
            onStep: (n) =>
                ctrl.setPeriodBudget(budget.periodBudget + _budgetStep * n),
          ),
        ),
        ruled(
          ValueStepper(
            key: const ValueKey('payday-stepper'),
            label: S.paydaySetting,
            value: payday == null ? S.paydayEndOfMonth : S.paydayDay(payday),
            decreaseLabel: S.decrease(S.paydaySetting),
            increaseLabel: S.increase(S.paydaySetting),
            canDecrease: payday != null,
            canIncrease: payday != 31,
            // 0 stands for "end of month" so the stepper walks
            // end-of-month, 1, 2, ... 31.
            onStep: (n) {
              final next = ((payday ?? 0) + n).clamp(0, 31);
              ctrl.setPayday(next == 0 ? null : next);
            },
          ),
        ),
        ruled(
          ValueStepper(
            key: const ValueKey('meal-price-stepper'),
            label: S.mealPriceSetting,
            value: formatBaht(budget.prices.mealOutPrice),
            unit: S.bahtUnit,
            decreaseLabel: S.decrease(S.mealPriceSetting),
            increaseLabel: S.increase(S.mealPriceSetting),
            canDecrease: budget.prices.mealOutPrice > _priceStep,
            onStep: (n) => ctrl.setMealOutPrice(
              budget.prices.mealOutPrice + _priceStep * n,
            ),
          ),
        ),
      ],
    );
  }
}

/// One short bar per day of the pay period: within budget, over budget,
/// nothing logged, today, still to come.
class _Timeline extends ConsumerWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final days = ref.watch(timelineProvider);
    final ledger = ref.watch(ledgerProvider);

    Color fill(DayMark m) => switch (m) {
      DayMark.within => t.accent,
      // Over budget is amber, not red: a day of overspending is not an
      // emergency (critique: 5/5 — red read as scolding).
      DayMark.over => t.warn,
      DayMark.noRecord => t.surfaceSunken,
      DayMark.today => t.surface,
      DayMark.future => t.surfaceSunken,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: RecipixTokens.space4,
          child: Row(
            children: [
              for (final d in days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      key: ValueKey('day-${d.date}'),
                      decoration: BoxDecoration(
                        color: fill(d.mark),
                        border: d.mark == DayMark.today
                            ? Border.all(
                                color: t.ink,
                                width: RecipixTokens.statusLineWidth,
                              )
                            : d.mark == DayMark.future
                            ? Border.all(color: t.line)
                            : null,
                        borderRadius: BorderRadius.circular(
                          RecipixTokens.radiusSm,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: RecipixTokens.space1),
        Row(
          children: [
            Text(formatThaiDate(ledger.periodStart), style: t.caption),
            const Spacer(),
            Text(
              formatThaiDate(ledger.nextPayday.addDays(-1)),
              style: t.caption,
            ),
          ],
        ),
        const SizedBox(height: RecipixTokens.space1),
        Wrap(
          spacing: RecipixTokens.space3,
          children: [
            _Legend(color: t.accent, label: S.markWithin),
            _Legend(color: t.warn, label: S.markOver),
            _Legend(color: t.surfaceSunken, label: S.markNoRecord),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: RecipixTokens.space2,
          height: RecipixTokens.space2,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
          ),
        ),
        const SizedBox(width: RecipixTokens.space1),
        Text(label, style: t.caption),
      ],
    );
  }
}

/// What the money left is worth, in meals and days.
class _BuysTable extends ConsumerWidget {
  const _BuysTable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider);
    final prices = ref.watch(budgetProvider).prices;
    final left = Money.max(Money.zero, ledger.remaining);
    final meals = left.satang ~/ prices.mealOutPrice.satang;
    final perDay = prices.dailyEatOutCost.satang;
    final days = perDay == 0 ? 0.0 : left.satang / perDay;

    return Column(
      children: [
        LedgerRow(
          label: S.buysMeals(formatBaht(prices.mealOutPrice)),
          value: Amount('$meals', unit: S.mealsUnit),
          ruled: true,
        ),
        LedgerRow(
          label: S.buysDays(prices.mealsPerDay),
          value: Amount(formatDays(days), unit: S.daysUnit),
          ruled: true,
        ),
        LedgerRow(
          label: S.buysAllowance,
          value: Amount(
            formatBahtWhole(ledger.allowanceToday, roundUp: false),
            unit: S.bahtUnit,
          ),
          ruled: true,
        ),
      ],
    );
  }
}

const _badgeIcons = {
  'clear_expiring': RecipixIcons.tag,
  'budget_saver': RecipixIcons.wallet,
  'home_cook': RecipixIcons.pan,
  'zero_waste_week': RecipixIcons.bowl,
  'first_scan': RecipixIcons.barcode,
};

/// Three columns of stamps (badge concept kept from the old app). Not yet
/// earned: a dashed outline in pencil grey with the distance as numbers
/// ("2/5"). Earned: inked in the accent with the date. No card around
/// them (critique: ดล, ธนากร — identical cards with empty bars).
class _BadgeGrid extends ConsumerWidget {
  const _BadgeGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(badgeProgressProvider);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: RecipixTokens.space3,
      crossAxisSpacing: RecipixTokens.space2,
      childAspectRatio: 0.78,
      children: [for (final b in badges) _BadgeTile(progress: b)],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.progress});

  final BadgeProgress progress;

  static const double _stamp = RecipixTokens.space6 + RecipixTokens.space3;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final on = progress.isUnlocked;
    final name = S.badgeNames[progress.badgeId] ?? progress.badgeId;
    final icon = RecipixIcon(
      _badgeIcons[progress.badgeId] ?? RecipixIcons.leaf,
      color: on ? t.accent : t.ink2,
      size: RecipixTokens.space5,
    );
    return Pressable(
      key: ValueKey('badge-${progress.badgeId}'),
      semanticLabel: '$name ${on ? '' : S.badgeLocked}',
      onTap: () => _showBadge(context, progress),
      child: Column(
        children: [
          SizedBox.square(
            dimension: _stamp,
            child: on
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: t.accent,
                        width: RecipixTokens.statusLineWidth,
                      ),
                      borderRadius: BorderRadius.circular(
                        RecipixTokens.radiusLg,
                      ),
                    ),
                    child: Center(child: icon),
                  )
                : CustomPaint(
                    painter: DashedRRectPainter(
                      color: t.ink2,
                      radius: RecipixTokens.radiusLg,
                    ),
                    child: Center(child: icon),
                  ),
          ),
          const SizedBox(height: RecipixTokens.space1),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.caption.copyWith(color: on ? t.ink : t.ink2),
          ),
          Text(
            on
                ? formatThaiDate(progress.unlockedOn!)
                : S.badgeProgress(progress.current, progress.target),
            style: t.micro.copyWith(color: on ? t.accent : t.ink2),
          ),
        ],
      ),
    );
  }
}

void _showBadge(BuildContext context, BadgeProgress p) {
  final t = context.tokens;
  showModalBottomSheet<void>(
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
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RecipixTokens.space3,
          0,
          RecipixTokens.space3,
          RecipixTokens.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RecipixIcon(
                  _badgeIcons[p.badgeId] ?? RecipixIcons.leaf,
                  color: p.isUnlocked ? t.accent : t.ink2,
                  size: RecipixTokens.space5,
                ),
                const SizedBox(width: RecipixTokens.space2),
                Expanded(
                  child: Text(
                    S.badgeNames[p.badgeId] ?? p.badgeId,
                    style: t.title,
                  ),
                ),
              ],
            ),
            const SizedBox(height: RecipixTokens.space2),
            Text(S.badgeRules[p.badgeId] ?? '', style: t.body),
            const SizedBox(height: RecipixTokens.space3),
            if (p.unlockedOn case final date?)
              Text(
                S.badgeUnlockedOn(formatThaiDate(date)),
                style: t.label.copyWith(color: t.accent),
              )
            else ...[
              _MiniBar(fraction: p.fraction),
              const SizedBox(height: RecipixTokens.space1),
              Text(
                S.badgeProgress(p.current, p.target),
                style: t.number.copyWith(color: t.ink2),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.fraction});

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
              child: ColoredBox(color: t.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dishes cooked most, as thin single-colour bars.
class _Repeats extends ConsumerWidget {
  const _Repeats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final list = ref.watch(repeatedDishesProvider);
    if (list.isEmpty) return Text(S.repeatsEmpty, style: t.bodyMuted);
    final top = list.map((e) => e.count).reduce(math.max);
    return Column(
      children: [
        for (final e in list)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: RecipixTokens.space1),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    e.recipe.name,
                    style: t.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: RecipixTokens.space2),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: e.count / top,
                      child: Container(
                        height: RecipixTokens.space1,
                        decoration: BoxDecoration(
                          color: t.accent,
                          borderRadius: BorderRadius.circular(
                            RecipixTokens.radiusSm,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: RecipixTokens.space2),
                SizedBox(
                  width: RecipixTokens.space6,
                  child: Text(
                    S.times(e.count),
                    textAlign: TextAlign.end,
                    style: t.number.copyWith(color: t.ink2),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
