import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../app/theme/recipix_tokens.dart';
import '../domain/fridge_layout.dart';

/// Pixel layout of the fridge board: one coordinate space for the cabinet,
/// every cell and the basket tray, so dragging needs no overlay maths.
///
/// Cabinet: full-width freezer on top; below it four rows (three shelves
/// and the crisper) four cells wide, beside a door column of four bins.
class FridgeGeometry {
  FridgeGeometry._(this.size, this.cell, this.cabinet, this.basket);

  /// Fits the board into [available] with square-ish cells.
  factory FridgeGeometry.fit(Size available) {
    const pad = RecipixTokens.space2;
    const gap = RecipixTokens.space2;
    const basketGap = RecipixTokens.space3;
    // Basket = label line + one row of items + padding.
    const basketChrome = RecipixTokens.space4 + 2 * RecipixTokens.space2;
    const basketScale = 0.8;

    final byWidth = (available.width - 2 * pad - gap) / 5;
    final byHeight =
        (available.height - 2 * pad - 4 * gap - basketGap - basketChrome) /
        (5 + basketScale);
    final cell = math.max(24.0, math.min(byWidth, math.min(byHeight, 96.0)));

    final cabinetW = 5 * cell + gap + 2 * pad;
    final cabinetH = 5 * cell + 4 * gap + 2 * pad;
    final left = (available.width - cabinetW) / 2;
    final cabinet = Rect.fromLTWH(left, 0, cabinetW, cabinetH);
    final basket = Rect.fromLTWH(
      left,
      cabinetH + basketGap,
      cabinetW,
      cell * basketScale + basketChrome,
    );
    return FridgeGeometry._(
      Size(available.width, basket.bottom),
      cell,
      cabinet,
      basket,
    );
  }

  final Size size;
  final double cell;
  final Rect cabinet;
  final Rect basket;

  static const double pad = RecipixTokens.space2;
  static const double gap = RecipixTokens.space2;

  /// Space between an item and its cell edge.
  static const double inset = RecipixTokens.space1;

  double get _innerLeft => cabinet.left + pad;
  double get _innerTop => cabinet.top + pad;
  double get _freezerCellW => (5 * cell + gap) / 5;

  static const _mainRows = [
    CompartmentId.shelf1,
    CompartmentId.shelf2,
    CompartmentId.shelf3,
    CompartmentId.crisper,
  ];

  double _rowTop(int mainRow) =>
      _innerTop + cell + gap + mainRow * (cell + gap);

  Rect compartmentRect(CompartmentId id) => switch (id) {
    CompartmentId.freezer => Rect.fromLTWH(
      _innerLeft,
      _innerTop,
      5 * cell + gap,
      cell,
    ),
    CompartmentId.door => Rect.fromLTWH(
      _innerLeft + 4 * cell + gap,
      _rowTop(0),
      cell,
      4 * cell + 3 * gap,
    ),
    _ => Rect.fromLTWH(
      _innerLeft,
      _rowTop(_mainRows.indexOf(id)),
      4 * cell,
      cell,
    ),
  };

  /// Rect of a single cell.
  Rect cellRect(Slot s) {
    if (s.compartment == CompartmentId.freezer) {
      return Rect.fromLTWH(
        _innerLeft + s.col * _freezerCellW,
        _innerTop,
        _freezerCellW,
        cell,
      );
    }
    if (s.compartment == CompartmentId.door) {
      return Rect.fromLTWH(
        _innerLeft + 4 * cell + gap,
        _rowTop(s.row),
        cell,
        cell,
      );
    }
    final c = compartmentRect(s.compartment);
    return Rect.fromLTWH(c.left + s.col * cell, c.top, cell, cell);
  }

  /// Rect an item of [width] cells occupies at [slot], inset from the walls.
  Rect itemRect(Slot slot, int width) {
    final first = cellRect(slot);
    final last = cellRect(
      Slot(slot.compartment, slot.col + width - 1, slot.row),
    );
    return Rect.fromLTRB(
      first.left,
      first.top,
      last.right,
      last.bottom,
    ).deflate(inset);
  }

  /// Basket items sit in one row at 80% size.
  double get basketItem => cell * 0.8;

  Rect basketItemRect(int index) {
    final top = basket.top + RecipixTokens.space4 + RecipixTokens.space2;
    return Rect.fromLTWH(
      basket.left +
          RecipixTokens.space2 +
          index * (basketItem + RecipixTokens.space2),
      top,
      basketItem,
      basketItem,
    );
  }

  /// How many basket items fit in the tray before "+n".
  int get basketCapacity =>
      ((basket.width - RecipixTokens.space2) /
              (basketItem + RecipixTokens.space2))
          .floor();

  /// The slot an item of [width] would snap to if dropped with its rect at
  /// [rect], or null when its centre is outside every compartment.
  Slot? slotFor(Rect rect, int width) {
    final centre = rect.center;
    for (final c in FridgeLayout.compartments) {
      final area = compartmentRect(c.id);
      if (!area.inflate(gap / 2).contains(centre)) continue;
      final cellW = c.id == CompartmentId.freezer ? _freezerCellW : cell;
      final rawCol = ((rect.left - area.left) / cellW).round();
      final col = rawCol.clamp(0, math.max(0, c.cols - width)).toInt();
      var row = 0;
      if (c.rows > 1) {
        row = ((centre.dy - area.top) / (cell + gap)).floor().clamp(
          0,
          c.rows - 1,
        );
      }
      return Slot(c.id, col, row);
    }
    return null;
  }

  bool isOverBasket(Rect rect) => basket.inflate(gap).contains(rect.center);
}
