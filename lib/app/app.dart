import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/profile/domain/profile_controller.dart';
import 'router.dart';
import 'strings.dart';
import 'theme/recipix_theme.dart';

class RecipixApp extends ConsumerStatefulWidget {
  const RecipixApp({super.key, this.initialLocation = '/home'});

  final String initialLocation;

  @override
  ConsumerState<RecipixApp> createState() => _RecipixAppState();
}

class _RecipixAppState extends ConsumerState<RecipixApp> {
  /// Mirrors "first-launch questions done" for the router's redirect.
  late final _onboarded = ValueNotifier(ref.read(profileProvider).isComplete);

  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
    onboarded: _onboarded,
  );

  @override
  void dispose() {
    _router.dispose();
    _onboarded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      profileProvider.select((p) => p.isComplete),
      (_, done) => _onboarded.value = done,
    );
    return MaterialApp.router(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildRecipixTheme(),
      routerConfig: _router,
    );
  }
}
