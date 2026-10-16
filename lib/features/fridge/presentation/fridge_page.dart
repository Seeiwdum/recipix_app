import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/widgets/pressable.dart';
import '../domain/fridge_controller.dart';
import '../domain/fridge_layout.dart';
import '../domain/freshness.dart';
import 'fridge_board.dart';
import 'fridge_geometry.dart';
import 'item_sheet.dart';

class FridgePage extends ConsumerWidget {
  const FridgePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final state = ref.watch(fridgeProvider);
    final used = state.arrangement.usedCells;
    final total = FridgeLayout.totalCells;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RecipixTokens.space3,
              RecipixTokens.space3,
              RecipixTokens.space3,
              RecipixTokens.space2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    S.fridgeTitle,
                    style: t.title.copyWith(fontSize: 24),
                  ),
                ),
                const SizedBox(width: RecipixTokens.space3),
                Expanded(
                  child: Text(
                    S.fridgeCapacity(used, total),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.number.copyWith(color: t.ink2),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RecipixTokens.space3,
            ),
            child: _CapacityBar(fraction: used / total),
          ),
          const SizedBox(height: RecipixTokens.space2),
          _FilterRow(
            selected: state.filter,
            onSelect: ref.read(fridgeProvider.notifier).setFilter,
          ),
          const SizedBox(height: RecipixTokens.space2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                RecipixTokens.space3,
                0,
                RecipixTokens.space3,
                RecipixTokens.space3,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => Align(
                  alignment: Alignment.topCenter,
                  child: FridgeBoard(
                    geometry: FridgeGeometry.fit(constraints.biggest),
                    onOpenItem: (item) => showItemSheet(context, ref, item),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  const _CapacityBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
      child: SizedBox(
        height: RecipixTokens.space1,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: t.surfaceSunken)),
            AnimatedFractionallySizedBox(
              duration: RecipixTokens.medium,
              curve: RecipixTokens.enter,
              widthFactor: fraction.clamp(0, 1),
              heightFactor: 1,
              alignment: Alignment.centerLeft,
              child: ColoredBox(color: t.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelect});

  final FridgeFilter selected;
  final ValueChanged<FridgeFilter> onSelect;

  static const labels = {
    FridgeFilter.all: S.filterAll,
    FridgeFilter.useSoon: S.filterUseSoon,
    FridgeFilter.produce: S.filterProduce,
    FridgeFilter.protein: S.filterProtein,
    FridgeFilter.unknown: S.filterUnknown,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: RecipixTokens.tapTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: RecipixTokens.space3),
        itemCount: FridgeFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: RecipixTokens.space2),
        itemBuilder: (context, i) {
          final f = FridgeFilter.values[i];
          final on = f == selected;
          return Pressable(
            selected: on,
            semanticLabel: labels[f],
            onTap: () => onSelect(f),
            child: Center(
              child: AnimatedContainer(
                duration: RecipixTokens.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: RecipixTokens.space3,
                  vertical: RecipixTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: on ? t.surface : null,
                  border: Border.all(color: on ? t.accent : t.line),
                  borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
                ),
                child: Text(
                  labels[f]!,
                  style: t.label.copyWith(color: on ? t.accent : t.ink2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
