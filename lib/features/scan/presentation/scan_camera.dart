import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';

/// Builds the camera view. Swapped for a fake in tests (no camera there).
typedef ScanCameraBuilder = Widget Function(
  BuildContext context, {
  required bool active,
  required ValueChanged<String> onCode,
});

final scanCameraProvider = Provider<ScanCameraBuilder>(
  (ref) =>
      (context, {required active, required onCode}) =>
          LiveScanCamera(active: active, onCode: onCode),
);

/// The real camera (`mobile_scanner`, ML Kit on Android). Reads retail
/// barcodes only, and runs only while [active].
class LiveScanCamera extends StatefulWidget {
  const LiveScanCamera({super.key, required this.active, required this.onCode});

  final bool active;
  final ValueChanged<String> onCode;

  @override
  State<LiveScanCamera> createState() => _LiveScanCameraState();
}

class _LiveScanCameraState extends State<LiveScanCamera> {
  final _controller = MobileScannerController(
    autoStart: false,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _run(true);
  }

  @override
  void didUpdateWidget(LiveScanCamera old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _run(widget.active);
  }

  /// Start/stop errors (denied permission, no camera) are shown by the
  /// error builder, so they are not rethrown here.
  Future<void> _run(bool on) async {
    try {
      on ? await _controller.start() : await _controller.stop();
    } on MobileScannerException {
      // Reported through MobileScanner.errorBuilder.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: _controller,
    onDetect: (capture) {
      for (final b in capture.barcodes) {
        final code = b.rawValue;
        if (code != null) {
          widget.onCode(code);
          return;
        }
      }
    },
    errorBuilder: (context, error) => CameraProblem(
      denied: error.errorCode == MobileScannerErrorCode.permissionDenied,
    ),
  );
}

/// What to show when the camera cannot run. Adding by hand stays below.
class CameraProblem extends StatelessWidget {
  const CameraProblem({super.key, required this.denied});

  final bool denied;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      key: const ValueKey('camera-problem'),
      padding: const EdgeInsets.all(RecipixTokens.space4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            denied ? S.scanCameraDenied : S.scanCameraUnavailable,
            textAlign: TextAlign.center,
            style: t.title.copyWith(color: t.surface),
          ),
          const SizedBox(height: RecipixTokens.space2),
          Text(
            denied ? S.scanCameraDeniedHint : S.scanCameraUnavailableHint,
            textAlign: TextAlign.center,
            style: t.body.copyWith(color: t.surface),
          ),
        ],
      ),
    );
  }
}
