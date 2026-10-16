import 'package:flutter/widgets.dart';

import '../../../app/strings.dart';
import '../../../shared/widgets/recipix_page.dart';

/// Placeholder until the tab is built in Phase 2.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const RecipixPage(
    title: S.homeTitle,
    children: [
      ComingSoonNote(status: S.underConstruction, text: S.homeComingSoon),
    ],
  );
}
