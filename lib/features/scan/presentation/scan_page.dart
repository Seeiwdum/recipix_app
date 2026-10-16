import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/widgets/mode_picker.dart';
import '../../fridge/presentation/add_item_sheet.dart';
import '../domain/photo_scan_controller.dart';
import '../domain/scan_controller.dart';
import 'photo_mode.dart';
import 'scan_camera.dart';
import 'scan_result_sheet.dart';

/// Scan tab, two modes:
/// - barcode (ADR-014): camera with an aiming frame, then a sheet to say
///   what the product is;
/// - photo (ADR-016): one photo, a box around each thing found, tap a box
///   to say what it is.
/// Adding by hand is always one tap away. Only the chosen mode's camera is
/// open, and only while the tab is on screen.
class ScanPage extends ConsumerWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final mode = ref.watch(scanModeProvider);
    final scan = ref.watch(scanProvider);
    final photo = ref.watch(photoScanProvider);
    final camera = ref.watch(scanCameraProvider);
    final onScreen = TickerMode.valuesOf(context).enabled;
    final barcodeActive =
        onScreen &&
        mode == ScanMode.barcode &&
        scan.phase == ScanPhase.scanning;

    ref.listen(scanProvider.select((s) => s.phase), (prev, next) {
      if (next == ScanPhase.picked && prev != ScanPhase.picked) {
        HapticFeedback.selectionClick();
        showScanResultSheet(context);
      }
    });

    final caption = mode == ScanMode.barcode ? S.scanHint : photoCaption(photo);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RecipixTokens.space3,
          RecipixTokens.space3,
          RecipixTokens.space3,
          RecipixTokens.space2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(S.scanTitle, style: t.pageTitle),
            ),
            const SizedBox(height: RecipixTokens.space3),
            ModePicker(
              labels: const {
                ScanMode.barcode: S.scanModeBarcode,
                ScanMode.photo: S.scanModePhoto,
              },
              value: mode,
              onChanged: ref.read(scanModeProvider.notifier).set,
            ),
            const SizedBox(height: RecipixTokens.space3),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(RecipixTokens.radiusLg),
                child: ColoredBox(
                  color: t.ink,
                  child: mode == ScanMode.photo
                      ? PhotoModeView(visible: onScreen)
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            camera(
                              context,
                              active: barcodeActive,
                              onCode: ref.read(scanProvider.notifier).onBarcode,
                            ),
                            const IgnorePointer(child: _AimFrame()),
                            if (scan.phase == ScanPhase.lookingUp)
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Semantics(
                                  liveRegion: true,
                                  label: S.scanLooking,
                                  // A real loader: runs only while waiting.
                                  child: LinearProgressIndicator(
                                    key: const ValueKey('scan-looking'),
                                    minHeight: RecipixTokens.space1,
                                    color: t.accent,
                                    backgroundColor: t.surface,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: RecipixTokens.space2),
            Text(
              caption,
              key: const ValueKey('scan-caption'),
              style: t.bodyMuted,
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (mode == ScanMode.photo && photo.phase != PhotoPhase.camera)
                  TextButton(
                    key: const ValueKey('photo-retake'),
                    onPressed: ref.read(photoScanProvider.notifier).retake,
                    child: Text(S.photoRetake),
                  ),
                TextButton(
                  key: const ValueKey('scan-add-by-hand'),
                  onPressed: () => showAddItemSheet(context),
                  child: Text(
                    mode == ScanMode.barcode ? S.scanNoBarcode : S.addByHand,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Four corner marks around the middle: where to hold the barcode.
class _AimFrame extends StatelessWidget {
  const _AimFrame();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return CustomPaint(
      painter: _CornersPainter(
        color: t.surface,
        width: RecipixTokens.statusLineWidth,
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  _CornersPainter({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * 0.72;
    final h = (size.height * 0.36).clamp(0.0, w * 0.7);
    final r = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );
    final arm = r.shortestSide * 0.18;
    final p = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final (corner, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(corner, corner + Offset(arm * dx, 0), p)
        ..drawLine(corner, corner + Offset(0, arm * dy), p);
    }
  }

  @override
  bool shouldRepaint(_CornersPainter old) =>
      old.color != color || old.width != width;
}
