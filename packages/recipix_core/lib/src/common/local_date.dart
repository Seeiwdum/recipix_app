/// A calendar date without time or time zone.
///
/// Expiry and payday rules work in whole days, so storing a [DateTime]
/// would invite off-by-one bugs around midnight. Arithmetic runs on UTC
/// internally so daylight-saving shifts can never change a day count.
final class LocalDate implements Comparable<LocalDate> {
  /// Out-of-range parts roll over, e.g. `LocalDate(2026, 10, 32)` is 1 Nov.
  factory LocalDate(int year, int month, int day) {
    final utc = DateTime.utc(year, month, day);
    return LocalDate._(utc.year, utc.month, utc.day);
  }

  const LocalDate._(this.year, this.month, this.day);

  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate(dateTime.year, dateTime.month, dateTime.day);

  /// Parses `YYYY-MM-DD`.
  factory LocalDate.parse(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw FormatException('Expected YYYY-MM-DD', iso);
    }
    return LocalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Whole days from this date to [other]; negative when [other] is earlier.
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  LocalDate addDays(int days) =>
      LocalDate.fromDateTime(_utc.add(Duration(days: days)));

  int get daysInMonth => DateTime.utc(year, month + 1, 0).day;

  /// ISO weekday: 1 = Monday ... 7 = Sunday.
  int get weekday => _utc.weekday;

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
