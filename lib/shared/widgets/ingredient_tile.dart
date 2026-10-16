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
    this.faded = false,
  });

  final String? ingredientKey;
  final String name;
  final double size;

  /// Items close to or past expiry are drawn slightly washed out so
  /// freshness reads at a glance.
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final key = ingredientKey;

    if (key == null) {
      return SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: t.ink2,
            radius: RecipixTokens.radiusSm,
          ),
          child: Center(
            child: Text('?', style: t.title.copyWith(color: t.ink2, height: 1)),
          ),
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
              style: t.title.copyWith(color: t.ink2, height: 1),
            ),
          );

    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Opacity(
        opacity: faded ? 0.55 : 1,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: t.surfaceSunken,
            borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
          ),
          child: content,
        ),
      ),
    );
  }
}
