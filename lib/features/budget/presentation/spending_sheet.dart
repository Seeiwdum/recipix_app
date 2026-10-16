import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/icons/recipix_icon.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/toast.dart';
import '../domain/budget_controller.dart';

Future<void> showSpendingSheet(BuildContext context) {
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
    builder: (_) => _SpendingSheet(hostContext: context),
  );
}

/// Log one food expense: amount (typed or one tap), what it was, save.
class _SpendingSheet extends ConsumerStatefulWidget {
  const _SpendingSheet({required this.hostContext});

  final BuildContext hostContext;

  @override
  ConsumerState<_SpendingSheet> createState() => _SpendingSheetState();
}

class _SpendingSheetState extends ConsumerState<_SpendingSheet> {
  final _amount = TextEditingController();
  var _category = SpendCategory.eatOut;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Money? get _parsed {
    final v = double.tryParse(_amount.text.replaceAll(',', ''));
    if (v == null || v <= 0) return null;
    return Money.baht(v);
  }

  void _save() {
    final amount = _parsed;
    if (amount == null) return;
    final ctrl = ref.read(budgetProvider.notifier);
    final entry = ctrl.add(amount, _category);
    Navigator.of(context).pop();
    showUndoToast(
      widget.hostContext,
      S.spendSaved(formatBaht(amount)),
      onUndo: () => ctrl.remove(entry.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final quick = ref.watch(budgetProvider.select((b) => b.quickAmounts));
    final todayEntries = ref.watch(todaySpendingProvider);
    final amount = _parsed;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
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
              Text(S.spendTitle, style: t.title),
              const SizedBox(height: RecipixTokens.space2),
              _CategoryPicker(
                value: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: RecipixTokens.space3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('spend-amount'),
                      controller: _amount,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      style: t.display,
                      cursorColor: t.accent,
                      decoration: InputDecoration(
                        hintText: S.spendAmountHint,
                        hintStyle: t.display.copyWith(color: t.line),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                  Text(S.bahtUnit, style: t.title.copyWith(color: t.ink2)),
                ],
              ),
              Divider(height: 1, color: t.line),
              const SizedBox(height: RecipixTokens.space2),
              Wrap(
                spacing: RecipixTokens.space2,
                children: [
                  for (final m in quick)
                    Pressable(
                      semanticLabel: '${formatBaht(m)} ${S.bahtUnit}',
                      onTap: () =>
                          _amount.text = formatBaht(m).replaceAll(',', ''),
                      child: Container(
                        height: RecipixTokens.tapTarget - RecipixTokens.space1,
                        padding: const EdgeInsets.symmetric(
                          horizontal: RecipixTokens.space4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: t.line),
                          borderRadius: BorderRadius.circular(
                            RecipixTokens.radiusMd,
                          ),
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text(formatBaht(m), style: t.number),
                        ),
                      ),
                    ),
                ],
              ),
              if (_category == SpendCategory.eatOut) ...[
                const SizedBox(height: RecipixTokens.space1),
                Text(S.eatOutCountsAsMeal, style: t.caption),
              ],
              const SizedBox(height: RecipixTokens.space3),
              SizedBox(
                height: RecipixTokens.tapTarget,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: t.onAccent,
                    disabledBackgroundColor: t.surfaceSunken,
                    disabledForegroundColor: t.ink2,
                    textStyle: t.label,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        RecipixTokens.radiusMd,
                      ),
                    ),
                  ),
                  onPressed: amount == null ? null : _save,
                  child: const Text(S.spendSave),
                ),
              ),
              const SizedBox(height: RecipixTokens.space3),
              Text(S.spendTodayTitle, style: t.label.copyWith(color: t.ink2)),
              if (todayEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: RecipixTokens.space1),
                  child: Text(S.spendNoneToday, style: t.bodyMuted),
                ),
              for (final e in todayEntries)
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          S.spendCategories[e.category.name]!,
                          style: t.body,
                        ),
                      ),
                      Text(
                        '${formatBaht(e.amount)} ${S.bahtUnit}',
                        style: t.number,
                      ),
                      IconButton(
                        tooltip: S.spendRemove,
                        constraints: const BoxConstraints.tightFor(
                          width: RecipixTokens.tapTarget,
                          height: RecipixTokens.tapTarget,
                        ),
                        onPressed: () =>
                            ref.read(budgetProvider.notifier).remove(e.id),
                        icon: RecipixIcon(RecipixIcons.close, color: t.ink2),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.value, required this.onChanged});

  final SpendCategory value;
  final ValueChanged<SpendCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(RecipixTokens.space1),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
      ),
      child: Row(
        children: [
          for (final c in SpendCategory.values)
            Expanded(
              child: Pressable(
                selected: c == value,
                semanticLabel: S.spendCategories[c.name],
                onTap: () => onChanged(c),
                child: AnimatedContainer(
                  duration: RecipixTokens.fast,
                  height: RecipixTokens.tapTarget - RecipixTokens.space2,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c == value ? t.surface : null,
                    border: c == value ? Border.all(color: t.line) : null,
                    borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
                  ),
                  child: Text(
                    S.spendCategories[c.name]!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.label.copyWith(color: c == value ? t.ink : t.ink2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
