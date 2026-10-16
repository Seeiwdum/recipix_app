import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipix_core/recipix_core.dart';

import '../../fridge/domain/fridge_controller.dart';
import '../data/object_finder.dart';
import 'barcode_memory.dart';

enum PhotoPhase {
  /// Camera live, waiting for the shutter.
  camera,

  /// Photo taken, looking for objects in it.
  finding,

  /// Boxes shown (possibly none); the user taps one to say what it is.
  boxes,

  /// This device could not look at the photo (web, ML Kit error).
  failed,
}

/// Photo mode of the scan tab (ADR-016).
final class PhotoScanState {
  PhotoScanState({
    required this.phase,
    this.imagePath,
    this.findings,
    Map<int, String> picked = const {},
  }) : picked = Map.unmodifiable(picked);

  PhotoScanState.camera() : this(phase: PhotoPhase.camera);

  final PhotoPhase phase;
  final String? imagePath;
  final PhotoFindings? findings;

  /// Box index -> catalog key the user said it is.
  final Map<int, String> picked;
}

enum ScanMode { barcode, photo }

final scanModeProvider = NotifierProvider<ScanModeController, ScanMode>(
  ScanModeController.new,
);

class ScanModeController extends Notifier<ScanMode> {
  @override
  ScanMode build() => ScanMode.barcode;

  void set(ScanMode mode) => state = mode;
}

final photoScanProvider = NotifierProvider<PhotoScanController, PhotoScanState>(
  PhotoScanController.new,
);

class PhotoScanController extends Notifier<PhotoScanState> {
  @override
  PhotoScanState build() => PhotoScanState.camera();

  /// The shutter fired and the photo is on disk.
  Future<void> captured(String imagePath) async {
    if (state.phase != PhotoPhase.camera) return;
    state = PhotoScanState(phase: PhotoPhase.finding, imagePath: imagePath);
    final findings = await ref.read(objectFinderProvider).find(imagePath);
    if (!ref.mounted || state.imagePath != imagePath) return;
    state = PhotoScanState(
      phase: findings == null ? PhotoPhase.failed : PhotoPhase.boxes,
      imagePath: imagePath,
      findings: findings,
    );
  }

  /// Puts one [catalogKey] in the basket for box [index]. A box already
  /// picked is not added twice.
  IngredientItem? pick(int index, String catalogKey) {
    final boxes = state.findings?.boxes ?? const [];
    if (state.phase != PhotoPhase.boxes ||
        index < 0 ||
        index >= boxes.length ||
        state.picked.containsKey(index)) {
      return null;
    }
    final item = ref.read(fridgeProvider.notifier).addFromCatalog(catalogKey);
    if (item == null) return null;
    ref.read(barcodeMemoryProvider.notifier).markScanned();
    state = PhotoScanState(
      phase: state.phase,
      imagePath: state.imagePath,
      findings: state.findings,
      picked: {...state.picked, index: catalogKey},
    );
    return item;
  }

  /// Back to the live camera for another photo.
  void retake() => state = PhotoScanState.camera();
}
