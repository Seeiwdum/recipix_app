import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/recipix_tokens.dart';
import '../icons/recipix_icon.dart';
import 'pressable.dart';

/// − value + control. Tap steps once; holding repeats and speeds up after
/// a moment, so a big change is not twenty taps. Replaces the old demo's
/// gradient slider.
class ValueStepper extends StatelessWidget {
  const ValueStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onStep,
    this.unit,
    this.large = false,
    this.decreaseLabel = '−',
    this.increaseLabel = '+',
    this.canDecrease = true,
    this.canIncrease = true,
  });

  final String label;

  /// Already formatted.
  final String value;
  final String? unit;

  /// Called with -1 or +1, times the hold multiplier while held.
  final ValueChanged<int> onStep;
  final bool large;
  final String decreaseLabel;
  final String increaseLabel;
  final bool canDecrease;
  final bool canIncrease;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final valueStyle = large ? t.display : t.title;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: t.caption),
              Semantics(
                liveRegion: true,
                child: Text.rich(
                  TextSpan(
                    text: value,
                    style: valueStyle.copyWith(
                      fontFeatures: RecipixTokens.tabularFigures,
                    ),
                    children: [
                      if (unit != null)
                        TextSpan(text: ' $unit', style: t.bodyMuted),
                    ],
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        _StepButton(
          icon: RecipixIcons.minus,
          semanticLabel: decreaseLabel,
          enabled: canDecrease,
          onStep: (n) => onStep(-n),
        ),
        const SizedBox(width: RecipixTokens.space2),
        _StepButton(
          icon: RecipixIcons.plus,
          semanticLabel: increaseLabel,
          enabled: canIncrease,
          onStep: onStep,
        ),
      ],
    );
  }
}

class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.enabled,
    required this.onStep,
  });

  final RecipixIcons icon;
  final String semanticLabel;
  final bool enabled;
  final ValueChanged<int> onStep;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _timer;
  int _ticks = 0;

  void _startRepeat() {
    _ticks = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      _ticks++;
      // x1 for the first second, then x5.
      widget.onStep(_ticks < 8 ? 1 : 5);
    });
  }

  void _stopRepeat() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = widget.enabled ? t.ink : t.line;
    return GestureDetector(
      onLongPressStart: widget.enabled ? (_) => _startRepeat() : null,
      onLongPressEnd: (_) => _stopRepeat(),
      onLongPressCancel: _stopRepeat,
      child: Pressable(
        semanticLabel: widget.semanticLabel,
        onTap: widget.enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onStep(1);
              }
            : null,
        child: Container(
          width: RecipixTokens.tapTarget,
          height: RecipixTokens.tapTarget,
          decoration: BoxDecoration(
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
          ),
          alignment: Alignment.center,
          child: RecipixIcon(widget.icon, color: color),
        ),
      ),
    );
  }
}
