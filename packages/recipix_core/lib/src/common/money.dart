/// An amount of Thai baht stored as whole satang (1 baht = 100 satang).
///
/// Integer storage keeps budget sums exact; floating-point baht drifts.
final class Money implements Comparable<Money> {
  const Money.satang(this.satang);

  factory Money.baht(num baht) => Money.satang((baht * 100).round());

  static const zero = Money.satang(0);

  final int satang;

  double get baht => satang / 100;

  bool get isNegative => satang < 0;
  bool get isZero => satang == 0;

  Money operator +(Money other) => Money.satang(satang + other.satang);
  Money operator -(Money other) => Money.satang(satang - other.satang);

  /// Multiplies and rounds to the nearest satang.
  Money operator *(num factor) => Money.satang((satang * factor).round());

  /// Splits into [parts] equal shares, rounding down so the shares never
  /// add up to more than the original amount.
  Money divideFloor(int parts) {
    if (parts <= 0) {
      throw ArgumentError.value(parts, 'parts', 'must be positive');
    }
    return Money.satang((satang / parts).floor());
  }

  bool operator <(Money other) => satang < other.satang;
  bool operator <=(Money other) => satang <= other.satang;
  bool operator >(Money other) => satang > other.satang;
  bool operator >=(Money other) => satang >= other.satang;

  static Money max(Money a, Money b) => a >= b ? a : b;
  static Money min(Money a, Money b) => a <= b ? a : b;

  @override
  int compareTo(Money other) => satang.compareTo(other.satang);

  @override
  bool operator ==(Object other) => other is Money && other.satang == satang;

  @override
  int get hashCode => satang.hashCode;

  @override
  String toString() => 'THB ${baht.toStringAsFixed(2)}';
}
