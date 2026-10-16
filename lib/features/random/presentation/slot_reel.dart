import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/motion/motion.dart';

/// One vertical reel. The outcome ([target]) is decided before this widget
/// animates; the reel only plays it back (spec 3.1).
///
/// When [spinToken] changes and the reel is not [locked], it scrolls past
/// [fillers] and stops on [target]: decelerating, a small overshoot
/// (6% of a tile), then settling. Reel [index] stops later than the one
/// before it. Reduced motion: no scroll, just a quick fade.
class SlotReel<T> extends StatefulWidget {
  const SlotReel({
    super.key,
    required this.target,
    required this.fillers,
    required this.spinToken,
    required this.index,
    required this.builder,
    required this.tileHeight,
    this.locked = false,
    this.onStopped,
  });

  final T? target;
  final List<T> fillers;
  final int spinToken;
  final int index;
  final double tileHeight;
  final bool locked;
  final Widget Function(BuildContext context, T? value) builder;
  final VoidCallback? onStopped;

  /// How long reel [index] spins.
  static Duration durationFor(int index) =>
      RecipixTokens.spinBase + RecipixTokens.spinStagger * index;

  @override
  State<SlotReel<T>> createState() => _SlotReelState<T>();
}

class _SlotReelState<T> extends State<SlotReel<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  List<T?> _strip = const [];
  Animation<double> _offset = const AlwaysStoppedAnimation(0);
  T? _shown;

  @override
  void initState() {
    super.initState();
    _shown = widget.target;
  }

  @override
  void didUpdateWidget(SlotReel<T> old) {
    super.didUpdateWidget(old);
    if (old.spinToken == widget.spinToken) {
      if (!_c.isAnimating) _shown = widget.target;
      return;
    }
    if (widget.locked || reduceMotionOf(context)) {
      setState(() => _shown = widget.target);
      WidgetsBinding.instance.addPostFrameCallback((_) => _stopped());
      return;
    }
    _start(from: _shown);
  }

  void _start({required T? from}) {
    final rng = math.Random(widget.spinToken * 31 + widget.index);
    final count = 10 + widget.index * 3;
    final fillers = widget.fillers;
    _strip = [
      from,
      for (var i = 0; i < count; i++)
        fillers.isEmpty ? null : fillers[rng.nextInt(fillers.length)],
      widget.target,
    ];
    final distance = (_strip.length - 1) * widget.tileHeight;
    final overshoot = widget.tileHeight * RecipixTokens.spinOvershoot;
    _offset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: distance + overshoot,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 88,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: distance + overshoot,
          end: distance,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 12,
      ),
    ]).animate(_c);
    _c.duration = SlotReel.durationFor(widget.index);
    _c.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _shown = widget.target;
        _strip = const [];
      });
      _stopped();
    });
    setState(() {});
  }

  void _stopped() {
    if (!mounted) return;
    HapticFeedback.selectionClick();
    widget.onStopped?.call();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.tileHeight;
    if (_strip.isEmpty) {
      return SizedBox(
        height: h,
        child: AnimatedSwitcher(
          duration: RecipixTokens.fast,
          child: KeyedSubtree(
            key: ValueKey(_shown),
            child: widget.builder(context, _shown),
          ),
        ),
      );
    }
    return ClipRect(
      child: SizedBox(
        height: h,
        child: AnimatedBuilder(
          animation: _offset,
          builder: (context, _) {
            final y = _offset.value;
            final first = (y / h).floor().clamp(0, _strip.length - 1);
            final last = math.min(first + 1, _strip.length - 1);
            return Stack(
              children: [
                for (var i = first; i <= last; i++)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: i * h - y,
                    height: h,
                    child: widget.builder(context, _strip[i]),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
