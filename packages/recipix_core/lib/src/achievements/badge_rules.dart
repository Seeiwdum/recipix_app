import 'recipix_event.dart';

/// Turns events into badge progress. Display names live in the app layer;
/// core only knows ids.
abstract interface class BadgeRule {
  String get badgeId;

  /// Progress needed to unlock.
  int get target;

  /// Progress after [event], given [current] progress.
  int next(int current, RecipixEvent event);
}

/// Adds whatever [increment] returns for each event.
final class CountingRule implements BadgeRule {
  const CountingRule({
    required this.badgeId,
    required this.target,
    required this.increment,
  });

  @override
  final String badgeId;
  @override
  final int target;
  final int Function(RecipixEvent event) increment;

  @override
  int next(int current, RecipixEvent event) => current + increment(event);
}

/// Counts consecutive successes. [outcome] returns `true` to extend the
/// streak, `false` to reset it, `null` to ignore the event.
final class StreakRule implements BadgeRule {
  const StreakRule({
    required this.badgeId,
    required this.target,
    required this.outcome,
  });

  @override
  final String badgeId;
  @override
  final int target;
  final bool? Function(RecipixEvent event) outcome;

  @override
  int next(int current, RecipixEvent event) => switch (outcome(event)) {
    true => current + 1,
    false => 0,
    null => current,
  };
}

/// Badge ids. Keep stable: they are persisted.
abstract final class BadgeIds {
  static const clearExpiring = 'clear_expiring';
  static const budgetSaver = 'budget_saver';
  static const homeCook = 'home_cook';
  static const zeroWasteWeek = 'zero_waste_week';
  static const firstScan = 'first_scan';
}

/// Starting rule set. Targets are first-pass balance values (L1) and can be
/// tuned without touching the engine.
final List<BadgeRule> defaultBadgeRules = List.unmodifiable(<BadgeRule>[
  CountingRule(
    badgeId: BadgeIds.clearExpiring,
    target: 5,
    increment: (e) => switch (e) {
      ItemUsed(wasUrgent: true) => 1,
      RecipeCooked(:final urgentItemsUsed) => urgentItemsUsed,
      _ => 0,
    },
  ),
  StreakRule(
    badgeId: BadgeIds.budgetSaver,
    target: 7,
    outcome: (e) => e is DayClosed ? e.withinAllowance : null,
  ),
  CountingRule(
    badgeId: BadgeIds.homeCook,
    target: 10,
    increment: (e) => e is RecipeCooked ? 1 : 0,
  ),
  StreakRule(
    badgeId: BadgeIds.zeroWasteWeek,
    target: 7,
    outcome: (e) => switch (e) {
      DayClosed(discardedCount: final n?) => n == 0,
      _ => null,
    },
  ),
  CountingRule(
    badgeId: BadgeIds.firstScan,
    target: 1,
    increment: (e) => e is ItemsScanned && e.count > 0 ? 1 : 0,
  ),
]);

/// How far each counting badge would move if [event] happened, by badge
/// id. Badges it does not touch are left out. Streak badges depend on the
/// days around the event, so they are never previewed.
Map<String, int> badgeGains(
  RecipixEvent event, {
  List<BadgeRule> rules = const [],
}) {
  final gains = <String, int>{};
  for (final rule in rules.isEmpty ? defaultBadgeRules : rules) {
    if (rule is CountingRule) {
      final n = rule.increment(event);
      if (n > 0) gains[rule.badgeId] = n;
    }
  }
  return gains;
}
