import 'package:flutter/material.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/utils/freshness_color.dart';
import '../../../shared/widgets/ingredient_tile.dart';

/// One item as it sits in the fridge or basket. Freshness reads three ways:
/// the day label, the edge colour, and how washed out the picture is.
/// Colours follow the shared rule (ADR-012): red only for expired/today,
/// amber for 1–5 days.
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

  /// In hand: lifted off the shelf onto a paper card with a hard, unblurred
  /// shadow underneath (critique: ดล — items had no weight; rules forbid
  /// soft shadows, so the shadow is a crisp offset shape).
  final bool lifted;

  static const double _shadowOffset = 3;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final days = item.daysUntilExpiry(today);
    final edge = freshnessColor(t, days, forText: false);
    final labelColor = freshnessColor(t, days) ?? t.ink2;
    final String? label = edge == null
        ? null
        : days < 0
        ? S.expired
        : days == 0
        ? S.today
        : S.daysShort(days);

    final tile = IngredientTile(
      ingredientKey: item.key,
      name: item.name,
      size: size.height,
      width: size.width,
      faded: days < 0,
      // Items stand directly on the shelf; the tile only shows in hand.
      framed: lifted,
    );
    final radius = BorderRadius.circular(RecipixTokens.radiusSm);

    return SizedBox.fromSize(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (lifted)
            Positioned.fill(
              top: _shadowOffset,
              bottom: -_shadowOffset,
              child: DecoratedBox(
                decoration: BoxDecoration(color: t.line, borderRadius: radius),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: lifted ? t.surface : null,
                borderRadius: radius,
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
                    borderRadius: radius,
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
                  borderRadius: radius,
                ),
                child: Text(label, style: t.micro.copyWith(color: labelColor)),
              ),
            ),
        ],
      ),
    );
  }
}
