import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/recipix_tokens.dart';
import 'dashed_rrect.dart';

/// Ingredient keys that have art in `assets/ingredients/`. Keys without art
/// fall back to the first letter of the name, never to an emoji.
const Set<String> ingredientArtKeys = {
  'egg',
  'tomato',
  'chili',
  'holy_basil',
  'pork',
  'rice',
  'lime',
  'milk',
  'cabbage',
  'morning_glory',
  'cucumber',
  'garlic',
  'chicken_breast',
  'shrimp',
  'tofu',
  'yogurt',
  'fish_sauce',
  'frozen_dumpling',
};

/// The shared rounded frame every ingredient picture sits in.
///
/// [ingredientKey] `null` means an unidentified ("mystery") item: dashed
/// frame, no fill, a question mark glyph.
class IngredientTile extends StatelessWidget {
  const IngredientTile({
    super.key,
    required this.ingredientKey,
    required this.name,
    this.size = 48,
    this.width,
    this.faded = false,
    this.framed = true,
  });

  final String? ingredientKey;
  final String name;

  /// Height, and width unless [width] is given.
  final double size;

  /// For items two cells wide.
  final double? width;

  /// Items close to or past expiry are drawn slightly washed out so
  /// freshness reads at a glance.
  final bool faded;

  /// Draw the beige tile behind the art. Off when the item stands on a
  /// fridge shelf or in a reel window, so it is not a box inside a box.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final key = ingredientKey;
    final w = width ?? size;
    final glyph = t.title.copyWith(
      color: t.ink2,
      height: 1,
      fontSize: (size * 0.4).clamp(12, 22),
    );

    if (key == null) {
      return SizedBox(
        width: w,
        height: size,
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: t.ink2,
            radius: RecipixTokens.radiusSm,
          ),
          child: Center(child: Text('?', style: glyph)),
        ),
      );
    }

    final Widget content = ingredientArtKeys.contains(key)
        ? Padding(
            padding: EdgeInsets.all(size * 0.08),
            child: SvgPicture.asset('assets/ingredients/$key.svg'),
          )
        : Center(
            child: Text(
              name.characters.isEmpty ? '' : name.characters.first,
              style: glyph,
            ),
          );

    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Opacity(
        opacity: faded ? 0.55 : 1,
        child: Container(
          width: w,
          height: size,
          decoration: framed
              ? BoxDecoration(
                  color: t.surfaceSunken,
                  borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
                )
              : null,
          child: content,
        ),
      ),
    );
  }
}
