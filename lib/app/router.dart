import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/fridge/presentation/fridge_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/random/presentation/random_page.dart';
import '../features/scan/presentation/scan_page.dart';
import 'shell/app_shell.dart';

GoRouter buildRouter({String initialLocation = '/home'}) {
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
    routes: [
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
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
