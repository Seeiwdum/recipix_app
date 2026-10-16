---
title: Changelog
owner: แพรว
last_updated: 2026-10-17
version: 0.9.0
status: active
---

# Changelog

## 0.13.0 — 2026-10-17 (photo mode, ADR-016)
- feat(scan): scan tab has two modes (barcode | photo). Photo mode: camera preview with a round shutter (`camera` 0.12.1), ML Kit object detection on the still photo (`google_mlkit_object_detection` 0.17.1, on device), a box around each thing found; tap a box to pick what it is and it goes into the basket.
- feat(scan): nothing found / device cannot look (web) explain themselves; retake; add by hand always there; only the chosen mode's camera runs, only while the tab is on screen.
- refactor: `ModePicker` shared by the random and scan tabs.
- test: photo_mode_test.dart and golden photo_boxes_390.

## 0.12.0 — 2026-10-17 (menu suggestions and recipe page, ADR-015)
- feat(home): "เมนูแนะนำ" under the report — up to 3 dishes: fridge dishes using urgent items first, then any fridge dish, then easy dishes; each says where it comes from.
- feat(home): recipe page `/home/recipe/:id` — ingredients with have/missing/optional, numbered steps, difficulty, badges this cook would move, and one "cook this" button when everything is on hand (with undo).
- feat(core): `Recipe.difficulty` / `Recipe.steps`; `badgeGains(event)` previews counting badges with the real rules.
- data: steps and difficulty for all 10 recipes (first draft, to be checked by Nutrition & Data).
- test: recipe_page_test.dart, core badge_gains_test.dart, golden recipe_390.

## 0.11.0 — 2026-10-17 (barcode scan, ADR-014)
- feat(scan): camera tab reads retail barcodes (mobile_scanner 7.4.2), looks the product up on Open Food Facts v3 (barcode number only), and lets the user pick the ingredient; the choice is remembered on the device (`recipix.barcodes.v1`), so repeat scans need no network.
- feat(scan): camera runs only while the tab is visible and nothing is being handled; denied permission / no camera explain themselves; "add by hand" is always one tap away.
- feat(dashboard): the first barcode scan feeds the first-scan badge.
- refactor(fridge): `CatalogGrid` shared by the add sheet and the scan result.
- chore: INTERNET permission (release builds), iOS camera usage text; removed unused windows/ and linux/ targets (plugin symlinks need Developer Mode on Windows).
- test: scan_test.dart (parsing, controller, page) and goldens scan_390 / scan_result_390.

## 0.10.0 — 2026-10-17 (add items by hand, ADR-013)
- feat(fridge): "add" button on the basket opens a catalog sheet; each tap puts one fresh item in the basket, with take-back.
- feat(home): empty-fridge state links to the fridge tab.
- docs: ADR-013 records the founder approving the meals headline and the "สมุดค่ากิน" tab name.
- test: add_item_test.dart and the add_item_sheet_390 golden.

## 0.9.0 — 2026-10-17 (PHASE 1.5 UI refinement, direction A "Kitchen Ledger")
- feat(ui): new type scale 44/24/18/16/13 (+10 micro), `pageTitle` on every tab, tabular `number`, `unitScale`/`leaderDot`/`leaderGap` tokens (ADR-012)
- feat(ui): shared `Amount`, `LedgerRow` and `DotLeader` (lib/shared/widgets/ledger.dart) replace template cards; one big number per screen
- feat(ui): `freshnessColor()` single source for freshness colour (red = expired/today, amber = 1-5 days); overspent days amber instead of red
- feat(fridge): held item lifts (scale 1.05, hard offset shadow), zones drawn with material lines, basket says why a drop is refused, honest empty state; crisper drawer front closed height 42% -> 30% of the row
- feat(home): report as ledger lines; plan shortfall shown first, eat-out shortfall quieter in ink2 and hidden when it duplicates (empty fridge); headline in meals (pending founder, L3)
- feat(random): reels in one window, 350ms pause before results, sheet max 58% height, full matches grouped first, empty fridge links to eat-out; eat-out as an order slip
- feat(dashboard): tab renamed "สมุดค่ากิน" (pending founder, L3); big number is money left; badges as stamps with progress or date; badge 'clear_expiring' renamed "เคลียร์ของใกล้หมด" (no mid-word break)
- feat(icons): home = spoon and fork, dashboard = ledger book, new wallet/tag/bowl; coin removed
- fix(home): menu suggestions never offer a dish with none of its ingredients in the fridge
- test: app 128 pass (48 design shot tests skipped without SHOTS define), core 65 pass, 14 goldens regenerated; before/after shots in docs/design/shots/
- docs: ADR-012, ui_refinement_sprint, design/{audit,references,direction_v2,changelog_ui}, design/critique/*, qa/five_second_test (before 8/16 -> after 11/16), UI critique, handover

## 0.8.0 — 2026-10-16 (random menu tab)
- feat(random): 3-reel ingredient slot (result decided first, reels stop one by one with a 6% settle, labels hidden until each reel stops), tap to lock, expiring-first toggle, result sheet with match/have/missing/other dishes, cook a full match with undo
- feat(random): eat-out mode — one dish reel priced within what is left today, sheet logs it as spending
- feat(core): slot ranking weighs how many reels a dish uses (RecipeMatcher.rank weighFocus)
- feat(data): assets/data/eat_out.json (12 dishes)
- chore: .vscode/launch.json (Chrome / Android / core tests)
- test: core 65, app 128 (+ random goldens)
- docs: ADR-011, UI critique

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
