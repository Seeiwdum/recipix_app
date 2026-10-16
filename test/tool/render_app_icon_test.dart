// Renders the Recipix mark (lib/shared/widgets/recipix_logo.dart) to the
// PNGs flutter_launcher_icons turns into Android / iOS / web icons.
// Skipped in normal runs. To redraw after changing the mark:
//   flutter test --dart-define=RENDER_ICON=true test/tool
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/theme/recipix_tokens.dart';
import 'package:recipix_app/shared/widgets/recipix_logo.dart';

const _render = bool.fromEnvironment('RENDER_ICON');

Future<void> _png(String path, CustomPainter painter) async {
  const size = 1024;
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size(size.toDouble(), size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  const t = RecipixTokens.light;

  testWidgets('render launcher icon PNGs', skip: !_render, (tester) async {
    await tester.runAsync(() async {
      // Full icon: green square, cream mark (iOS, web, old Android).
      await _png(
        'assets/brand/app_icon.png',
        RecipixLogoPainter(background: t.accent, mark: t.bg, cut: t.accent),
      );
      // Android adaptive foreground: mark only. flutter_launcher_icons insets
      // it 16% on each side, which keeps it inside the mask safe zone.
      await _png(
        'assets/brand/app_icon_foreground.png',
        RecipixLogoPainter(mark: t.bg, cut: t.accent, scale: 0.85),
      );
    });
  });
}
