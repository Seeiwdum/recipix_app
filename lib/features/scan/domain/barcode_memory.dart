import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../../app/providers.dart';
import '../../../shared/persistence/app_store.dart';
import '../../../shared/persistence/codecs.dart';

/// Barcode -> catalog key, learned when the user picks what a scanned
/// product is (ADR-014), plus the day of the first scan (for the badge).
/// Kept on the device so a repeat scan needs no network.
final class BarcodeBook {
  BarcodeBook({Map<String, String> keys = const {}, this.firstScanOn})
    : keys = Map.unmodifiable(keys);

  final Map<String, String> keys;
  final LocalDate? firstScanOn;
}

final barcodeMemoryProvider = NotifierProvider<BarcodeMemory, BarcodeBook>(
  BarcodeMemory.new,
);

class BarcodeMemory extends Notifier<BarcodeBook> {
  @override
  BarcodeBook build() {
    final store = ref.watch(appStoreProvider);
    if (store != null) {
      listenSelf(
        (_, next) => store.saveBarcodes(
          SavedBarcodes(next.keys, firstScanOn: next.firstScanOn),
        ),
      );
    }
    final saved = ref.watch(savedDataProvider).barcodes;
    return BarcodeBook(
      keys: saved?.keys ?? const {},
      firstScanOn: saved?.firstScanOn,
    );
  }

  /// Records the first scan day without a barcode (photo mode, ADR-016).
  void markScanned() {
    if (state.firstScanOn != null) return;
    state = BarcodeBook(keys: state.keys, firstScanOn: ref.read(todayProvider));
  }

  /// Records that [barcode] is a [catalogKey] (a scan that put something
  /// in the basket).
  void remember(String barcode, String catalogKey) {
    state = BarcodeBook(
      keys: {...state.keys, barcode: catalogKey},
      firstScanOn: state.firstScanOn ?? ref.read(todayProvider),
    );
  }
}
