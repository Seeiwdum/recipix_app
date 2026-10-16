import 'dart:ui';

import '../../app/theme/recipix_tokens.dart';

/// Status colour for days to expiry, the same on every screen (ADR-012):
/// red only for "expired or today", amber for 1–5 days, nothing after.
/// Before this, 2 days left was amber on home but red in the item sheet.
Color? freshnessColor(RecipixTokens t, int daysLeft, {bool forText = true}) {
  if (daysLeft <= 0) return t.urgent;
  if (daysLeft <= 5) return forText ? t.warnText : t.warn;
  return null;
}
