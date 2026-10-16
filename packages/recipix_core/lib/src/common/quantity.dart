/// What a unit measures. Units only convert within the same dimension.
enum UnitDimension { count, mass, volume }

/// Units for ingredient amounts. [toBase] converts to grams, millilitres
/// or pieces.
enum QuantityUnit {
  piece(UnitDimension.count, 1),
  gram(UnitDimension.mass, 1),
  kilogram(UnitDimension.mass, 1000),
  milliliter(UnitDimension.volume, 1),
  liter(UnitDimension.volume, 1000);

  const QuantityUnit(this.dimension, this.toBase);

  final UnitDimension dimension;
  final double toBase;

  bool isCompatibleWith(QuantityUnit other) => dimension == other.dimension;
}

/// Amounts below this are treated as zero, absorbing float noise from
/// unit conversions.
const double quantityEpsilon = 1e-9;

final class Quantity {
  const Quantity(this.amount, this.unit);

  const Quantity.pieces(this.amount) : unit = QuantityUnit.piece;
  const Quantity.grams(this.amount) : unit = QuantityUnit.gram;
  const Quantity.milliliters(this.amount) : unit = QuantityUnit.milliliter;

  final double amount;
  final QuantityUnit unit;

  bool get isEmpty => amount <= quantityEpsilon;

  bool isCompatibleWith(Quantity other) => unit.isCompatibleWith(other.unit);

  /// Throws [ArgumentError] when the dimensions differ.
  Quantity convertTo(QuantityUnit target) {
    if (!unit.isCompatibleWith(target)) {
      throw ArgumentError('Cannot convert ${unit.name} to ${target.name}');
    }
    return Quantity(amount * unit.toBase / target.toBase, target);
  }

  /// Result is expressed in this quantity's unit.
  Quantity operator +(Quantity other) =>
      Quantity(amount + other.convertTo(unit).amount, unit);

  /// Result is expressed in this quantity's unit.
  Quantity operator -(Quantity other) =>
      Quantity(amount - other.convertTo(unit).amount, unit);

  @override
  bool operator ==(Object other) =>
      other is Quantity && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(amount, unit);

  @override
  String toString() => '$amount ${unit.name}';
}
