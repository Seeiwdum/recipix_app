import 'package:flutter/widgets.dart';

import '../../app/theme/recipix_tokens.dart';
import 'motion.dart';

/// Fades a list row in while it rises 8px, once, delayed 30ms per [index]
/// (rows past the 6th share the last delay). Reduced motion: shown at once.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: RecipixTokens.medium,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: RecipixTokens.enter,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotionOf(context)) {
      _c.value = 1;
      return;
    }
    final step = widget.index.clamp(0, RecipixTokens.staggerMaxItems - 1);
    Future.delayed(RecipixTokens.staggerStep * step, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (context, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(
        offset: Offset(0, RecipixTokens.riseOffset * (1 - _t.value)),
        child: child,
      ),
    ),
    child: widget.child,
  );
}

/// Counts a number up from zero over 400ms the first time it appears, then
/// eases between later values. Reduced motion: no animation.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.format,
    required this.style,
  });

  final double value;
  final String Function(double) format;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    return Semantics(
      label: format(value),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: reduce ? Duration.zero : RecipixTokens.countUp,
        curve: RecipixTokens.enter,
        builder: (context, v, _) => Text(format(v), style: style),
      ),
    );
  }
}
