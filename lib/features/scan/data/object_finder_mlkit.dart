import 'dart:io';
import 'dart:ui' as ui;

import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import 'object_finder.dart';

ObjectFinder createObjectFinder() => MlKitObjectFinder();

/// ML Kit object detection, single-image mode, several objects per photo.
/// Its coarse classes (food, home goods...) cannot tell pork from chicken,
/// so they are not used: the user says what each box is (ADR-016).
final class MlKitObjectFinder implements ObjectFinder {
  ObjectDetector? _detector;

  ObjectDetector get _ready => _detector ??= ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: false,
      multipleObjects: true,
    ),
  );

  @override
  Future<PhotoFindings?> find(String imagePath) async {
    try {
      final objects = await _ready.processImage(
        InputImage.fromFilePath(imagePath),
      );
      // Boxes come in the upright image's pixels; read that size the same
      // way the photo is shown (orientation applied by the decoder).
      final codec = await ui.instantiateImageCodec(
        await File(imagePath).readAsBytes(),
      );
      final frame = await codec.getNextFrame();
      final size = ui.Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      codec.dispose();
      if (size.isEmpty) return null;
      return PhotoFindings(
        imageSize: size,
        boxes: [
          for (final o in objects)
            ui.Rect.fromLTRB(
              (o.boundingBox.left / size.width).clamp(0, 1),
              (o.boundingBox.top / size.height).clamp(0, 1),
              (o.boundingBox.right / size.width).clamp(0, 1),
              (o.boundingBox.bottom / size.height).clamp(0, 1),
            ),
        ],
      );
    } on Object {
      return null;
    }
  }
}
