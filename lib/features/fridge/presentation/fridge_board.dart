import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/motion/motion.dart';
import '../domain/fridge_controller.dart';
import '../domain/fridge_layout.dart';
import 'fridge_geometry.dart';
import 'fridge_item_view.dart';

/// The fridge mini-game: a cross-section with shelves, crisper drawer,
/// freezer and door bins, plus a basket of shopping to put away.
///
/// Drag is hand-rolled (not `Draggable`) so a drop can spring into its
/// cell and a refused drop can spring back to where it came from.
class FridgeBoard extends ConsumerStatefulWidget {
  const FridgeBoard({
    super.key,
    required this.geometry,
    required this.onOpenItem,
  });

  final FridgeGeometry geometry;
  final ValueChanged<IngredientItem> onOpenItem;

  /// ~1.5% overshoot (damping ratio 0.8), inside the 6% motion budget.
  static final spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 520,
    ratio: 0.8,
  );

  @override
  ConsumerState<FridgeBoard> createState() => _FridgeBoardState();
}

class _Drag {
  _Drag({
    required this.itemId,
    required this.width,
    required this.origin,
    required this.rect,
    required this.grab,
  });

  final String itemId;
  final int width;

  /// Where the item was before it was picked up.
  final Rect origin;
  Rect rect;

  /// Pointer position inside [rect].
  final Offset grab;

  Slot? target;
  bool valid = false;
  bool overBasket = false;

  /// Set once released; the item springs from [from] to [to].
  Rect? from;
  Rect? to;

  bool get settling => to != null;
}

class _FridgeBoardState extends ConsumerState<FridgeBoard>
    with SingleTickerProviderStateMixin {
  final _stackKey = GlobalKey();
  late final AnimationController _settle = AnimationController.unbounded(
    vsync: this,
  )..addListener(_onSettleTick);
  _Drag? _drag;
  bool _drawerOpen = false;

  FridgeGeometry get g => widget.geometry;
  FridgeController get _ctrl => ref.read(fridgeProvider.notifier);

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  Offset _local(Offset global) =>
      (_stackKey.currentContext!.findRenderObject()! as RenderBox)
          .globalToLocal(global);

  Size _footprint(int width) => Size(
    width * g.cell - 2 * FridgeGeometry.inset,
    g.cell - 2 * FridgeGeometry.inset,
  );

  // Drag lifecycle -----------------------------------------------------------

  void _start(IngredientItem item, Rect origin, DragStartDetails d) {
    if (_drag != null) return;
    final width = _ctrl.widthOf(item);
    final size = _footprint(width);
    final local = _local(d.globalPosition);
    final fraction = Offset(
      ((local.dx - origin.left) / origin.width).clamp(0.0, 1.0),
      ((local.dy - origin.top) / origin.height).clamp(0.0, 1.0),
    );
    final grab = Offset(fraction.dx * size.width, fraction.dy * size.height);
    setState(() {
      _drag = _Drag(
        itemId: item.id,
        width: width,
        origin: origin,
        rect: (local - grab) & size,
        grab: grab,
      );
    });
  }

  void _update(DragUpdateDetails d) {
    final drag = _drag;
    if (drag == null || drag.settling) return;
    final local = _local(d.globalPosition);
    setState(() {
      drag.rect = (local - drag.grab) & drag.rect.size;
      drag.overBasket = g.isOverBasket(drag.rect);
      drag.target = drag.overBasket ? null : g.slotFor(drag.rect, drag.width);
      drag.valid =
          drag.target != null && _ctrl.canPlace(drag.itemId, drag.target!);
      if (drag.target?.compartment == CompartmentId.crisper) {
        _drawerOpen = true;
      }
    });
  }

  void _end() {
    final drag = _drag;
    if (drag == null || drag.settling) return;
    final state = ref.read(fridgeProvider);
    final wasPlaced = state.arrangement.contains(drag.itemId);

    Rect to;
    if (drag.valid && _ctrl.place(drag.itemId, drag.target!)) {
      to = g.itemRect(drag.target!, drag.width);
      HapticFeedback.lightImpact();
    } else if (drag.overBasket) {
      if (wasPlaced) _ctrl.moveToBasket(drag.itemId);
      final basket = ref.read(fridgeProvider).basket;
      final index = basket.indexWhere((i) => i.id == drag.itemId);
      to = g.basketItemRect(index.clamp(0, g.basketCapacity - 1));
    } else {
      to = drag.origin; // refused: spring back
    }

    if (reduceMotionOf(context)) {
      setState(() => _drag = null);
      return;
    }
    setState(() {
      drag
        ..from = drag.rect
        ..to = to
        ..target = null;
    });
    _settle.value = 0;
    _settle
        .animateWith(SpringSimulation(FridgeBoard.spring, 0, 1, 0))
        .whenCompleteOrCancel(() {
          if (mounted) setState(() => _drag = null);
        });
  }

  void _onSettleTick() {
    final drag = _drag;
    if (drag == null || !drag.settling) return;
    setState(() => drag.rect = Rect.lerp(drag.from, drag.to, _settle.value)!);
  }

  // Build --------------------------------------------------------------------

  Widget _interactive(IngredientItem item, Rect rect, Widget child) =>
      GestureDetector(
        key: ValueKey('item-${item.id}'),
        behavior: HitTestBehavior.opaque,
        // Report the touch-down point, not the point after the slop, so
        // the item stays under the finger where it was grabbed.
        dragStartBehavior: DragStartBehavior.down,
        onTap: () => widget.onOpenItem(item),
        onPanStart: (d) => _start(item, rect, d),
        onPanUpdate: _update,
        onPanEnd: (_) => _end(),
        onPanCancel: _end,
        child: Semantics(
          button: true,
          label: item.name,
          excludeSemantics: true,
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final state = ref.watch(fridgeProvider);
    final today = ref.watch(todayProvider);
    final reduce = reduceMotionOf(context);
    final move = reduce ? Duration.zero : RecipixTokens.medium;
    final drag = _drag;
    final dragging = drag != null && !drag.settling;
    final dragged = drag == null ? null : state.byId(drag.itemId);

    bool dimmed(IngredientItem i) => !state.filter.matches(i, today);

    final crisper = g.compartmentRect(CompartmentId.crisper);
    // Closed: the front hides the lower part of the crisper row. Open: it
    // is pulled out below the cabinet, still visible and tappable.
    final frontHeight = _drawerOpen
        ? RecipixTokens.space3 + 2
        : crisper.height * 0.3; // low enough that each item stays readable
    final frontTop = _drawerOpen
        ? crisper.bottom + 2
        : crisper.bottom - frontHeight;

    final basket = state.basket;
    final visibleBasket = basket.take(g.basketCapacity).toList();
    final overflow = basket.length - visibleBasket.length;

    return SizedBox.fromSize(
      size: g.size,
      child: Stack(
        key: _stackKey,
        clipBehavior: Clip.none,
        children: [
          // Cabinet body.
          Positioned.fromRect(
            rect: g.cabinet,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                border: Border.all(color: t.line),
                borderRadius: BorderRadius.circular(RecipixTokens.radiusLg),
              ),
            ),
          ),

          // Compartments and door bins.
          for (final c in FridgeLayout.compartments)
            if (c.id == CompartmentId.door)
              for (var row = 0; row < c.rows; row++)
                Positioned.fromRect(
                  rect: g.cellRect(Slot(c.id, 0, row)),
                  child: _Bin(color: t.bg, line: t.line),
                )
            else
              Positioned.fromRect(
                rect: g.compartmentRect(c.id),
                child: Semantics(
                  label: S.compartmentNames[c.id.name],
                  child: _Compartment(id: c.id),
                ),
              ),

          // Cell grid: invisible anchors, outlined while dragging.
          for (final c in FridgeLayout.compartments)
            for (var row = 0; row < c.rows; row++)
              for (var col = 0; col < c.cols; col++)
                Positioned.fromRect(
                  key: ValueKey('cell-${c.id.name}-$col-$row'),
                  rect: g
                      .cellRect(Slot(c.id, col, row))
                      .deflate(FridgeGeometry.inset),
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity:
                          dragging &&
                              state.arrangement.itemAt(Slot(c.id, col, row)) ==
                                  null
                          ? 1
                          : 0,
                      duration: RecipixTokens.fast,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: t.line),
                          borderRadius: BorderRadius.circular(
                            RecipixTokens.radiusSm,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

          // Items on the shelves.
          for (final item in state.placed)
            _placedItem(item, state, today, move, dimmed(item)),

          // Crisper drawer front: slides down to open.
          AnimatedPositioned(
            duration: move,
            curve: RecipixTokens.enter,
            left: crisper.left,
            width: crisper.width,
            top: frontTop,
            height: frontHeight,
            child: _DrawerFront(
              open: _drawerOpen,
              onTap: () => setState(() => _drawerOpen = !_drawerOpen),
            ),
          ),

          // Basket tray.
          Positioned.fromRect(
            rect: g.basket,
            child: AnimatedContainer(
              duration: RecipixTokens.fast,
              padding: const EdgeInsets.fromLTRB(
                RecipixTokens.space2,
                RecipixTokens.space1,
                RecipixTokens.space2,
                0,
              ),
              alignment: Alignment.topLeft,
              decoration: BoxDecoration(
                color: t.surfaceSunken,
                border: Border.all(
                  color: dragging && drag.overBasket ? t.accent : t.line,
                ),
                borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
              ),
              child: Text.rich(
                TextSpan(
                  text: S.basketTitle,
                  style: t.label,
                  children: [
                    TextSpan(
                      text: '  ${_basketLine(state, drag)}',
                      style: t.caption.copyWith(
                        color: dragging && drag.target != null && !drag.valid
                            ? t.warnText
                            : t.ink2,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          for (var i = 0; i < visibleBasket.length; i++)
            _basketItem(visibleBasket[i], i, today, move, dimmed),
          if (overflow > 0)
            Positioned.fromRect(
              rect: g.basketItemRect(g.basketCapacity - 1),
              child: Center(
                child: Text(S.basketMore(overflow), style: t.label),
              ),
            ),

          // Where the item would land.
          if (dragging && drag.target != null)
            Positioned.fromRect(
              rect: g.itemRect(drag.target!, drag.width),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: drag.valid ? t.accent : t.urgent,
                      width: RecipixTokens.statusLineWidth,
                    ),
                    borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
                  ),
                ),
              ),
            ),

          // The item in hand (or springing into place).
          if (drag != null && dragged != null)
            Positioned.fromRect(
              rect: drag.rect,
              child: IgnorePointer(
                // Lifted 5% while in hand, back to size as it settles.
                child: Transform.scale(
                  scale: drag.settling
                      ? 1 + 0.05 * (1 - _settle.value.clamp(0.0, 1.0))
                      : 1.05,
                  child: FridgeItemView(
                    item: dragged,
                    today: today,
                    size: drag.rect.size,
                    lifted: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The basket's one line: why a drop will not work while dragging over
  /// a bad spot (critique: ดล — refusals had no reason), otherwise a
  /// hint or the truthful empty message.
  String _basketLine(FridgeState state, _Drag? drag) {
    if (drag != null && !drag.settling && drag.target != null && !drag.valid) {
      final c = FridgeLayout.of(drag.target!.compartment);
      return drag.width > c.cols ? S.dropTooWide : S.dropTaken;
    }
    if (state.items.isEmpty) return S.basketFridgeEmpty;
    return state.basket.isEmpty ? S.basketEmpty : S.basketHint;
  }

  /// The item being dragged stays mounted (so its pan gesture survives)
  /// but is hidden; the copy "in hand" is drawn on top instead.
  Widget _hideIfDragged(IngredientItem item, Widget child) =>
      Opacity(opacity: item.id == _drag?.itemId ? 0 : 1, child: child);

  Widget _placedItem(
    IngredientItem item,
    FridgeState state,
    LocalDate today,
    Duration move,
    bool dim,
  ) {
    final p = state.arrangement.placements[item.id]!;
    final rect = g.itemRect(p.slot, p.width);
    return AnimatedPositioned(
      key: ValueKey('placed-${item.id}'),
      duration: move,
      curve: RecipixTokens.enter,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: _hideIfDragged(
        item,
        AnimatedOpacity(
          opacity: dim ? 0.25 : 1,
          duration: RecipixTokens.medium,
          child: _interactive(
            item,
            rect,
            FridgeItemView(item: item, today: today, size: rect.size),
          ),
        ),
      ),
    );
  }

  Widget _basketItem(
    IngredientItem item,
    int index,
    LocalDate today,
    Duration move,
    bool Function(IngredientItem) dimmed,
  ) {
    final rect = g.basketItemRect(index);
    return AnimatedPositioned(
      key: ValueKey('basket-${item.id}'),
      duration: move,
      curve: RecipixTokens.enter,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: _hideIfDragged(
        item,
        AnimatedOpacity(
          opacity: dimmed(item) ? 0.25 : 1,
          duration: RecipixTokens.medium,
          child: _interactive(
            item,
            rect,
            FridgeItemView(item: item, today: today, size: rect.size),
          ),
        ),
      ),
    );
  }
}

/// A door bin: open box with a front lip.
class _Bin extends StatelessWidget {
  const _Bin({required this.color, required this.line});

  final Color color;
  final Color line;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      border: Border(
        left: BorderSide(color: line),
        right: BorderSide(color: line),
        bottom: BorderSide(color: line, width: RecipixTokens.space1 / 2),
      ),
    ),
  );
}

class _DrawerFront extends StatelessWidget {
  const _DrawerFront({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      expanded: open,
      label: S.drawerLabel,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('drawer-front'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.surfaceSunken,
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
          ),
          child: open
              ? Center(
                  child: Container(
                    width: RecipixTokens.space5,
                    height: RecipixTokens.space1,
                    decoration: BoxDecoration(
                      color: t.ink2,
                      borderRadius: BorderRadius.circular(
                        RecipixTokens.radiusSm,
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    const SizedBox(width: RecipixTokens.space2),
                    Flexible(
                      child: Text(
                        S.drawerLabel,
                        style: t.caption,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: RecipixTokens.space5,
                      height: RecipixTokens.space1,
                      decoration: BoxDecoration(
                        color: t.ink2,
                        borderRadius: BorderRadius.circular(
                          RecipixTokens.radiusSm,
                        ),
                      ),
                    ),
                    const SizedBox(width: RecipixTokens.space3),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Each zone gets its material from lines, not colour (critique: ดล):
/// shelves have a heavier front lip, the freezer a double frame like a
/// door seal; the crisper keeps its sliding front.
class _Compartment extends StatelessWidget {
  const _Compartment({required this.id});

  final CompartmentId id;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(RecipixTokens.radiusSm);
    if (id == CompartmentId.freezer) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: t.bg,
          border: Border.all(color: t.line),
          borderRadius: radius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(RecipixTokens.space1 - 1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: t.line),
              borderRadius: radius,
            ),
          ),
        ),
      );
    }
    final shelf = id != CompartmentId.crisper;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(
          left: BorderSide(color: t.line),
          right: BorderSide(color: t.line),
          top: BorderSide(color: t.line),
          bottom: BorderSide(
            color: t.line,
            width: shelf ? RecipixTokens.space1 - 1 : RecipixTokens.lineWidth,
          ),
        ),
      ),
    );
  }
}
