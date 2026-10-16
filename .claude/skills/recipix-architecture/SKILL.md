---
name: recipix-architecture
description: Use when deciding where code goes in Recipix or changing business rules — layer boundaries (recipix_core / features / app), survival, slot machine, inventory and badge rules, and the Unity-to-Flutter mapping.
---

# Recipix architecture

## Layers
- `packages/recipix_core` — pure Dart, no Flutter, no runtime deps. All business rules. Tests with `dart test`.
- `lib/features/<tab>/domain` — app-side use cases/state (notifiers) calling core.
- `lib/features/<tab>/presentation` — widgets only; no business logic.
- `lib/app` — router (go_router + ShellRoute for 5 tabs), theme (`ThemeExtension<RecipixTokens>`), shell.
- `lib/shared` — widgets, icons, motion, utils.
Time and randomness are injected (`LocalDate today`, `Random`) — never read inside core.

## Business rules (see ADR-002, ADR-003)
- Survival: kcal of unexpired, identified items / 2000 = days; mystery items (`key == null`) -> separate estimate. Urgent = 0-2 days left. Allowance = budget / days until payday (floor to satang). Payday unset -> 1st of next month. Deficit = max(0, uncoveredDays x meal price x meals/day - budget).
- Slot: pool = identified, unexpired, one per key (soonest). Strategy picks reels (`ExpiringFirstRollStrategy` weight 1/(d+1)^2, `PureRandomRollStrategy`). Locked reels kept. Match via sets against the whole usable pool; recipes must use >= 1 reel key. Result decided before animation.
- Match % = have/required, floored; jackpot = nothing missing; optional ingredients never missing.
- Cooking: `InventoryService.cook` deducts by quantity, FEFO, compatible units only, returns shortfall.
- Badges: `RecipixEvent` -> `BadgeRule` (Counting/Streak) -> `AchievementManager`; unlock permanent; `Stream<BadgeUnlocked>`. Thai names live in the app.

## Unity -> Flutter
Core models/features -> `recipix_core`; `ISlotRollStrategy` -> `SlotRollStrategy`; `OnBadgeUnlocked` -> `onBadgeUnlocked` stream; MVP Controller/Presenter/View -> Notifier + ConsumerWidget; object pooling/ScrollRect -> `ListView.builder`/slivers; SafeAreaHandler -> `SafeArea`; NavigationController -> go_router; RecipixTheme ScriptableObject -> `ThemeExtension`; coroutines -> async/AnimationController.
