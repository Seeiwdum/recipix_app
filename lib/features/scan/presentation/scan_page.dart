import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../fridge/presentation/add_item_sheet.dart';
import '../domain/scan_controller.dart';
import 'scan_camera.dart';
import 'scan_result_sheet.dart';

/// Barcode scan (ADR-014): camera with an aiming frame, then a sheet to
/// say what the product is. Adding by hand is always one tap away.
class ScanPage extends ConsumerWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final scan = ref.watch(scanProvider);
    final camera = ref.watch(scanCameraProvider);
    // Camera only while this tab is on screen and nothing is being handled.
    final active =
        TickerMode.valuesOf(context).enabled &&
        scan.phase == ScanPhase.scanning;

    ref.listen(scanProvider.select((s) => s.phase), (prev, next) {
      if (next == ScanPhase.picked && prev != ScanPhase.picked) {
        HapticFeedback.selectionClick();
        showScanResultSheet(context);
      }
    });

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
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(RecipixTokens.radiusLg),
                child: ColoredBox(
                  color: t.ink,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      camera(
                        context,
                        active: active,
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
            Text(S.scanHint, style: t.bodyMuted, textAlign: TextAlign.center),
            TextButton(
              key: const ValueKey('scan-add-by-hand'),
              onPressed: () => showAddItemSheet(context),
              child: Text(S.scanNoBarcode),
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
