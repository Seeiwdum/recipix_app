import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import 'photo_image.dart';
import 'scan_camera.dart';

/// Builds the photo-mode camera (preview + shutter). Swapped for a fake in
/// tests. [onCaptured] gets the path of the photo taken.
typedef PhotoCameraBuilder = Widget Function(
  BuildContext context, {
  required bool active,
  required ValueChanged<String> onCaptured,
});

final photoCameraProvider = Provider<PhotoCameraBuilder>(
  (ref) =>
      (context, {required active, required onCaptured}) =>
          LivePhotoCamera(active: active, onCaptured: onCaptured),
);

/// Shows a taken photo. Swapped in tests (no file there).
final photoImageProvider = Provider<Widget Function(String path)>(
  (ref) => photoImage,
);

/// Round shutter at the bottom of the preview: the photo mode's one action.
class ShutterButton extends StatelessWidget {
  const ShutterButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    const size = RecipixTokens.tapTarget + RecipixTokens.space3;
    return Semantics(
      button: true,
      label: S.shutter,
      child: GestureDetector(
        key: const ValueKey('shutter'),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(RecipixTokens.space1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: t.surface,
              width: RecipixTokens.statusLineWidth,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onTap == null ? t.ink2 : t.surface,
            ),
          ),
        ),
      ),
    );
  }
}

/// The real camera (`camera` package). Opened only while [active], and
/// released otherwise so the barcode camera and other apps can use it.
class LivePhotoCamera extends StatefulWidget {
  const LivePhotoCamera({
    super.key,
    required this.active,
    required this.onCaptured,
  });

  final bool active;
  final ValueChanged<String> onCaptured;

  @override
  State<LivePhotoCamera> createState() => _LivePhotoCameraState();
}

class _LivePhotoCameraState extends State<LivePhotoCamera> {
  CameraController? _controller;
  bool? _denied;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _open();
  }

  @override
  void didUpdateWidget(LivePhotoCamera old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) widget.active ? _open() : _close();
  }

  Future<void> _open() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('NoCamera', null);
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        // Photos only: no microphone permission needed.
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted || !widget.active) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _denied = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _denied = e.code.contains('Denied'));
    }
  }

  Future<void> _close() async {
    final c = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await c?.dispose();
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (c == null || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      widget.onCaptured(file.path);
    } on CameraException {
      // A missed shot leaves the camera ready for another try.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final denied = _denied;
    if (denied != null) return CameraProblem(denied: denied);
    final c = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (c != null && c.value.isInitialized)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              // Preview size is landscape; the phone is held upright.
              width: c.value.previewSize?.height ?? 1,
              height: c.value.previewSize?.width ?? 1,
              child: CameraPreview(c),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: RecipixTokens.space3),
            child: ShutterButton(onTap: c == null || _busy ? null : _shoot),
          ),
        ),
      ],
    );
  }
}
