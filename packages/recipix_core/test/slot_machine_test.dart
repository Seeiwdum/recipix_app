import 'dart:math';

import 'package:recipix_core/recipix_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Always picks pool items in order, so tests are deterministic.
final class _InOrderStrategy implements SlotRollStrategy {
  const _InOrderStrategy();

  @override
  List<IngredientItem> pick(
    List<IngredientItem> pool,
    int count,
    Random random,
    LocalDate today,
  ) => pool.take(count).toList();
}

void main() {
  group('RecipeMatcher', () {
    const matcher = RecipeMatcher();

    test('match percentage and missing keys', () {
      final m = matcher.match(recipe('omelette', ['egg', 'pork', 'onion']), {
        'egg',
        'pork',
        'rice',
      });
      expect(m.haveKeys, {'egg', 'pork'});
      expect(m.missingKeys, {'onion'});
      expect(m.matchPercentage, 66);
      expect(m.isJackpot, isFalse);
    });

    test('jackpot only at 100%', () {
      final m = matcher.match(recipe('r', ['egg', 'rice']), {'egg', 'rice'});
      expect(m.matchPercentage, 100);
      expect(m.isJackpot, isTrue);
    });

    test('optional ingredients never count as missing', () {
      final m = matcher.match(recipe('r', ['egg'], optional: ['chili']), {
        'egg',
      });
      expect(m.isJackpot, isTrue);
    });

    test('rank drops recipes that use no focus key', () {
      final ranked = matcher.rank(
        [
          recipe('a', ['egg']),
          recipe('b', ['pork']),
        ],
        {'egg', 'pork'},
        focusKeys: {'egg'},
      );
      expect(ranked.map((m) => m.recipe.id), ['a']);
    });

    test('rank orders by ratio then focus hits', () {
      final ranked = matcher.rank(
        [
          recipe('half', ['egg', 'beef']),
          recipe('full-1', ['egg']),
          recipe('full-2', ['egg', 'pork']),
        ],
        {'egg', 'pork'},
        focusKeys: {'egg', 'pork'},
      );
      expect(ranked.map((m) => m.recipe.id), ['full-2', 'full-1', 'half']);
    });
  });

  group('ExpiringFirstRollStrategy', () {
    test('weights fall off with days left', () {
      expect(ExpiringFirstRollStrategy.weightFor(0), 1);
      expect(ExpiringFirstRollStrategy.weightFor(1), 0.25);
      expect(
        ExpiringFirstRollStrategy.weightFor(0),
        greaterThan(ExpiringFirstRollStrategy.weightFor(7) * 60),
      );
    });

    test('favours items close to expiry', () {
      final pool = [item('soon', daysLeft: 0), item('later', daysLeft: 7)];
      var soonFirst = 0;
      final random = Random(42);
      for (var i = 0; i < 1000; i++) {
        final pick = const ExpiringFirstRollStrategy().pick(
          pool,
          1,
          random,
          today,
        );
        if (pick.single.id == 'soon') soonFirst++;
      }
      expect(soonFirst, greaterThan(950));
    });

    test('picks distinct items and stops when pool runs out', () {
      final pool = [item('a'), item('b')];
      final pick = const ExpiringFirstRollStrategy().pick(
        pool,
        3,
        Random(1),
        today,
      );
      expect(pick.map((i) => i.id).toSet(), {'a', 'b'});
    });
  });

  group('PureRandomRollStrategy', () {
    test('picks distinct items', () {
      final pool = [for (var i = 0; i < 10; i++) item('i$i')];
      final pick = const PureRandomRollStrategy().pick(
        pool,
        3,
        Random(7),
        today,
      );
      expect(pick.length, 3);
      expect(pick.map((i) => i.id).toSet().length, 3);
    });
  });

  group('IngredientSlotMachine', () {
    final recipes = [
      recipe('kaprao', ['pork', 'basil', 'egg']),
      recipe('omelette', ['egg']),
      recipe('tomyum', ['shrimp', 'lemongrass']),
    ];

    IngredientSlotMachine machine({SlotRollStrategy? strategy, int seed = 1}) =>
        IngredientSlotMachine(
          strategy: strategy ?? const _InOrderStrategy(),
          recipes: recipes,
          random: Random(seed),
        );

    test('pool excludes expired, mystery and duplicate keys', () {
      final pool = IngredientSlotMachine.usablePool([
        item('egg-old', key: 'egg', daysLeft: 4),
        item('egg-new', key: 'egg', daysLeft: 1),
        item('milk', daysLeft: -1),
        item('box', mystery: true),
      ], today);
      expect(pool.map((i) => i.id), ['egg-new']);
    });

    test('result is decided up front with best match', () {
      final result = machine().spin(
        fridge: [item('pork'), item('basil'), item('egg')],
        today: today,
      );
      expect(result.reels.map((i) => i?.key), ['pork', 'basil', 'egg']);
      expect(result.bestMatch!.recipe.id, 'kaprao');
      expect(result.isJackpot, isTrue);
      expect(result.matchPercentage, 100);
      expect(result.alternatives.map((m) => m.recipe.id), ['omelette']);
    });

    test('locked reels keep their item and are not rolled twice', () {
      final egg = item('egg');
      final result = machine().spin(
        fridge: [egg, item('pork'), item('basil')],
        today: today,
        locked: {1: egg},
      );
      expect(result.reels[1], same(egg));
      expect(result.reels.where((i) => i?.key == 'egg').length, 1);
      expect(result.reels.whereType<IngredientItem>().length, 3);
    });

    test('empty reels when fridge is short; no match on empty fridge', () {
      final result = machine().spin(fridge: const [], today: today);
      expect(result.reels, [null, null, null]);
      expect(result.bestMatch, isNull);
      expect(result.matchPercentage, 0);
    });

    test('same seed gives the same spin', () {
      final fridge = [for (var i = 0; i < 8; i++) item('i$i')];
      List<String?> spin() => machine(
        strategy: const PureRandomRollStrategy(),
        seed: 99,
      ).spin(fridge: fridge, today: today).reels.map((i) => i?.id).toList();
      expect(spin(), spin());
    });
  });
}
