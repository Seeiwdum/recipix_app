import 'dart:async';

import '../common/local_date.dart';
import 'badge_rules.dart';
import 'recipix_event.dart';

final class BadgeProgress {
  const BadgeProgress({
    required this.badgeId,
    required this.current,
    required this.target,
    this.unlockedOn,
  });

  final String badgeId;
  final int current;
  final int target;
  final LocalDate? unlockedOn;

  bool get isUnlocked => unlockedOn != null;

  /// 0.0 to 1.0 for progress bars.
  double get fraction =>
      isUnlocked ? 1 : (target <= 0 ? 0 : (current / target).clamp(0, 1));
}

final class BadgeUnlocked {
  const BadgeUnlocked(this.badgeId, this.date);

  final String badgeId;
  final LocalDate date;
}

/// Port of the Unity `AchievementManager`.
///
/// Feeds events through [BadgeRule]s and broadcasts unlocks on
/// [onBadgeUnlocked] (the C# `OnBadgeUnlocked` event), so the UI listens
/// without the rules knowing about any widget. Unlocks are permanent.
final class AchievementManager {
  AchievementManager({
    List<BadgeRule>? rules,
    Iterable<BadgeProgress> saved = const [],
  }) : _rules = rules ?? defaultBadgeRules {
    final byId = {for (final p in saved) p.badgeId: p};
    for (final rule in _rules) {
      final s = byId[rule.badgeId];
      _progress[rule.badgeId] = BadgeProgress(
        badgeId: rule.badgeId,
        current: s?.current ?? 0,
        target: rule.target,
        unlockedOn: s?.unlockedOn,
      );
    }
  }

  final List<BadgeRule> _rules;
  final Map<String, BadgeProgress> _progress = {};
  final StreamController<BadgeUnlocked> _unlocks = StreamController.broadcast();

  Stream<BadgeUnlocked> get onBadgeUnlocked => _unlocks.stream;

  /// In rule order.
  List<BadgeProgress> get progress => [
    for (final r in _rules) _progress[r.badgeId]!,
  ];

  BadgeProgress progressOf(String badgeId) => _progress[badgeId]!;

  /// Applies [event] and returns badges unlocked by it.
  List<BadgeUnlocked> handle(RecipixEvent event) {
    final unlocked = <BadgeUnlocked>[];
    for (final rule in _rules) {
      final before = _progress[rule.badgeId]!;
      if (before.isUnlocked) continue;

      final value = rule.next(before.current, event).clamp(0, rule.target);
      final reached = value >= rule.target;
      _progress[rule.badgeId] = BadgeProgress(
        badgeId: rule.badgeId,
        current: value,
        target: rule.target,
        unlockedOn: reached ? event.date : null,
      );
      if (reached) unlocked.add(BadgeUnlocked(rule.badgeId, event.date));
    }
    unlocked.forEach(_unlocks.add);
    return unlocked;
  }

  Future<void> dispose() => _unlocks.close();
}
