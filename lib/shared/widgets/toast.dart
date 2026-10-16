import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme/recipix_tokens.dart';

/// Bottom toast with an optional "เลิกทำ" for 5 seconds — the app's
/// feedback in place of pop-ups.
void showUndoToast(
  BuildContext context,
  String message, {
  VoidCallback? onUndo,
}) {
  final t = context.tokens;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: t.body.copyWith(color: t.surface)),
        backgroundColor: t.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        // Snack bars with an action stay up by default in this Flutter;
        // the spec wants undo offered for 5 seconds only.
        persist: false,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RecipixTokens.radiusMd),
        ),
        action: onUndo == null
            ? null
            : SnackBarAction(
                label: S.undo,
                textColor: t.surface,
                onPressed: onUndo,
              ),
      ),
    );
}
