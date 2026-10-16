import 'package:recipix_core/recipix_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('LocalDate', () {
    test('rolls over and counts days across months and years', () {
      expect(LocalDate(2026, 10, 32), LocalDate(2026, 11, 1));
      expect(LocalDate(2026, 12, 31).daysUntil(LocalDate(2027, 1, 2)), 2);
      expect(LocalDate(2028, 2, 1).daysInMonth, 29);
    });

    test('parses ISO dates', () {
      expect(LocalDate.parse('2026-10-16'), today);
      expect(today.toString(), '2026-10-16');
    });
  });

  group('IngredientItem expiry', () {
    test('expiry is computed from today, not stored as a day count', () {
      final milk = item('milk', daysLeft: 3);
      expect(milk.daysUntilExpiry(today), 3);
      expect(milk.daysUntilExpiry(today.addDays(2)), 1);
      expect(milk.isUrgent(today.addDays(2)), isTrue);
      expect(milk.isExpired(today.addDays(4)), isTrue);
    });
  });

  group('Money', () {
    test('exact satang arithmetic', () {
      expect(Money.baht(0.1) + Money.baht(0.2), Money.baht(0.3));
      expect(Money.baht(60) * 3, Money.baht(180));
    });

    test('divideFloor rejects zero parts', () {
      expect(() => Money.baht(1).divideFloor(0), throwsArgumentError);
    });
  });

  group('Quantity', () {
    test('converts within a dimension only', () {
      expect(
        const Quantity(
          1.5,
          QuantityUnit.liter,
        ).convertTo(QuantityUnit.milliliter).amount,
        1500,
      );
      expect(
        () => const Quantity.pieces(1).convertTo(QuantityUnit.gram),
        throwsArgumentError,
      );
    });
  });
}
