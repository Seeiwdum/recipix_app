---
title: Handover Notes
owner: แพรว
last_updated: 2026-10-16
version: 1.0
status: active
---

# Handover

## สถานะล่าสุด
จบ Phase 0 (CP1) บน branch `dev`: ระบบทีม/เอกสารครบ, `recipix_core` พอร์ตแล้วพร้อมเทสต์ 47 ข้อผ่าน, แอปยังเป็นหน้า scaffold เดิมของ Flutter

## ทำแล้ว
- ตรวจเครื่อง (ดู `engineering/tooling_setup.md`) — Flutter 3.47.7 / Dart 3.13.5, รันได้บน Chrome
- git: `main` (scaffold) + `dev`
- `packages/recipix_core`: Survival, Slot (2 strategies + matcher), Inventory (ตัดตามปริมาณ), Badges (rules + stream) — แก้บั๊กเดโมทั้ง 6 ข้อในหมวด 4
- ADR-002 นิยาม BudgetDeficit, ADR-003 โมเดลโดเมน
- `CLAUDE.md`, `.claude/agents/*` (9), `.claude/skills/*` (6), `.mcp.json` (Dart MCP)

## ค้างอยู่ / ปัญหา
- ไม่มี `docs/ui_design_prompt.md`, `legacy_unity/` (ต้นฉบับ C#) และ `Recipix_2.2_Demo.html` ในรีโป → ใช้ MASTER_PROMPT แทน; ชื่อเหรียญใช้ชุดตั้งต้นใน skill `recipix-thai-copy`
- path Flutter มีช่องว่าง → `flutter` ใน Git Bash บางคำสั่งพัง ใช้ PowerShell
- ไม่มี Android SDK (ต้องติดตั้ง Android Studio เอง) — ใช้ Chrome ไปก่อน
- `.mcp.json` ยังไม่ได้ยืนยันสถานะ Connected (ต้องอนุมัติในเซสชันถัดไป แล้วเช็ก `/mcp`)
- ยังไม่ได้ติดตั้งปลั๊กอิน `skill-creator` (ทำผ่าน `/plugins`)

## ขั้นต่อไป (Phase 1)
1. ตรวจเวอร์ชันจาก pub.dev แล้วเพิ่ม Riverpod, go_router, flutter_svg → ADR-004 (state/nav)
2. ดาวน์โหลด IBM Plex Sans Thai (OFL) เข้า `assets/fonts/`
3. `RecipixTokens` (ThemeExtension) + ไฟล์ข้อความไทยกลาง
4. ไอคอน SVG ชุดแรก (5 แท็บ + การกระทำหลัก) + กรอบภาพวัตถุดิบ
5. App shell: tab bar 5 แท็บ + ทรานซิชันเปลี่ยนแท็บ + reduce-motion
6. ข้อมูลตัวอย่าง `assets/data/` (วัตถุดิบ/สูตรไทย) — วุฒิ
7. เช็กลิสต์ 5.5 → `ui_critique.md`, ภาพหน้าจอ Chrome 360/390/430

## คำถาม L3 ที่รอคำตอบ
1. ไฟล์ต้นฉบับที่หายไป (ui_design_prompt / Unity / เดโม HTML) — มีไหม จะวางให้ไหม
2. Android: จะติดตั้ง Android Studio เพื่อรันบน emulator/มือถือจริงเมื่อไร

## ไฟล์ที่แก้ล่าสุด
`packages/recipix_core/**`, `pubspec.yaml`, `CLAUDE.md`, `.mcp.json`, `.claude/**`, `docs/**`
