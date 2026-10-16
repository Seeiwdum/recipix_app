---
name: recipix-design-system
description: Use whenever creating or changing any Recipix UI — widgets, screens, icons, ingredient art, colors, motion. Holds the "paper kitchen" tokens, the anti-slop rules, icon spec and the pre-ship UI checklist.
---

# Recipix design system

Founder feedback: earlier UI looked like "AI slop" and "an ad", and used emoji. Goal: distinctive, clean, minimal rounded, still clearly about food. A screenshot must read as a **tool**, not an ad.
If `docs/ui_design_prompt.md` exists, it is the primary spec and wins over this file.

## Tokens (all UI values come from `RecipixTokens`; never inline)
Colors: bg `#F7F3EC` · surface `#FFFDF9` · surface-sunken `#EFE9DF` · line `#E3DBCE` · ink `#1F1B16` · ink-2 `#6B6358` · accent `#2F6B4F` (the only accent) · warn `#C98A1B` (borders/dots/bars only) · warnText `#8A5A0B` (text in the warn hue; warn itself is under 3:1) · urgent `#C4452F`. Freshness: fresh=accent, soon=warn, urgent=urgent.
Radii: 10 / 16 / 24 only. Spacing: 8px grid (4 allowed for hairline gaps). Tap targets >= 44-48px. Lines 1px.
Type: one family, IBM Plex Sans Thai (fallback Noto Sans Thai), bundled. Tabular figures for numbers. Thai line height >= 1.5.
Motion: durations 120 / 220 / 360 ms; enter curve `Cubic(.2,.8,.2,1)`; exit `Cubic(.4,0,1,1)`; spring overshoot <= 6%. Transform + opacity only. Reduce-motion -> 120ms fade only.

## Hard rules
1. No emoji anywhere — icons, food art, copy, badge names. Custom SVG only.
2. No glow/aurora/particles/stacked grids; no `BackdropFilter` decoration.
3. No gradient as primary fill of buttons/cards/text; no glow; no soft blurry shadows (use 1px lines).
4. No infinite animations (pulse/shimmer/float) except real loaders.
5. No uppercase English labels or marketing words (Jackpot, Pulse, Aurora, Chef's Pick); no stray "!".
6. No card in card; max one primary button per screen; no confetti/floating pop-ups.
7. If unsure whether to add it — don't.

## Icons & ingredient art
Icons: 24 grid, 1.75 stroke, round caps/joins, `currentColor`, no fills unless a state needs it. Files in `assets/icons/<name>.svg`.
Ingredients: flat shapes, 3-4 colors, inside the same rounded frame (radius 10). Missing art -> initials in the frame. Never fall back to emoji.

## Signature motion
Tab change: fast fade out, 8px rise + fade in, indicator slides. Sheets rise 360ms. Shared element row -> detail. Fridge: spring snap on drop, drawer slides, used items collapse and neighbours close the gap. Rows stagger 30ms, max 6. Numbers count up 400ms once. Slot reels stop one by one.
Feedback instead of pop-ups: press scale .97, bottom toast with "เลิกทำ" for 5s, 4px shake on error, light haptics on drop/reel stop.

## Pre-ship checklist (log in `docs/ui_critique.md`)
- grep finds zero emoji (strings and badge names included)
- no forbidden gradient/blur/glow/infinite animation; one accent; radii 10/16/24 only
- squint test & grayscale: hierarchy still reads
- contrast >= 4.5:1; tap >= 44px; Thai not clipped at 360/390/430 widths
- stranger test: "tool", not "ad"

Emoji grep (repo root, Git Bash):
`LC_ALL=C.UTF-8 grep -rnIP --exclude-dir=.dart_tool "[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}\x{1F000}-\x{1F2FF}]" lib assets packages`

## Where things live
Tokens `lib/app/theme/recipix_tokens.dart` (`context.tokens`) · theme `recipix_theme.dart` · strings `lib/app/strings.dart` · icons `RecipixIcon(RecipixIcons.x)` (sources in `tool/gen_icons.sh`) · ingredient art `IngredientTile` (sources in `tool/gen_ingredients.sh`) · press feedback `Pressable` · dashed frame `DashedRRectPainter` · reduce motion `reduceMotionOf(context)`.
`test/governance_test.dart` enforces the emoji, color, radius and gradient rules automatically.
