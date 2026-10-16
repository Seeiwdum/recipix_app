import 'dart:ui' show Rect, Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'object_finder_stub.dart'
    if (dart.library.io) 'object_finder_mlkit.dart'
    as impl;

/// Where things are in a photo (ADR-016). Boxes are fractions of the image
/// (0..1), so they can be laid over the photo at any size.
final class PhotoFindings {
  PhotoFindings({required this.imageSize, required List<Rect> boxes})
    : boxes = List.unmodifiable(boxes);

  final Size imageSize;
  final List<Rect> boxes;
}

/// Finds the separate objects in a photo. On-device only: the photo never
/// leaves the phone.
abstract interface class ObjectFinder {
  /// Null when this device cannot look (web, ML Kit error).
  Future<PhotoFindings?> find(String imagePath);
}

final objectFinderProvider = Provider<ObjectFinder>(
  (ref) => impl.createObjectFinder(),
);
