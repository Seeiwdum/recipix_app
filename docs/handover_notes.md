---
title: Handover Notes
owner: แพรว
last_updated: 2026-10-16
version: 1.2
status: active
---

# Handover

## สถานะล่าสุด
แท็บตู้เย็น (minigame จัดตู้เย็น) เสร็จบน branch `dev` และรันจริงบน Chrome แล้ว อีก 4 แท็บยังเป็น placeholder
เทสต์: แอป 61 ผ่าน (รวม golden 11 ภาพ), core 47 ผ่าน, analyze สะอาด

## ทำแล้ว (Phase 2 — ตู้เย็น)
- ผังตู้ 25 ช่อง: ช่องแช่แข็ง / ชั้นบน-กลาง-ล่าง / ลิ้นชักผัก (มีหน้าลิ้นชักเลื่อนเปิด, เปิดเองเมื่อลากผ่าน) / ชั้นประตู 4 ช่อง
- ลาก-วางเขียนเอง (ADR-005): จับของจากตะกร้าหรือชั้น → กรอบเขียวบอกช่องที่วางได้ / แดงถ้าวางไม่ได้ → spring snap หรือเด้งกลับ; ลากลงตะกร้าได้
- ความสด 3 ทาง: ป้ายวัน, กรอบสี, ภาพซีด; ตัวกรอง 5 แบบหรี่ของที่ไม่ตรง; แถบความจุ
- Sheet รายละเอียด: วันหมดอายุไทย, พลังงาน (ของปริศนาแสดง "ประมาณ"), ที่เก็บ; ใช้แล้ว / ทิ้ง / ย้ายไปตะกร้า / จัดเข้าตู้ให้; toast "เลิกทำ" 5 วินาที คืนตำแหน่งเพื่อนบ้านได้ด้วย
- `assets/data/ingredients.json` 18 รายการ + ภาพวัตถุดิบครบ 18 ชิ้น; precache SVG ตอนเปิดแอป
- `todayProvider`, `catalogProvider` (inject ใน `main()` และใน test)

## ค้างอยู่ / ปัญหา
- ค่าแคลอรี่/อายุใน catalog เป็นประมาณการ → วุฒิต้องตรวจแหล่งอ้างอิง (`product/ingredient_data_spec.md`)
- ข้อมูลยังอยู่ในหน่วยความจำ ปิดแอปแล้วหาย (persistence = Phase 3)
- ยังไม่ได้ทดสอบบนมือถือจริง: แฮปติก, ลากด้วยนิ้ว, 60 FPS; ด้ามลิ้นชักตอนเปิดสูงแค่ 18px
- ไฟล์ต้นฉบับ (ui_design_prompt / Unity / เดโม HTML) ยังไม่มี
- `.mcp.json` (Dart MCP) ยังไม่ได้ยืนยัน Connected

## ขั้นต่อไป
1. แท็บหน้าหลัก "ใบรายงานประจำวัน": `SurvivalEngine` จากของในตู้ (provider ร่วมกับ fridgeProvider), ตัวเลขหลัก "อยู่ได้อีก x วัน" นับขึ้น 400ms, รายการต้องใช้ก่อนปัดเพื่อ ใช้แล้ว/ทิ้ง, ข้อเสนอเมนู 1 แถว (ต้องมีข้อมูลสูตร `assets/data/recipes.json`)
2. ต่อด้วย สแกน → สุ่มเมนู → แดชบอร์ด
3. ย้าย fridge state ไปเป็น "คลังกลาง" ที่ทุกแท็บใช้ร่วม (ตอนนี้อยู่ใน feature fridge)

## คำถาม L3 ที่รอคำตอบ
1. ไฟล์ต้นฉบับที่หายไป (ui_design_prompt / Unity / เดโม HTML)
2. Android Studio: ติดตั้งเมื่อไรเพื่อทดสอบบนมือถือจริง

## ไฟล์ที่แก้ล่าสุด
`lib/features/fridge/**`, `lib/app/{providers,strings}.dart`, `lib/app/theme/recipix_tokens.dart`, `lib/main.dart`, `lib/shared/widgets/ingredient_tile.dart`, `assets/data/ingredients.json`, `assets/ingredients/*`, `tool/gen_ingredients.sh`, `test/**`, `pubspec.yaml`, `.claude/launch.json`, `docs/**`
