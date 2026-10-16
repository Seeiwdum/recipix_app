---
title: Handover Notes
owner: แพรว
last_updated: 2026-10-16
version: 1.1
status: active
---

# Handover

## สถานะล่าสุด
จบ Phase 1 บน branch `dev`: ระบบดีไซน์ + app shell 5 แท็บรันได้จริงบน Chrome; แต่ละแท็บยังเป็นหน้า "กำลังทำ" (ตู้เย็นแสดงชุดภาพวัตถุดิบไว้ให้ตรวจ)
เทสต์: แอป 34 ผ่าน (รวม golden 6 ภาพ, governance, contrast), core 47 ผ่าน, analyze สะอาด

## ทำแล้ว (Phase 1)
- แพ็กเกจ: flutter_riverpod 3.4.3, go_router 18.1.0, flutter_svg 2.3.0 → ADR-004
- ฟอนต์ IBM Plex Sans Thai 400/500/600 + OFL ใน `assets/fonts/`
- `RecipixTokens` (สี/รัศมี/ระยะ/ตัวอักษร/motion) + `buildRecipixTheme()` ปิด ripple; เพิ่ม `warnText` เพราะ warn เดิมคอนทราสต์ไม่พอสำหรับข้อความ
- `lib/app/strings.dart` ข้อความไทยรวมที่เดียว (รวมชื่อเหรียญ)
- ไอคอน SVG 19 ตัว (`tool/gen_icons.sh`) + `RecipixIcon`; ภาพวัตถุดิบ 9 ชิ้น (`tool/gen_ingredients.sh`) + `IngredientTile` (ตัวอักษรย่อเมื่อไม่มีภาพ, กรอบประสำหรับของปริศนา, ซีดเมื่อใกล้หมดอายุ)
- Shell: `StatefulShellRoute` + `TabSwitcher` (จางออก 120ms / จางเข้า+เลื่อนขึ้น 8px 220ms, reduce-motion = fade 120ms) + `RecipixTabBar` แถบบ่งชี้เลื่อนตาม + `Pressable` (scale .97)
- `test/governance_test.dart` บังคับกฎ: ไม่มี emoji, สีเฉพาะใน theme, ไม่มีรัศมีตัวเลขตรงๆ, ไม่มี gradient/blur/repeat, ไอคอนตามสเปก, core ไม่ import Flutter
- `.claude/launch.json` สำหรับ preview บนเว็บ (release mode)

## ค้างอยู่ / ปัญหา
- ไฟล์ต้นฉบับยังไม่มี: `docs/ui_design_prompt.md`, `legacy_unity/`, เดโม HTML — ใช้ MASTER_PROMPT เป็นสเปก (ผู้ก่อตั้งอนุมัติ)
- บน web ครั้งแรกที่เปิดแท็บตู้เย็น ทรานซิชันสะดุดระหว่าง decode SVG → precache ตอนเปิดแอป (Phase 2)
- ไม่มี Android SDK → ยังทดสอบบนมือถือจริงไม่ได้ (haptics/safe area จริง)
- `.mcp.json` (Dart MCP) ยังไม่ได้ยืนยัน Connected

## ขั้นต่อไป (Phase 2 — แท็บตู้เย็นก่อน)
1. ข้อมูลตัวอย่าง `assets/data/ingredients.json`, `recipes.json` (วุฒิ) + loader ใน `features/*/data`
2. Riverpod providers: `todayProvider` (ฉีดวันที่), fridge state (Notifier) ห่อ `recipix_core`
3. Precache SVG ตอนเปิดแอป
4. แท็บตู้เย็น: หน้าตัด 3 ชั้น + ลิ้นชักผัก + ช่องแช่แข็ง + ชั้นประตู, กริด 1x1/2x1, ลากจากตะกร้า snap spring, ดีดกลับเมื่อเต็ม, bottom sheet รายละเอียด, ตัวกรองไฮไลต์, แถบความจุ → ADR การวางกริด (app layer)
5. widget + golden test ตู้เย็น, เช็กลิสต์ 5.5 → `ui_critique.md`
6. ต่อด้วย หน้าหลัก → สแกน → สุ่มเมนู → แดชบอร์ด

## คำถาม L3 ที่รอคำตอบ
1. ไฟล์ต้นฉบับที่หายไป (ui_design_prompt / Unity / เดโม HTML): ถ้ามีให้วางไว้ตามหมวด 0 ของ MASTER_PROMPT จะได้เทียบชื่อเหรียญและสูตรเดิม
2. Android Studio: ติดตั้งเมื่อไรเพื่อทดสอบบนมือถือ/emulator

## ไฟล์ที่แก้ล่าสุด
`lib/**`, `test/**`, `assets/**`, `tool/gen_*.sh`, `pubspec.yaml`, `.claude/launch.json`, `.claude/skills/recipix-design-system/SKILL.md`, `docs/**`
