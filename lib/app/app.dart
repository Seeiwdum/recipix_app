import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'strings.dart';
import 'theme/recipix_theme.dart';

class RecipixApp extends StatefulWidget {
  const RecipixApp({super.key, this.initialLocation = '/home'});

  final String initialLocation;

  @override
  State<RecipixApp> createState() => _RecipixAppState();
}

class _RecipixAppState extends State<RecipixApp> {
  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: S.appName,
    debugShowCheckedModeBanner: false,
    theme: buildRecipixTheme(),
    routerConfig: _router,
  );
}
