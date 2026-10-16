import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/fridge/presentation/fridge_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/home/presentation/meal_plan_page.dart';
import '../features/home/presentation/recipe_page.dart';
import '../features/profile/presentation/onboarding_page.dart';
import '../features/random/presentation/random_page.dart';
import '../features/scan/presentation/scan_page.dart';
import '../shared/motion/motion.dart';
import 'shell/app_shell.dart';
import 'theme/recipix_tokens.dart';

/// Detail pages fade in rising 8px (the tab-change motion), and leave with
/// a quick fade. Reduced motion: fade only.
Page<void> _detailPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: RecipixTokens.medium,
      reverseTransitionDuration: RecipixTokens.fast,
      transitionsBuilder: (context, animation, _, child) {
        final t = CurvedAnimation(
          parent: animation,
          curve: RecipixTokens.enter,
          reverseCurve: RecipixTokens.exit,
        );
        final rise = reduceMotionOf(context) ? 0.0 : RecipixTokens.riseOffset;
        return FadeTransition(
          opacity: t,
          child: AnimatedBuilder(
            animation: t,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, rise * (1 - t.value)),
              child: child,
            ),
            child: child,
          ),
        );
      },
    );

/// [onboarded] gates the app (ADR-017): until the first-launch questions
/// are done every location goes to `/welcome`, and afterwards `/welcome`
/// goes home.
GoRouter buildRouter({
  String initialLocation = '/home',
  ValueListenable<bool>? onboarded,
}) {
  const pages = <Widget>[
    HomePage(),
    FridgePage(),
    ScanPage(),
    RandomPage(),
    DashboardPage(),
  ];
  assert(pages.length == appTabs.length);

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: onboarded,
    redirect: (context, state) {
      final done = onboarded?.value ?? true;
      final atWelcome = state.matchedLocation == '/welcome';
      if (!done && !atWelcome) return '/welcome';
      if (done && atWelcome) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) =>
            _detailPage(state, const OnboardingPage()),
      ),
      StatefulShellRoute(
        builder: (context, state, shell) => shell,
        navigatorContainerBuilder: (context, shell, children) =>
            AppShell(shell: shell, children: children),
        branches: [
          for (var i = 0; i < appTabs.length; i++)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: appTabs[i].path,
                  pageBuilder: (context, state) =>
                      NoTransitionPage(key: state.pageKey, child: pages[i]),
                  routes: [
                    if (appTabs[i].path == '/home')
                      GoRoute(
                        path: 'plan',
                        pageBuilder: (context, state) =>
                            _detailPage(state, const MealPlanPage()),
                      ),
                    if (appTabs[i].path == '/home')
                      GoRoute(
                        path: 'recipe/:id',
                        pageBuilder: (context, state) => _detailPage(
                          state,
                          RecipePage(recipeId: state.pathParameters['id']!),
                        ),
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
