// Automated parts of COMPANY_RULES R2.3 / R3 and the UI checklist 5.5.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/shared/icons/recipix_icon.dart';

final _emoji = RegExp(
  '[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]',
  unicode: true,
);

Iterable<File> _files(String dir, String ext) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith(ext));

String _rel(File f) => f.path.replaceAll(r'\', '/');

void main() {
  test('no emoji in source, assets or core', () {
    final offenders = [
      for (final dir in ['lib', 'packages/recipix_core/lib', 'assets'])
        for (final ext in ['.dart', '.svg', '.json'])
          if (Directory(dir).existsSync())
            for (final f in _files(dir, ext))
              if (_emoji.hasMatch(f.readAsStringSync())) _rel(f),
    ];
    expect(offenders, isEmpty);
  });

  test('colors are defined only in the theme folder', () {
    final offenders = [
      for (final f in _files('lib', '.dart'))
        if (!_rel(f).contains('lib/app/theme/') &&
            RegExp(r'Color\(0x|Colors\.(?!transparent)')
                .hasMatch(f.readAsStringSync()))
          _rel(f),
    ];
    expect(offenders, isEmpty);
  });

  test('no literal radii outside tokens', () {
    final offenders = [
      for (final f in _files('lib', '.dart'))
        if (!_rel(f).contains('lib/app/theme/') &&
            RegExp(r'(BorderRadius|Radius)\.circular\(\d')
                .hasMatch(f.readAsStringSync()))
          _rel(f),
    ];
    expect(offenders, isEmpty);
  });

  test('no gradients, blur or infinite repeats in UI code', () {
    final banned = RegExp(
      r'LinearGradient|RadialGradient|SweepGradient|BackdropFilter|ImageFilter\.blur|\.repeat\(',
    );
    final offenders = [
      for (final f in _files('lib', '.dart'))
        if (banned.hasMatch(f.readAsStringSync())) _rel(f),
    ];
    expect(offenders, isEmpty);
  });

  test('every icon exists and follows the stroke spec', () {
    for (final icon in RecipixIcons.values) {
      final file = File(icon.asset);
      expect(file.existsSync(), isTrue, reason: icon.asset);
      final svg = file.readAsStringSync();
      expect(svg, contains('viewBox="0 0 24 24"'), reason: icon.asset);
      expect(svg, contains('stroke="currentColor"'), reason: icon.asset);
      expect(svg, contains('stroke-width="1.75"'), reason: icon.asset);
      expect(svg, contains('stroke-linecap="round"'), reason: icon.asset);
    }
  });

  test('recipix_core does not import Flutter', () {
    final offenders = [
      for (final f in _files('packages/recipix_core/lib', '.dart'))
        if (f.readAsStringSync().contains('package:flutter')) _rel(f),
    ];
    expect(offenders, isEmpty);
  });
}
