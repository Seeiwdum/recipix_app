// Design-review screenshots (UI refinement sprint). Not part of the normal
// suite: runs only when a set is named, and writes PNGs into docs.
//
//   flutter test --update-goldens --dart-define=SHOTS=before test/design
//   flutter test --update-goldens --dart-define=SHOTS=after test/design
@Tags(['shots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipix_app/app/app.dart';
import 'package:recipix_app/app/providers.dart';
import 'package:recipix_app/features/fridge/domain/fridge_layout.dart';
import 'package:recipix_app/features/random/domain/random_controller.dart';
import 'package:recipix_app/shared/persistence/app_store.dart';
import 'package:recipix_app/shared/persistence/codecs.dart';
import 'package:recipix_app/app/strings.dart';

import '../helpers.dart';

const shotSet = String.fromEnvironment('SHOTS');

Widget emptyFridgeApp(String location) => ProviderScope(
  overrides: [
    catalogProvider.overrideWithValue(testCatalog),
    recipeBookProvider.overrideWithValue(testRecipes),
    eatOutMenuProvider.overrideWithValue(testEatOut),
    todayProvider.overrideWithValue(testToday),
    savedDataProvider.overrideWithValue(
      SavedData(
        fridge: SavedFridge(
          items: const [],
          arrangement: FridgeArrangement(),
          cooked: const [],
        ),
      ),
    ),
  ],
  child: RecipixApp(initialLocation: location),
);

typedef Setup = Future<void> Function(WidgetTester tester);

void main() {
  setUpAll(loadAppFonts);

  final shots = <String, (Widget Function(), Setup?)>{
    'home_normal': (() => testApp(), null),
    'home_scrolled': (
      () => testApp(),
      (t) async {
        await t.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -700),
        );
        await t.pumpAndSettle();
      },
    ),
    'home_empty': (() => emptyFridgeApp('/home'), null),
    'home_spending-sheet': (
      () => testApp(),
      (t) async {
        await t.scrollUntilVisible(
          find.byKey(const ValueKey('log-spending')),
          100,
        );
        await t.tap(find.byKey(const ValueKey('log-spending')));
        await t.pumpAndSettle();
      },
    ),
    'home_plan': (() => testApp(initialLocation: '/home/plan'), null),
    'fridge_normal': (() => testApp(initialLocation: '/fridge'), null),
    'fridge_item-sheet': (
      () => testApp(initialLocation: '/fridge'),
      (t) async {
        await t.tap(find.byKey(const ValueKey('item-holy_basil-6')));
        await t.pumpAndSettle();
      },
    ),
    'fridge_filter-use-soon': (
      () => testApp(initialLocation: '/fridge'),
      (t) async {
        await t.tap(find.bySemanticsLabel(S.filterUseSoon));
        await t.pumpAndSettle();
      },
    ),
    'fridge_empty': (() => emptyFridgeApp('/fridge'), null),
    'scan_placeholder': (() => testApp(initialLocation: '/scan'), null),
    'random_initial': (() => testApp(initialLocation: '/random'), null),
    'random_result': (
      () => testApp(initialLocation: '/random'),
      (t) async {
        await t.tap(find.byKey(const ValueKey('spin')));
        await settleSpin(t);
      },
    ),
    'random_eat-out-result': (
      () => testApp(initialLocation: '/random'),
      (t) async {
        await t.tap(find.bySemanticsLabel(S.modeEatOut));
        await t.pump();
        await t.tap(find.byKey(const ValueKey('spin')));
        await settleSpin(t);
      },
    ),
    'random_empty-fridge': (
      () => emptyFridgeApp('/random'),
      (t) async {
        await t.tap(find.byKey(const ValueKey('spin')));
        await settleSpin(t);
      },
    ),
    'dashboard_top': (() => testApp(initialLocation: '/dashboard'), null),
    'dashboard_badges': (
      () => testApp(initialLocation: '/dashboard'),
      (t) async {
        await t.drag(find.byType(ListView).first, const Offset(0, -600));
        await t.pumpAndSettle();
      },
    ),
  };

  for (final width in [360.0, 390.0, 430.0]) {
    for (final entry in shots.entries) {
      testWidgets('${entry.key} ${width.toInt()}', skip: shotSet.isEmpty, (
        tester,
      ) async {
        setPhoneSize(tester, width, height: 844);
        await tester.pumpWidget(entry.value.$1());
        await tester.pumpAndSettle();
        await entry.value.$2?.call(tester);
        await expectLater(
          find.byType(RecipixApp),
          matchesGoldenFile(
            '../../docs/design/shots/$shotSet/'
            '${entry.key}_${width.toInt()}.png',
          ),
        );
      });
    }
  }
}
