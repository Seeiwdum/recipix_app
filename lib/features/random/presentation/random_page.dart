import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/icons/recipix_icon.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../../../shared/widgets/pressable.dart';
import '../../fridge/domain/fridge_controller.dart';
import '../domain/random_controller.dart';
import 'random_result_sheets.dart';
import 'slot_reel.dart';

/// Slot machine: three ingredient reels (cook) or one dish reel (eat out).
/// The result is decided first; reels stop one by one; the result opens
/// in a sheet. Tap a reel to lock its ingredient for the next spin.
class RandomPage extends ConsumerStatefulWidget {
  const RandomPage({super.key});

  @override
  ConsumerState<RandomPage> createState() => _RandomPageState();
}

class _RandomPageState extends ConsumerState<RandomPage> {
  bool _spinning = false;

  /// Reels that have not stopped yet this spin. Their labels stay hidden
  /// so the result is not given away before the reel lands.
  Set<int> _pending = const {};

  void _spin() {
    if (_spinning) return;
    final ctrl = ref.read(randomProvider.notifier);
    final mode = ref.read(randomProvider).mode;
    if (mode == RandomMode.cook) {
      ctrl.spinCook();
      _pending = {for (var i = 0; i < reelCount; i++) i};
    } else {
      if (ctrl.spinEatOut() == null) return;
      _pending = {0};
    }
    setState(() => _spinning = true);
  }

  void _onReelStopped(int reel) {
    if (!_spinning) return;
    setState(() => _pending = {..._pending}..remove(reel));
    if (_pending.isNotEmpty) return;
    setState(() => _spinning = false);
    final s = ref.read(randomProvider);
    if (s.mode == RandomMode.cook) {
      showCookResultSheet(context, s.result!);
    } else {
      showEatOutResultSheet(context, s.dish!, overBudget: s.overBudget);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = ref.watch(randomProvider);
    final ctrl = ref.read(randomProvider.notifier);
    final cook = s.mode == RandomMode.cook;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(RecipixTokens.space3),
        children: [
          Semantics(
            header: true,
            child: Text(S.randomTitle, style: t.title.copyWith(fontSize: 24)),
          ),
          const SizedBox(height: RecipixTokens.space3),
          _ModePicker(
            value: s.mode,
            onChanged: _spinning ? null : ctrl.setMode,
          ),
          const SizedBox(height: RecipixTokens.space3),
          Text(cook ? S.spinHintCook : S.spinHintEatOut, style: t.bodyMuted),
          const SizedBox(height: RecipixTokens.space3),
          if (cook)
            _IngredientReels(
              state: s,
              hidden: _pending,
              onStopped: _onReelStopped,
            )
          else
            _DishReel(state: s, onStopped: () => _onReelStopped(0)),
          const SizedBox(height: RecipixTokens.space3),
          if (cook) ...[
            Text(S.lockHint, style: t.caption, textAlign: TextAlign.center),
            const SizedBox(height: RecipixTokens.space2),
            _CheckRow(
              label: S.preferExpiring,
              value: s.expiringFirst,
              onChanged: _spinning ? null : ctrl.setExpiringFirst,
            ),
          ],
          const SizedBox(height: RecipixTokens.space3),
          SizedBox(
            height: RecipixTokens.tapTarget,
            child: FilledButton(
              key: const ValueKey('spin'),
              style: FilledButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: t.onAccent,
                disabledBackgroundColor: t.surfaceSunken,
                disabledForegroundColor: t.ink2,
                textStyle: t.label,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
                ),
              ),
              onPressed: _spinning ? null : _spin,
              child: const Text(S.spin),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientReels extends ConsumerWidget {
  const _IngredientReels({
    required this.state,
    required this.hidden,
    required this.onStopped,
  });

  final RandomState state;
  final Set<int> hidden;
  final ValueChanged<int> onStopped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final pool = IngredientSlotMachine.usablePool(
      ref.watch(fridgeProvider).items,
      today,
    );
    final ctrl = ref.read(randomProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = RecipixTokens.space2;
        final w = (constraints.maxWidth - gap * (reelCount - 1)) / reelCount;
        final tile = w - RecipixTokens.space2 * 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < reelCount; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: w,
                child: _ReelFrame(
                  index: i,
                  locked: state.locked.contains(i),
                  name: hidden.contains(i) && !state.locked.contains(i)
                      ? S.reelSpinning
                      : state.reels[i]?.name,
                  onTap: state.reels[i] == null
                      ? null
                      : () => ctrl.toggleLock(i),
                  child: SlotReel<IngredientItem>(
                    key: ValueKey('reel-$i'),
                    target: state.reels[i],
                    fillers: pool,
                    spinToken: state.spins,
                    index: i,
                    locked: state.locked.contains(i),
                    tileHeight: tile,
                    onStopped: () => onStopped(i),
                    builder: (context, item) => Center(
                      child: item == null
                          ? IngredientTile(
                              ingredientKey: null,
                              name: S.emptyReel,
                              size: tile,
                            )
                          : IngredientTile(
                              ingredientKey: item.key,
                              name: item.name,
                              size: tile,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ReelFrame extends StatelessWidget {
  const _ReelFrame({
    required this.index,
    required this.locked,
    required this.name,
    required this.onTap,
    required this.child,
  });

  final int index;
  final bool locked;
  final String? name;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final label = name ?? S.emptyReel;
    return Pressable(
      key: ValueKey('reel-frame-$index'),
      selected: locked,
      semanticLabel:
          '${S.reelLabel(index, label)}${locked ? ' ${S.locked}' : ''}',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(RecipixTokens.space2),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(
            color: locked ? t.accent : t.line,
            width: locked
                ? RecipixTokens.statusLineWidth
                : RecipixTokens.lineWidth,
          ),
          borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
        ),
        child: Column(
          children: [
            child,
            const SizedBox(height: RecipixTokens.space2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (locked) ...[
                  RecipixIcon(
                    RecipixIcons.lock,
                    color: t.accent,
                    size: RecipixTokens.space3,
                  ),
                  const SizedBox(width: RecipixTokens.space1),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(
                      color: locked ? t.accent : t.ink2,
                    ),
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

class _DishReel extends ConsumerWidget {
  const _DishReel({required this.state, required this.onStopped});

  final RandomState state;
  final VoidCallback onStopped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final dishes = ref.watch(eatOutMenuProvider).dishes;
    const height = RecipixTokens.space6 * 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: RecipixTokens.space3),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
      ),
      child: SlotReel(
        key: const ValueKey('dish-reel'),
        target: state.dish,
        fillers: dishes,
        spinToken: state.spins,
        index: 0,
        tileHeight: height,
        onStopped: onStopped,
        builder: (context, dish) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dish?.name ?? S.emptyReel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.title.copyWith(color: dish == null ? t.ink2 : t.ink),
              ),
              if (dish != null)
                Text(
                  S.priceBaht(dish.price.baht.toStringAsFixed(0)),
                  style: t.number.copyWith(color: t.ink2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.value, required this.onChanged});

  final RandomMode value;
  final ValueChanged<RandomMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    const labels = {
      RandomMode.cook: S.modeCook,
      RandomMode.eatOut: S.modeEatOut,
    };
    return Container(
      padding: const EdgeInsets.all(RecipixTokens.space1),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
      ),
      child: Row(
        children: [
          for (final m in RandomMode.values)
            Expanded(
              child: Pressable(
                selected: m == value,
                semanticLabel: labels[m],
                onTap: onChanged == null ? null : () => onChanged!(m),
                child: AnimatedContainer(
                  duration: RecipixTokens.fast,
                  height: RecipixTokens.tapTarget - RecipixTokens.space2,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: m == value ? t.surface : null,
                    border: m == value ? Border.all(color: t.line) : null,
                    borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
                  ),
                  child: Text(
                    labels[m]!,
                    style: t.label.copyWith(color: m == value ? t.ink : t.ink2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      key: const ValueKey('prefer-expiring'),
      selected: value,
      semanticLabel: label,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: SizedBox(
        height: RecipixTokens.tapTarget,
        child: Row(
          children: [
            Container(
              width: RecipixTokens.space4,
              height: RecipixTokens.space4,
              decoration: BoxDecoration(
                color: value ? t.accent : t.surface,
                border: Border.all(color: value ? t.accent : t.line),
                borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
              ),
              child: value
                  ? RecipixIcon(
                      RecipixIcons.check,
                      color: t.onAccent,
                      size: RecipixTokens.space3,
                    )
                  : null,
            ),
            const SizedBox(width: RecipixTokens.space2),
            Text(label, style: t.body),
          ],
        ),
      ),
    );
  }
}
