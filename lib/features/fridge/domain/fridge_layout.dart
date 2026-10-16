import 'package:recipix_core/recipix_core.dart';

/// The compartments of the fridge cross-section, top to bottom.
enum CompartmentId { freezer, shelf1, shelf2, shelf3, crisper, door }

final class Compartment {
  const Compartment(this.id, this.zone, {required this.cols, this.rows = 1});

  final CompartmentId id;
  final StorageZone zone;
  final int cols;
  final int rows;

  int get cells => cols * rows;
}

/// The standard fridge: a full-width freezer on top, then three shelves and
/// a crisper drawer (4 slots wide) next to a door column with 4 bins.
abstract final class FridgeLayout {
  static const int mainCols = 4;

  static const List<Compartment> compartments = [
    Compartment(CompartmentId.freezer, StorageZone.freezer, cols: mainCols + 1),
    Compartment(CompartmentId.shelf1, StorageZone.shelf, cols: mainCols),
    Compartment(CompartmentId.shelf2, StorageZone.shelf, cols: mainCols),
    Compartment(CompartmentId.shelf3, StorageZone.shelf, cols: mainCols),
    Compartment(CompartmentId.crisper, StorageZone.crisper, cols: mainCols),
    Compartment(CompartmentId.door, StorageZone.door, cols: 1, rows: 4),
  ];

  static Compartment of(CompartmentId id) =>
      compartments.firstWhere((c) => c.id == id);

  static int get totalCells => compartments.fold(0, (sum, c) => sum + c.cells);
}

/// Top-left cell an item occupies.
final class Slot {
  const Slot(this.compartment, this.col, [this.row = 0]);

  final CompartmentId compartment;
  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is Slot &&
      other.compartment == compartment &&
      other.col == col &&
      other.row == row;

  @override
  int get hashCode => Object.hash(compartment, col, row);

  @override
  String toString() => 'Slot(${compartment.name}, $col, $row)';
}

/// Where an item sits and how many cells wide it is (1 or 2).
final class Placement {
  const Placement(this.slot, this.width);

  final Slot slot;
  final int width;

  Iterable<Slot> get cells sync* {
    for (var i = 0; i < width; i++) {
      yield Slot(slot.compartment, slot.col + i, slot.row);
    }
  }
}

/// Immutable map of item id to [Placement]. Items without a placement are
/// in the basket.
final class FridgeArrangement {
  FridgeArrangement([Map<String, Placement> placements = const {}])
    : placements = Map.unmodifiable(placements);

  final Map<String, Placement> placements;

  bool contains(String itemId) => placements.containsKey(itemId);

  int get usedCells => placements.values.fold(0, (sum, p) => sum + p.width);

  /// Id of the item covering [cell], if any.
  String? itemAt(Slot cell) {
    for (final entry in placements.entries) {
      if (entry.value.cells.contains(cell)) return entry.key;
    }
    return null;
  }

  /// Whether [itemId] of [width] fits at [slot]. Cells held by the item
  /// itself count as free, so an item can be nudged within its shelf.
  bool canPlace(String itemId, int width, Slot slot) {
    final c = FridgeLayout.of(slot.compartment);
    if (slot.col < 0 || slot.row < 0) return false;
    if (slot.col + width > c.cols || slot.row >= c.rows) return false;
    for (final cell in Placement(slot, width).cells) {
      final owner = itemAt(cell);
      if (owner != null && owner != itemId) return false;
    }
    return true;
  }

  /// Throws [StateError] when the slot is taken or out of bounds.
  FridgeArrangement place(String itemId, int width, Slot slot) {
    if (!canPlace(itemId, width, slot)) {
      throw StateError('$itemId does not fit at $slot');
    }
    return FridgeArrangement({...placements, itemId: Placement(slot, width)});
  }

  FridgeArrangement remove(String itemId) =>
      FridgeArrangement({...placements}..remove(itemId));

  /// After the item at [removed] is taken out, slides the items to its
  /// right along the same row left by its width, so neighbours close the
  /// gap. Gaps the user left elsewhere are kept.
  FridgeArrangement closeGap(Placement removed) {
    final s = removed.slot;
    final next = {...placements};
    for (final e in placements.entries) {
      final p = e.value.slot;
      if (p.compartment == s.compartment && p.row == s.row && p.col > s.col) {
        next[e.key] = Placement(
          Slot(p.compartment, p.col - removed.width, p.row),
          e.value.width,
        );
      }
    }
    return FridgeArrangement(next);
  }

  /// First free slot for an item of [width], trying compartments whose zone
  /// matches [preferred] first, then the rest top to bottom.
  Slot? firstFree(String itemId, int width, {StorageZone? preferred}) {
    final ordered = [
      ...FridgeLayout.compartments.where((c) => c.zone == preferred),
      ...FridgeLayout.compartments.where((c) => c.zone != preferred),
    ];
    for (final c in ordered) {
      for (var row = 0; row < c.rows; row++) {
        for (var col = 0; col + width <= c.cols; col++) {
          final slot = Slot(c.id, col, row);
          if (canPlace(itemId, width, slot)) return slot;
        }
      }
    }
    return null;
  }
}
