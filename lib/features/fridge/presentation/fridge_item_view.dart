import 'package:flutter/material.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/widgets/ingredient_tile.dart';
import '../domain/freshness.dart';

/// One item as it sits in the fridge or basket. Freshness reads three ways:
/// the day label, the edge colour, and how washed out the picture is.
class FridgeItemView extends StatelessWidget {
  const FridgeItemView({
    super.key,
    required this.item,
    required this.today,
    required this.size,
    this.lifted = false,
  });

  final IngredientItem item;
  final LocalDate today;
  final Size size;

  /// Being dragged: drawn on a plain surface with a hairline so it reads as
  /// "in hand" without a blurry shadow.
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final freshness = Freshness.of(item, today);
    final days = item.daysUntilExpiry(today);

    final (Color? edge, Color labelColor, String? label) = switch (freshness) {
      Freshness.fresh => (null, t.ink2, null),
      Freshness.soon => (t.warn, t.warnText, S.daysShort(days)),
      Freshness.urgent => (
        t.urgent,
        t.urgent,
        days == 0 ? S.today : S.daysShort(days),
      ),
      Freshness.expired => (t.urgent, t.urgent, S.expired),
    };

    final tile = IngredientTile(
      ingredientKey: item.key,
      name: item.name,
      size: size.height,
      width: size.width,
      faded: freshness == Freshness.expired,
    );

    return SizedBox.fromSize(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: lifted ? t.surface : null,
                borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
              ),
              child: tile,
            ),
          ),
          if (edge != null || lifted)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: edge ?? t.line,
                      width: edge != null
                          ? RecipixTokens.statusLineWidth
                          : RecipixTokens.lineWidth,
                    ),
                    borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
                  ),
                ),
              ),
            ),
          if (label != null && size.height >= 36)
            Positioned(
              right: RecipixTokens.space1,
              bottom: RecipixTokens.space1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RecipixTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
                ),
                child: Text(label, style: t.micro.copyWith(color: labelColor)),
              ),
            ),
        ],
      ),
    );
  }
}
