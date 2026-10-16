import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/features/fridge/domain/fridge_layout.dart';
import 'package:recipix_core/recipix_core.dart';

void main() {
  const shelf = CompartmentId.shelf1;

  test('layout has 25 cells', () {
    expect(FridgeLayout.totalCells, 5 + 4 * 3 + 4 + 4);
  });

  test('2-wide items need two free cells inside the shelf', () {
    final a = FridgeArrangement().place('a', 1, const Slot(shelf, 1));
    expect(a.canPlace('b', 2, const Slot(shelf, 0)), isFalse);
    expect(a.canPlace('b', 2, const Slot(shelf, 2)), isTrue);
    expect(a.canPlace('b', 2, const Slot(shelf, 3)), isFalse);
  });

  test('2-wide items never fit the 1-wide door', () {
    expect(
      FridgeArrangement().canPlace('x', 2, const Slot(CompartmentId.door, 0)),
      isFalse,
    );
    expect(
      FridgeArrangement().canPlace(
        'x',
        1,
        const Slot(CompartmentId.door, 0, 3),
      ),
      isTrue,
    );
    expect(
      FridgeArrangement().canPlace(
        'x',
        1,
        const Slot(CompartmentId.door, 0, 4),
      ),
      isFalse,
    );
  });

  test('an item may move within its own cells', () {
    final a = FridgeArrangement().place('a', 2, const Slot(shelf, 0));
    expect(a.canPlace('a', 2, const Slot(shelf, 1)), isTrue);
    expect(
      a.place('a', 2, const Slot(shelf, 1)).itemAt(const Slot(shelf, 0)),
      isNull,
    );
  });

  test('place throws when taken', () {
    final a = FridgeArrangement().place('a', 1, const Slot(shelf, 0));
    expect(() => a.place('b', 1, const Slot(shelf, 0)), throwsStateError);
  });

  test('closeGap slides right-hand neighbours left, keeps other gaps', () {
    var a = FridgeArrangement()
        .place('a', 1, const Slot(shelf, 0))
        .place('b', 2, const Slot(shelf, 1))
        .place('c', 1, const Slot(shelf, 3))
        .place('other', 1, const Slot(CompartmentId.shelf2, 3));
    final removed = a.placements['b']!;
    a = a.remove('b').closeGap(removed);
    expect(a.placements['a']!.slot, const Slot(shelf, 0));
    expect(a.placements['c']!.slot, const Slot(shelf, 1));
    expect(a.placements['other']!.slot, const Slot(CompartmentId.shelf2, 3));
  });

  test('used cells count widths', () {
    final a = FridgeArrangement()
        .place('a', 2, const Slot(shelf, 0))
        .place('b', 1, const Slot(CompartmentId.door, 0, 1));
    expect(a.usedCells, 3);
  });

  test('firstFree prefers the matching zone', () {
    final slot = FridgeArrangement().firstFree(
      'x',
      1,
      preferred: StorageZone.crisper,
    );
    expect(slot, const Slot(CompartmentId.crisper, 0));
  });
}
