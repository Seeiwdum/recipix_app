import 'package:flutter/material.dart';

import '../../app/theme/recipix_tokens.dart';

/// How big an [Amount] is set.
enum AmountSize { display, title, body }

/// The app's one way to write a number with its unit (ADR-012):
/// tabular figures in ink, the unit about half the size in the secondary
/// ink, on the same baseline. The same figure looks the same everywhere.
class Amount extends StatelessWidget {
  const Amount(
    this.value, {
    super.key,
    this.unit,
    this.size = AmountSize.body,
    this.color,
  });

  final String value;
  final String? unit;
  final AmountSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final base = switch (size) {
      AmountSize.display => t.display,
      AmountSize.title => t.title.copyWith(
        fontFeatures: RecipixTokens.tabularFigures,
      ),
      AmountSize.body => t.number,
    };
    final numberStyle = base.copyWith(color: color ?? t.ink);
    final unitSize = size == AmountSize.body
        ? t.caption.fontSize!
        : base.fontSize! * RecipixTokens.unitScale;
    return Text.rich(
      TextSpan(
        text: value,
        style: numberStyle,
        children: [
          if (unit != null)
            TextSpan(
              text: ' $unit',
              style: t.caption.copyWith(
                fontSize: unitSize,
                fontWeight: FontWeight.w500,
                color: t.ink2,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
    );
  }
}

/// A line that reads a value: label on the left, value on the right, a
/// dot leader between them — the receipt / account-book line that is the
/// Recipix signature (ADR-012). Use only where a value is being read.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.ruled = false,
    this.leader = true,
  });

  final String label;
  final Widget value;
  final TextStyle? labelStyle;

  /// Hairline under the row, for lists of rows.
  final bool ruled;
  final bool leader;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: RecipixTokens.space1 + 2),
      decoration: ruled
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: t.line)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            flex: 0,
            child: Text(
              label,
              style: labelStyle ?? t.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (leader) const Expanded(child: DotLeader()) else const Spacer(),
          value,
        ],
      ),
    );
  }
}

/// A row of small dots sitting near the text baseline.
class DotLeader extends StatelessWidget {
  const DotLeader({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      RecipixTokens.space1 + 2,
      0,
      RecipixTokens.space1 + 2,
      RecipixTokens.space1 + 3,
    ),
    child: SizedBox(
      height: RecipixTokens.leaderDot * 2,
      child: CustomPaint(painter: _DotsPainter(context.tokens.ink2)),
    ),
  );
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.45);
    const step = RecipixTokens.leaderDot * 2 + RecipixTokens.leaderGap;
    final y = size.height / 2;
    for (var x = RecipixTokens.leaderDot; x < size.width; x += step) {
      canvas.drawCircle(Offset(x, y), RecipixTokens.leaderDot, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}
