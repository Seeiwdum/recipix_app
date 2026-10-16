import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/icons/recipix_icon.dart';
import '../../shared/motion/motion.dart';
import '../../shared/widgets/pressable.dart';
import '../strings.dart';
import '../theme/recipix_tokens.dart';

class TabSpec {
  const TabSpec(this.path, this.label, this.icon);

  final String path;
  final String label;
  final RecipixIcons icon;
}

/// Tab order, left to right. Branch indexes in the router follow this list.
const List<TabSpec> appTabs = [
  TabSpec('/home', S.tabHome, RecipixIcons.home),
  TabSpec('/fridge', S.tabFridge, RecipixIcons.fridge),
  TabSpec('/scan', S.tabScan, RecipixIcons.scan),
  TabSpec('/random', S.tabRandom, RecipixIcons.random),
  TabSpec('/dashboard', S.tabDashboard, RecipixIcons.dashboard),
];

/// Scaffold around the tab branches: page area plus the tab bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell, required this.children});

  final StatefulNavigationShell shell;
  final List<Widget> children;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabSwitcher(index: shell.currentIndex, children: children),
      bottomNavigationBar: RecipixTabBar(
        currentIndex: shell.currentIndex,
        onSelect: _select,
      ),
    );
  }
}

/// Keeps every tab alive and plays the signature tab change: the old tab
/// fades out fast while the new one fades in rising 8px. Reduced motion:
/// a plain 120ms fade.
class TabSwitcher extends StatefulWidget {
  const TabSwitcher({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<TabSwitcher> createState() => _TabSwitcherState();
}

class _TabSwitcherState extends State<TabSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RecipixTokens.medium,
    value: 1,
  );
  int? _previous;

  /// Bumped on every switch so a cancelled transition cannot clear the
  /// outgoing tab of the transition that replaced it.
  int _generation = 0;

  @override
  void didUpdateWidget(TabSwitcher old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      final generation = ++_generation;
      _previous = old.index;
      _controller.duration = reduceMotionOf(context)
          ? RecipixTokens.fast
          : RecipixTokens.medium;
      _controller.forward(from: 0).whenCompleteOrCancel(() {
        if (mounted && generation == _generation) {
          setState(() => _previous = null);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    final outFraction =
        RecipixTokens.fast.inMilliseconds / RecipixTokens.medium.inMilliseconds;
    final fadeOut = reduce
        ? const AlwaysStoppedAnimation<double>(0)
        : ReverseAnimation(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(0, outFraction, curve: RecipixTokens.exit),
            ),
          );
    final fadeIn = CurvedAnimation(
      parent: _controller,
      curve: reduce
          ? Curves.linear
          : Interval(outFraction / 2, 1, curve: RecipixTokens.enter),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _buildTab(i, fadeIn, fadeOut, reduce),
      ],
    );
  }

  Widget _buildTab(
    int i,
    Animation<double> fadeIn,
    Animation<double> fadeOut,
    bool reduce,
  ) {
    final current = i == widget.index;
    final leaving = i == _previous;
    final visible = current || leaving;

    Widget child = widget.children[i];
    if (current) {
      child = AnimatedBuilder(
        animation: fadeIn,
        builder: (context, child) => Opacity(
          opacity: fadeIn.value,
          child: Transform.translate(
            offset: Offset(
              0,
              reduce ? 0 : RecipixTokens.riseOffset * (1 - fadeIn.value),
            ),
            child: child,
          ),
        ),
        child: child,
      );
    } else if (leaving) {
      child = FadeTransition(opacity: fadeOut, child: child);
    }

    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: current,
        child: IgnorePointer(
          ignoring: !current,
          child: ExcludeSemantics(excluding: !current, child: child),
        ),
      ),
    );
  }
}

/// Custom tab bar: paper surface, hairline top border, accent for the
/// selected tab and a short bar that slides to it.
class RecipixTabBar extends StatelessWidget {
  const RecipixTabBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const double height = 64;
  static const double indicatorWidth = 24;
  static const double indicatorHeight = 3;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final count = appTabs.length;
    final duration = reduceMotionOf(context)
        ? Duration.zero
        : RecipixTokens.medium;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(
          top: BorderSide(color: t.line, width: RecipixTokens.lineWidth),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              AnimatedAlign(
                duration: duration,
                curve: RecipixTokens.enter,
                alignment: Alignment(
                  count == 1 ? 0 : -1 + 2 * currentIndex / (count - 1),
                  -1,
                ),
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: indicatorWidth,
                      height: indicatorHeight,
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(indicatorHeight),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: _TabItem(
                        spec: appTabs[i],
                        selected: i == currentIndex,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.accent : t.ink2;
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: spec.label,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RecipixIcon(spec.icon, color: color),
            const SizedBox(height: RecipixTokens.space1 / 2),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: t.caption.copyWith(
                color: color,
                height: 1.3,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
