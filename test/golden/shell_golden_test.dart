// Goldens at the three checklist widths. Regenerate deliberately with:
//   flutter test --update-goldens test/golden
@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/app.dart';
import 'package:recipix_app/app/strings.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('home shell at ${width.toInt()}', (tester) async {
      setPhoneSize(tester, width);
      await tester.pumpWidget(const RecipixApp());
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RecipixApp),
        matchesGoldenFile('goldens/home_${width.toInt()}.png'),
      );
    });

    testWidgets('fridge art preview at ${width.toInt()}', (tester) async {
      setPhoneSize(tester, width);
      await tester.pumpWidget(const RecipixApp(initialLocation: '/fridge'));
      await tester.pumpAndSettle();
      expect(find.text(S.fridgeComingSoon), findsOneWidget);
      await expectLater(
        find.byType(RecipixApp),
        matchesGoldenFile('goldens/fridge_${width.toInt()}.png'),
      );
    });
  }
}
