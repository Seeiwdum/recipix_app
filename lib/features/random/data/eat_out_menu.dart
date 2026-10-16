import 'dart:convert';

import 'package:recipix_core/recipix_core.dart';

/// A dish bought outside, with a typical price.
final class EatOutDish {
  const EatOutDish({required this.id, required this.name, required this.price});

  final String id;
  final String name;
  final Money price;
}

/// Dishes from `assets/data/eat_out.json`.
final class EatOutMenu {
  EatOutMenu(Iterable<EatOutDish> dishes) : dishes = List.unmodifiable(dishes);

  factory EatOutMenu.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    return EatOutMenu([
      for (final d
          in (json['dishes']! as List<Object?>).cast<Map<String, Object?>>())
        EatOutDish(
          id: d['id']! as String,
          name: d['name']! as String,
          price: Money.baht(d['price']! as num),
        ),
    ]);
  }

  static const assetPath = 'assets/data/eat_out.json';

  final List<EatOutDish> dishes;
}
