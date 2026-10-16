---
title: Changelog
owner: แพรว
last_updated: 2026-10-16
version: 0.7.0
status: active
---

# Changelog

## 0.7.0 — 2026-10-16 (dashboard)
- feat(dashboard): editable period budget, payday and meal price with steppers (hold to repeat and speed up); deficit line; pay-period timeline; what the money left buys; badge grid (3 columns, concept kept) with rule sheet; most-cooked dishes
- feat(badges): progress rebuilt by replaying saved history (used/discarded, cooked, spending) through the core AchievementManager; undo moves badges back
- feat(core): badge events carry item ids; DayClosed.discardedCount nullable so waste badges skip untracked days
- feat(persistence): activity log, urgent-items-used per dish and tracking start date saved (older saves still load)
- test: core 64, app 112 (incl. dashboard goldens at 360/390/430)
- docs: ADR-010, UI critique

## 0.6.0 — 2026-10-16 (on-device saving)
- feat(persistence): fridge contents, shelf positions, cooked meals and the budget/spending log are saved on the device (shared_preferences 2.5.6; localStorage on web) and restored before the first frame
- feat(persistence): writes coalesced per microtask, flushed when the app is paused/hidden; first-launch sample data saved immediately so its dates stay fixed
- feat(persistence): unreadable or unknown-version data is copied to <key>.corrupt.<timestamp> before starting fresh (never silently overwritten)
- test: codec round-trips, relaunch on a later day, corrupt backup, write coalescing (app 95, core 63)
- docs: ADR-009

## 0.5.0 — 2026-10-16 (spending log + meal plan)
- feat(core): BudgetLedger (pay period, remaining, start-of-day allowance, eat-out meals today) and MealPlanner (greedy plan to payday cooking from the fridge first, shortfall, will-spoil list)
- feat(budget): spending log sheet on home: amount, quick amounts from settings, category, today's entries with remove, undo toast; report shows spent/left today and over-allowance
- feat(plan): meal plan page (/home/plan) with summary and day-by-day meals; next-meal row on home; cook sheet deducts the dish from the fridge with undo
- fix(ui): undo toasts now close after 5s (Flutter 3.47 keeps snack bars with actions by default)
- test: 63 core, 87 app (incl. goldens for plan and spending sheet)
- docs: ADR-008, UI critique

## 0.4.0 — 2026-10-16 (Phase 2: home tab)
- feat(home): daily report: headline days-left number (count-up), mystery estimate line, coverage-to-payday bar, daily allowance, days to payday, plain deficit line
- feat(home): use-first list (expired then 0-2 days) with swipe right = used, left = discard, tap = item sheet, undo toast, staggered entrance
- feat(home): one suggested dish using something urgent, match % or "ครบทุกอย่าง", minutes and kcal
- feat(data): 10 everyday Thai recipes in assets/data/recipes.json; shared RecipeBook; budgetProvider
- feat(core): LocalDate.weekday
- chore: preview port 8765 (8080 became OS-reserved)
- docs: ADR-006, design references from the team Figma, UI critique

## 0.3.0 — 2026-10-16 (Phase 2: fridge tab)
- feat(fridge): cross-section fridge mini-game: freezer, 3 shelves, crisper drawer, door bins; 1x1/2x1 items; drag from basket with spring snap, refused drops spring back, drawer auto-opens on hover
- feat(fridge): freshness via day label, edge colour and fade; filters that dim non-matching items; capacity bar; item sheet with used/discard/move/auto-place; undo toast (5s)
- feat(data): ingredient catalog (18 items) in assets/data, loaded at startup; 9 more ingredient illustrations
- fix(app): SVG ingredient art precached at startup (first-visit transition stall)
- test: fridge grid + controller unit tests, drag/drop widget tests, asset-bundle check, goldens for board/sheet/mid-drag
- docs: ADR-005, ingredient data spec, UI critique for the fridge

## 0.2.0 — 2026-10-16 (Phase 1: design system + shell)
- feat(app): RecipixTokens + theme, IBM Plex Sans Thai, Thai strings file
- feat(app): 19 hand-drawn SVG icons, 9 ingredient illustrations, IngredientTile (initials / dashed mystery / faded)
- feat(app): 5-tab shell with go_router StatefulShellRoute, custom tab bar, signature tab transition, reduce-motion fallback, press feedback
- test(app): shell widget tests, token contrast tests, governance tests (emoji, colors, radii, gradients, icon spec), goldens at 360/390/430
- fix(shell): quick second tab tap no longer cuts the outgoing fade short
- docs: ADR-004, UI critique for Phase 1, web preview notes

## 0.1.0 — 2026-10-16 (Phase 0 / CP1)
- chore: git repo (`main` + `dev`), Flutter 3.47.7 scaffold `recipix_app`, folder layout per MASTER_PROMPT 11
- feat(core): `packages/recipix_core` — `LocalDate`, `Money`, `Quantity`, `IngredientItem`, `Recipe`, `UserBudgetProfile`/`PriceSettings`, `SurvivalEngine`, `RecipeMatcher`, `SlotRollStrategy` (ExpiringFirst, PureRandom), `IngredientSlotMachine`, `InventoryService`, `AchievementManager` + rules
- fix(demo bugs): no blended survival score; mystery kcal as estimate; deduct by quantity; real expiry dates; event-driven badge rules; editable prices
- test(core): 47 unit tests
- docs: CLAUDE.md, COMPANY_RULES, ADR-001..003, engineering/product/qa docs, 9 subagents, 6 project skills
- chore: `.mcp.json` with the official Dart MCP server (`dart mcp-server`)
