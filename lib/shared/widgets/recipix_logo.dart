import 'package:flutter/widgets.dart';

import '../../app/theme/recipix_tokens.dart';

/// The Recipix mark: a two-door fridge in paper cream with a fresh leaf
/// growing from its top — "keep it fresh until payday". Flat shapes only
/// (no gradient, no shadow). The same drawing makes the launcher icons
/// (`test/tool/render_app_icon_test.dart`) and `assets/brand/logo.svg`.
class RecipixLogo extends StatelessWidget {
  const RecipixLogo({super.key, this.size = 72, this.withBackground = true});

  final double size;

  /// Green square behind the mark (app icon look). Off: the mark alone,
  /// drawn in the accent colour, for paper backgrounds.
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Recipix',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(withBackground ? size * 0.22 : 0),
          child: CustomPaint(
            painter: RecipixLogoPainter(
              background: withBackground ? t.accent : null,
              mark: withBackground ? t.bg : t.accent,
              cut: withBackground ? t.accent : t.bg,
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the mark on a square canvas. [scale] shrinks the mark around the
/// centre (Android adaptive icons need it inside the middle ~60%).
class RecipixLogoPainter extends CustomPainter {
  const RecipixLogoPainter({
    required this.mark,
    required this.cut,
    this.background,
    this.scale = 1,
  });

  // Artwork geometry on the 1024 grid (like rx in logo.svg), not UI
  // chrome, so it does not come from the radius tokens.
  static const double _bodyCorner = 64;
  static const double _handleCorner = 15;

  /// Fridge and leaf.
  final Color mark;

  /// Door gap, handles and leaf vein (the background showing through).
  final Color cut;
  final Color? background;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = background;
    if (bg != null) canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    // All geometry on a 1024 grid.
    final u = size.shortestSide / 1024;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(u * scale)
      ..translate(-512, -512);

    final fill = Paint()..color = mark;
    final cutFill = Paint()..color = cut;

    // Leaf: base on the fridge's top-right shoulder, tip up and right.
    final leaf = Path()
      ..moveTo(600, 250)
      ..cubicTo(592, 170, 644, 110, 746, 96)
      ..cubicTo(756, 192, 704, 250, 600, 250)
      ..close();
    canvas.drawPath(leaf, fill);
    // Vein stops short of the base so it never notches the fridge top.
    canvas.drawLine(
      const Offset(634, 218),
      const Offset(714, 132),
      Paint()
        ..color = cut
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );

    // Fridge body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(320, 248, 384, 600),
        const Radius.circular(_bodyCorner),
      ),
      fill,
    );
    // Door gap: freezer on top, fridge below.
    canvas.drawRect(const Rect.fromLTWH(320, 446, 384, 24), cutFill);
    // Handles.
    for (final r in const [
      Rect.fromLTWH(380, 318, 30, 88),
      Rect.fromLTWH(380, 518, 30, 150),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(_handleCorner)),
        cutFill,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(RecipixLogoPainter old) =>
      old.mark != mark ||
      old.cut != cut ||
      old.background != background ||
      old.scale != scale;
}
