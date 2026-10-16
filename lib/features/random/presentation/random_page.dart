import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/icons/recipix_icon.dart';
import '../../../shared/motion/motion.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/ledger.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../../../shared/widgets/mode_picker.dart';
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
    // A short still moment with all reels in view before the result
    // (critique: ดล — the sheet used to cover the reels as they landed).
    final pause = reduceMotionOf(context) ? Duration.zero : _resultPause;
    Future.delayed(pause, () {
      if (!mounted) return;
      setState(() => _spinning = false);
      final s = ref.read(randomProvider);
      if (s.mode == RandomMode.cook) {
        showCookResultSheet(context, s.result!);
      } else {
        showEatOutResultSheet(context, s.dish!, overBudget: s.overBudget);
      }
    });
  }

  static const _resultPause = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = ref.watch(randomProvider);
    final ctrl = ref.read(randomProvider.notifier);
    final cook = s.mode == RandomMode.cook;
    final nothingToSpin =
        cook &&
        IngredientSlotMachine.usablePool(
          ref.watch(fridgeProvider).items,
          ref.watch(todayProvider),
        ).isEmpty;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(RecipixTokens.space3),
        children: [
          Semantics(
            header: true,
            child: Text(S.randomTitle, style: t.pageTitle),
          ),
          const SizedBox(height: RecipixTokens.space3),
          ModePicker(
            labels: const {
              RandomMode.cook: S.modeCook,
              RandomMode.eatOut: S.modeEatOut,
            },
            value: s.mode,
            onChanged: _spinning ? null : ctrl.setMode,
          ),
          const SizedBox(height: RecipixTokens.space3),
          if (nothingToSpin)
            _EmptyFridgeNote(onEatOut: () => ctrl.setMode(RandomMode.eatOut))
          else
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
            if (s.reels.any((r) => r != null))
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
              onPressed: _spinning || nothingToSpin ? null : _spin,
              child: const Text(S.spin),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three reels behind one window, separated by hairlines — one object, not
/// three cards with tiles inside (critique: ธนากร, 5.1 rule 6). Tapping a
/// reel locks its ingredient; the locked reel gets an accent rule and a
/// lock under it.
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
    final t = context.tokens;
    final today = ref.watch(todayProvider);
    final pool = IngredientSlotMachine.usablePool(
      ref.watch(fridgeProvider).items,
      today,
    );
    final ctrl = ref.read(randomProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth / reelCount;
        final tile = w - RecipixTokens.space4;
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: t.surface,
                border: Border.all(color: t.line),
                borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < reelCount; i++)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: i == 0
                                ? BorderSide.none
                                : BorderSide(color: t.line),
                            bottom: BorderSide(
                              color: state.locked.contains(i)
                                  ? t.accent
                                  : Colors.transparent,
                              width: RecipixTokens.space1 - 1,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: RecipixTokens.space2,
                        ),
                        child: Pressable(
                          key: ValueKey('reel-frame-$i'),
                          selected: state.locked.contains(i),
                          semanticLabel: S.reelLabel(
                            i,
                            state.reels[i]?.name ?? S.emptyReel,
                          ),
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
                                  ? Text(
                                      '?',
                                      style: t.pageTitle.copyWith(
                                        color: t.line,
                                      ),
                                    )
                                  : IngredientTile(
                                      ingredientKey: item.key,
                                      name: item.name,
                                      size: tile,
                                      framed: false,
                                    ),
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
                for (var i = 0; i < reelCount; i++)
                  Expanded(
                    child: _ReelLabel(
                      name: hidden.contains(i) && !state.locked.contains(i)
                          ? S.reelSpinning
                          : state.reels[i]?.name,
                      locked: state.locked.contains(i),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ReelLabel extends StatelessWidget {
  const _ReelLabel({required this.name, required this.locked});

  final String? name;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
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
            name ?? S.emptyReel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.caption.copyWith(color: locked ? t.accent : t.ink2),
          ),
        ),
      ],
    );
  }
}

/// Cook mode with nothing usable in the fridge: say so before a spin, and
/// offer the mode that works (critique: ฎา — it used to spin to "?" and
/// suggest unlocking).
class _EmptyFridgeNote extends StatelessWidget {
  const _EmptyFridgeNote({required this.onEatOut});

  final VoidCallback onEatOut;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.randomFridgeEmpty, style: t.body),
        Pressable(
          key: const ValueKey('try-eat-out'),
          semanticLabel: S.tryEatOut,
          onTap: onEatOut,
          child: SizedBox(
            height: RecipixTokens.tapTarget,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                S.tryEatOut,
                style: t.label.copyWith(color: t.accent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Eat-out reel: one line like an order slip — dish left, price right —
/// rather than a centred promo card (critique: ธนากร ad test).
class _DishReel extends ConsumerWidget {
  const _DishReel({required this.state, required this.onStopped});

  final RandomState state;
  final VoidCallback onStopped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final dishes = ref.watch(eatOutMenuProvider).dishes;
    const height = RecipixTokens.space6 + RecipixTokens.space2;
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
        builder: (context, dish) => dish == null
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(S.emptyReel, style: t.bodyMuted),
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      dish.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.title,
                    ),
                  ),
                  const SizedBox(width: RecipixTokens.space2),
                  Amount(formatBaht(dish.price), unit: S.bahtUnit),
                ],
              ),
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
