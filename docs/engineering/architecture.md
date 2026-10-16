---
title: Architecture
owner: เมธ
last_updated: 2026-10-16
version: 1.0
status: active
---

# สถาปัตยกรรม

```
packages/recipix_core   Dart ล้วน (ไม่มี dependency runtime)
  common/      LocalDate, Money, Quantity
  entities/    IngredientItem, Recipe, UserBudgetProfile, PriceSettings
  survival/    SurvivalEngine -> SurvivalReport
  slot/        SlotRollStrategy (ExpiringFirst, PureRandom), RecipeMatcher, IngredientSlotMachine -> SlotSpinResult
  inventory/   InventoryService.cook -> CookResult (ตัดตามปริมาณ FEFO)
  achievements/ RecipixEvent (sealed), BadgeRule, AchievementManager (Stream<BadgeUnlocked>)
lib/
  app/         router (go_router + ShellRoute), theme (ThemeExtension<RecipixTokens>), shell
  features/<tab>/data|domain|presentation
  shared/      widgets, icons, motion, utils
```

## กติกา
- ทิศทาง dependency: presentation → domain (ของ feature) → recipix_core; core ไม่รู้จักอะไรข้างบน
- ทุกฟังก์ชันใน core ที่ขึ้นกับเวลา รับ `LocalDate today` เป็นพารามิเตอร์ (ไม่มี `DateTime.now()` ใน core)
- ผลสุ่มสล็อตตัดสินใน core ก่อน UI เล่นแอนิเมชัน
- แผนที่ Unity → Flutter: ดู MASTER_PROMPT หมวด 3.2 และ skill `recipix-architecture`

## แพ็กเกจแอป (Phase 1 — ต้องตรวจเวอร์ชันจาก pub.dev ตอนเพิ่ม และออก ADR)
Riverpod, go_router, flutter_svg; ภายหลัง: drift, flutter_local_notifications, camera/mobile_scanner/ML Kit
