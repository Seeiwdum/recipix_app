import 'object_finder.dart';

/// Web: ML Kit is not available, so photo mode says so.
ObjectFinder createObjectFinder() => const _NoFinder();

final class _NoFinder implements ObjectFinder {
  const _NoFinder();

  @override
  Future<PhotoFindings?> find(String imagePath) async => null;
}
