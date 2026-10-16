import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/strings.dart';
import '../../../app/theme/recipix_tokens.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/toast.dart';
import '../../fridge/presentation/catalog_grid.dart';
import '../domain/photo_scan_controller.dart';
import 'photo_camera.dart';

/// The framed area of photo mode (ADR-016): live camera with a shutter,
/// then the photo with a box around each thing found. Tap a box to say
/// what it is.
class PhotoModeView extends ConsumerWidget {
  const PhotoModeView({super.key, required this.visible});

  /// The scan tab is on screen and photo mode is chosen.
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final s = ref.watch(photoScanProvider);
    final ctrl = ref.read(photoScanProvider.notifier);

    if (s.phase == PhotoPhase.camera) {
      return ref.watch(photoCameraProvider)(
        context,
        active: visible,
        onCaptured: ctrl.captured,
      );
    }
    final photo = ref.watch(photoImageProvider)(s.imagePath!);
    final findings = s.findings;
    return Stack(
      fit: StackFit.expand,
      children: [
        photo,
        if (findings != null)
          LayoutBuilder(
            builder: (context, c) {
              final shown = _shownRect(findings.imageSize, c.biggest);
              return Stack(
                children: [
                  for (final (i, box) in findings.boxes.indexed)
                    Positioned.fromRect(
                      rect: Rect.fromLTRB(
                        shown.left + box.left * shown.width,
                        shown.top + box.top * shown.height,
                        shown.left + box.right * shown.width,
                        shown.top + box.bottom * shown.height,
                      ),
                      child: _Box(
                        index: i,
                        pickedKey: s.picked[i],
                        onTap: () => _pick(context, ref, i),
                      ),
                    ),
                ],
              );
            },
          ),
        if (s.phase == PhotoPhase.finding)
          Align(
            alignment: Alignment.bottomCenter,
            child: Semantics(
              liveRegion: true,
              label: S.photoFinding,
              // A real loader: runs only while ML Kit is looking.
              child: LinearProgressIndicator(
                key: const ValueKey('photo-finding'),
                minHeight: RecipixTokens.space1,
                color: t.accent,
                backgroundColor: t.surface,
              ),
            ),
          ),
      ],
    );
  }

  /// Where a photo of [image] size lands inside [box] with BoxFit.contain,
  /// centred — the same fit the photo widget uses.
  static Rect _shownRect(Size image, Size box) {
    final fitted = applyBoxFit(BoxFit.contain, image, box).destination;
    return Alignment.center.inscribe(fitted, Offset.zero & box);
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, int index) {
    final t = context.tokens;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      elevation: 0,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RecipixTokens.radiusLg),
        ),
      ),
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            RecipixTokens.space3,
            0,
            RecipixTokens.space3,
            RecipixTokens.space3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(S.photoPickTitle, style: t.title),
              ),
              Text(S.photoBox(index + 1), style: t.caption),
              const SizedBox(height: RecipixTokens.space2),
              Flexible(
                child: CatalogGrid(
                  onPick: (entry) {
                    final item = ref
                        .read(photoScanProvider.notifier)
                        .pick(index, entry.key);
                    Navigator.of(sheetContext).pop();
                    if (item != null) {
                      HapticFeedback.selectionClick();
                      showUndoToast(context, S.scanAdded(item.name));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One found thing: a plain outline until the user says what it is, then
/// an accent outline with the name.
class _Box extends ConsumerWidget {
  const _Box({
    required this.index,
    required this.pickedKey,
    required this.onTap,
  });

  final int index;
  final String? pickedKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final done = pickedKey != null;
    final name = done ? ref.watch(catalogProvider)[pickedKey!]?.name : null;
    return Pressable(
      key: ValueKey('photo-box-$index'),
      semanticLabel: name ?? S.photoBox(index + 1),
      selected: done,
      onTap: done ? null : onTap,
      child: Container(
        alignment: Alignment.topLeft,
        decoration: BoxDecoration(
          border: Border.all(
            color: done ? t.accent : t.surface,
            width: RecipixTokens.statusLineWidth,
          ),
          borderRadius: BorderRadius.circular(RecipixTokens.radiusSm),
        ),
        child: name == null
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RecipixTokens.space1,
                ),
                color: t.accent,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.label.copyWith(color: t.surface),
                ),
              ),
      ),
    );
  }
}

/// The caption under the frame for photo mode.
String photoCaption(PhotoScanState s) => switch (s.phase) {
  PhotoPhase.camera => S.photoHint,
  PhotoPhase.finding => S.photoFinding,
  PhotoPhase.failed => S.photoFailed,
  PhotoPhase.boxes when (s.findings?.boxes.isEmpty ?? true) => S.photoNone,
  PhotoPhase.boxes when s.picked.isNotEmpty => S.photoAdded(s.picked.length),
  PhotoPhase.boxes => S.photoTapBox,
};
