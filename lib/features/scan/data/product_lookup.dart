import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// What a barcode lookup came back with.
sealed class LookupResult {
  const LookupResult();
}

/// The database knows the product. [name] may still be empty when the
/// entry has no name in any language we read.
final class ProductFound extends LookupResult {
  const ProductFound({required this.name, this.brand});

  final String name;
  final String? brand;
}

final class ProductNotFound extends LookupResult {
  const ProductNotFound();
}

/// No answer (offline, timeout, server error, rate limit). The user can
/// still pick the item by hand.
final class LookupFailed extends LookupResult {
  const LookupFailed();
}

/// Turns a barcode number into a product name (ADR-014).
abstract interface class ProductLookup {
  Future<LookupResult> find(String barcode);
}

/// Open Food Facts API v3. Only the barcode number leaves the device; no
/// account is needed. The server allows 15 reads a minute per IP and asks
/// every app to identify itself.
final class OpenFoodFactsLookup implements ProductLookup {
  OpenFoodFactsLookup([http.Client? client])
    : _client = client ?? http.Client();

  static const _host = 'world.openfoodfacts.org';
  static const userAgent =
      'Recipix/0.1 (https://github.com/Seeiwdum/recipix_app)';
  static const timeout = Duration(seconds: 8);

  final http.Client _client;

  @override
  Future<LookupResult> find(String barcode) async {
    final uri = Uri.https(_host, '/api/v3/product/$barcode', {
      'fields': 'product_name,product_name_th,brands',
    });
    try {
      final res = await _client
          .get(uri, headers: {'User-Agent': userAgent})
          .timeout(timeout);
      // A missing product is a 404 with a JSON body saying so.
      if (res.statusCode != 200 && res.statusCode != 404) {
        return const LookupFailed();
      }
      return parse(jsonDecode(utf8.decode(res.bodyBytes)));
    } on Object {
      return const LookupFailed();
    }
  }

  /// Reads a v3 product response. Thai name first, then the default one.
  static LookupResult parse(Object? json) {
    if (json is! Map<String, Object?>) return const LookupFailed();
    if (json['status'] != 'success') {
      final result = json['result'];
      final id = result is Map<String, Object?> ? result['id'] : null;
      return id == 'product_not_found'
          ? const ProductNotFound()
          : const LookupFailed();
    }
    final p = json['product'];
    if (p is! Map<String, Object?>) return const ProductNotFound();
    String? text(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    final brands = text(p['brands']);
    return ProductFound(
      name: text(p['product_name_th']) ?? text(p['product_name']) ?? '',
      brand: brands?.split(',').first.trim(),
    );
  }
}

final productLookupProvider = Provider<ProductLookup>(
  (ref) => OpenFoodFactsLookup(),
);
