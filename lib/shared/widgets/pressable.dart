import 'package:flutter/widgets.dart';

import '../../app/theme/recipix_tokens.dart';
import '../motion/motion.dart';

/// Tap target that scales to 0.97 while pressed — the app's press feedback
/// in place of ripples.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.selected = false,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;
  final bool selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _down && !reduceMotionOf(context)
        ? RecipixTokens.pressScale
        : 1.0;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: AnimatedScale(
          scale: scale,
          duration: RecipixTokens.fast,
          curve: RecipixTokens.enter,
          child: widget.child,
        ),
      ),
    );
  }
}
