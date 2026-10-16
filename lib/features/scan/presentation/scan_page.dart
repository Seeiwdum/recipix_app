import 'package:flutter/widgets.dart';

import '../../../app/strings.dart';
import '../../../shared/widgets/recipix_page.dart';

/// Placeholder until the tab is built in Phase 2.
class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) => const RecipixPage(
    title: S.scanTitle,
    children: [ComingSoonNote(status: S.scanNotYet, text: S.scanComingSoon)],
  );
}
