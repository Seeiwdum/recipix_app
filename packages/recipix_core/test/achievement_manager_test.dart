import 'package:recipix_core/recipix_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  DayClosed day(int offset, {bool within = true, int discarded = 0}) =>
      DayClosed(
        today.addDays(offset),
        spent: Money.baht(within ? 80 : 150),
        allowance: Money.baht(100),
        discardedCount: discarded,
      );

  test('clear-expiring counts urgent uses only', () {
    final m = AchievementManager();
    m.handle(ItemUsed(today, itemId: 'a', daysLeft: 5));
    m.handle(ItemUsed(today, itemId: 'b', daysLeft: 2));
    m.handle(
      RecipeCooked(today, recipe: recipe('r', ['x']), urgentItemsUsed: 3),
    );
    expect(m.progressOf(BadgeIds.clearExpiring).current, 4);
    final unlocked = m.handle(ItemUsed(today, itemId: 'c', daysLeft: 0));
    expect(unlocked.map((u) => u.badgeId), contains(BadgeIds.clearExpiring));
    expect(m.progressOf(BadgeIds.clearExpiring).isUnlocked, isTrue);
  });

  test('budget streak resets on an over-budget day', () {
    final m = AchievementManager();
    for (var i = 0; i < 6; i++) {
      m.handle(day(i));
    }
    m.handle(day(6, within: false));
    expect(m.progressOf(BadgeIds.budgetSaver).current, 0);
    for (var i = 7; i < 14; i++) {
      m.handle(day(i));
    }
    expect(m.progressOf(BadgeIds.budgetSaver).isUnlocked, isTrue);
  });

  test('days without waste tracking do not count toward zero-waste', () {
    final m = AchievementManager();
    for (var i = 0; i < 10; i++) {
      m.handle(
        DayClosed(
          today.addDays(i),
          spent: Money.zero,
          allowance: Money.baht(100),
          discardedCount: null,
        ),
      );
    }
    expect(m.progressOf(BadgeIds.zeroWasteWeek).current, 0);
    expect(m.progressOf(BadgeIds.budgetSaver).isUnlocked, isTrue);
  });

  test('broadcasts unlocks on the stream, once', () async {
    final m = AchievementManager();
    final events = <String>[];
    final sub = m.onBadgeUnlocked.listen((u) => events.add(u.badgeId));
    m.handle(ItemsScanned(today, count: 3));
    m.handle(ItemsScanned(today, count: 3));
    await Future<void>.delayed(Duration.zero);
    expect(events, [BadgeIds.firstScan]);
    await sub.cancel();
    await m.dispose();
  });

  test('unlocked badges stay unlocked', () {
    final m = AchievementManager();
    m.handle(ItemsScanned(today, count: 1));
    m.handle(day(1, discarded: 2));
    expect(m.progressOf(BadgeIds.firstScan).isUnlocked, isTrue);
    expect(m.progressOf(BadgeIds.firstScan).fraction, 1);
  });

  test('restores saved progress', () {
    final m = AchievementManager(
      saved: const [
        BadgeProgress(badgeId: BadgeIds.homeCook, current: 9, target: 10),
      ],
    );
    final unlocked = m.handle(
      RecipeCooked(today, recipe: recipe('r', ['x']), urgentItemsUsed: 0),
    );
    expect(unlocked.single.badgeId, BadgeIds.homeCook);
  });

  test('custom rules plug in', () {
    final m = AchievementManager(
      rules: [
        CountingRule(
          badgeId: 'discard_none',
          target: 2,
          increment: (e) => e is ItemDiscarded ? 1 : 0,
        ),
      ],
    );
    m.handle(ItemDiscarded(today, itemId: 'a'));
    expect(m.progress.single.fraction, 0.5);
  });
}
