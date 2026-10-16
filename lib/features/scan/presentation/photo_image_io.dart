import 'dart:io';

import 'package:flutter/widgets.dart';

/// Android/iOS: the camera writes a temporary file.
Widget photoImage(String path) => Image.file(File(path), fit: BoxFit.contain);
