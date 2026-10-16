---
title: Changelog
owner: แพรว
last_updated: 2026-10-16
version: 0.2.0
status: active
---

# Changelog

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
