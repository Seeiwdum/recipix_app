import 'package:flutter/widgets.dart';

import '../../app/theme/recipix_tokens.dart';
import 'pressable.dart';

/// Two or three modes side by side in a sunken track; the chosen one sits
/// on paper. Used by the random tab (cook / eat out) and the scan tab
/// (barcode / photo).
class ModePicker<T> extends StatelessWidget {
  const ModePicker({
    super.key,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  /// Modes in display order, with their labels.
  final Map<T, String> labels;
  final T value;
  final ValueChanged<T>? onChanged;

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
          for (final MapEntry(key: m, value: label) in labels.entries)
            Expanded(
              child: Pressable(
                selected: m == value,
                semanticLabel: label,
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
                    label,
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
