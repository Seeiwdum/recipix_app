import 'package:flutter/widgets.dart';

/// True when the OS asks for reduced motion. All animated widgets check
/// this and fall back to a 120ms fade.
bool reduceMotionOf(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
