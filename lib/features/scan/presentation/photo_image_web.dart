import 'package:flutter/widgets.dart';

/// Web: the camera gives a blob URL.
Widget photoImage(String path) => Image.network(path, fit: BoxFit.contain);
