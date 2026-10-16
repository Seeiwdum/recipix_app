import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../fridge/domain/fridge_controller.dart';
import '../data/product_lookup.dart';
import 'barcode_memory.dart';

enum ScanPhase { scanning, lookingUp, picked }

/// One barcode's trip from camera to basket (ADR-014).
final class ScanState {
  const ScanState.scanning()
    : phase = ScanPhase.scanning,
      barcode = null,
      knownKey = null,
      lookup = null;

  const ScanState._(this.phase, this.barcode, {this.knownKey, this.lookup});

  final ScanPhase phase;
  final String? barcode;

  /// Catalog key remembered from an earlier scan of the same barcode.
  final String? knownKey;

  /// What the product database said; null when [knownKey] made asking
  /// unnecessary.
  final LookupResult? lookup;
}

final scanProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);

class ScanController extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanState.scanning();

  /// Only retail product codes are looked up, so a QR code with a link (or
  /// anything personal) never leaves the device.
  static bool isProductCode(String code) =>
      RegExp(r'^\d{8}$|^\d{12,14}$').hasMatch(code);

  /// Called for every barcode the camera sees. Ignored while one is being
  /// handled, so a code held in view is not looked up again and again.
  Future<void> onBarcode(String code) async {
    if (state.phase != ScanPhase.scanning || !isProductCode(code)) return;
    final known = ref.read(barcodeMemoryProvider).keys[code];
    if (known != null) {
      state = ScanState._(ScanPhase.picked, code, knownKey: known);
      return;
    }
    state = ScanState._(ScanPhase.lookingUp, code);
    final result = await ref.read(productLookupProvider).find(code);
    // The user may have closed the result in the meantime.
    if (!ref.mounted ||
        state.phase != ScanPhase.lookingUp ||
        state.barcode != code) {
      return;
    }
    state = ScanState._(ScanPhase.picked, code, lookup: result);
  }

  /// Puts one [catalogKey] in the basket, remembers the barcode, and goes
  /// back to scanning. Returns the new item.
  IngredientItem? add(String catalogKey) {
    final code = state.barcode;
    if (code == null) return null;
    final item = ref.read(fridgeProvider.notifier).addFromCatalog(catalogKey);
    if (item == null) return null;
    ref.read(barcodeMemoryProvider.notifier).remember(code, catalogKey);
    state = const ScanState.scanning();
    return item;
  }

  void dismiss() => state = const ScanState.scanning();
}
