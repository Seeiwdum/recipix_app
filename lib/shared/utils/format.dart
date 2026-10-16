import 'package:recipix_core/recipix_core.dart';

import '../../app/strings.dart';

/// 6054 -> "6,054".
String formatInt(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// Whole baht when there are no satang: "1,600" / "99.50".
String formatBaht(Money money) {
  final whole = money.satang ~/ 100;
  final rest = (money.satang % 100).abs();
  return rest == 0
      ? formatInt(whole)
      : '${formatInt(whole)}.${rest.toString().padLeft(2, '0')}';
}

/// One decimal, rounded down so "2.96 days" never reads as "3.0".
String formatDays(double days) =>
    ((days * 10).floorToDouble() / 10).toStringAsFixed(1);

/// "16 ต.ค."
String formatThaiDate(LocalDate d) => '${d.day} ${S.monthsShort[d.month - 1]}';

/// "วันศุกร์ 16 ต.ค."
String formatThaiDateLong(LocalDate d) =>
    'วัน${S.weekdays[d.weekday - 1]} ${formatThaiDate(d)}';

/// Whole baht, rounding toward the safe side: shortfalls round up, money
/// you may spend rounds down. "780.10" owed reads as "781".
String formatBahtWhole(Money money, {required bool roundUp}) {
  final s = money.satang;
  final whole = roundUp ? (s + 99) ~/ 100 : s ~/ 100;
  return formatInt(whole);
}

/// "300 ก." / "1.5 ล." / "2 ชิ้น".
String formatQuantity(Quantity q) {
  final a = q.amount;
  final text = a == a.roundToDouble()
      ? a.toInt().toString()
      : a.toStringAsFixed(1);
  return '$text ${S.units[q.unit.name]}';
}
