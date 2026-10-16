---
title: Handover Notes
owner: แพรว
last_updated: 2026-10-17
version: 1.9
status: active
---

# Handover

## สถานะล่าสุด
PHASE 1.5 เสร็จและ commit บน `dev` แล้ว (`db9078f`); ผู้ก่อตั้งผ่าน CP2 และตัดสินใจตาม ADR-013 (หัวข้อเป็นมื้อ, แท็บ "สมุดค่ากิน", เพิ่มของเข้าตู้เอง) — ทำปุ่มเพิ่มของแล้ว
เทสต์: `flutter analyze` สะอาด, `flutter test` 138 ผ่าน (shot test 48 ตัวข้ามเมื่อไม่ใส่ `SHOTS`), core `dart test` 65 ผ่าน, golden 15 ภาพ

## ทำแล้วรอบล่าสุด (ADR-013)
- `FridgeController.addFromCatalog` / `removeAdded` (เอาออกไม่บันทึกเป็นใช้/ทิ้ง จึงไม่กระทบเหรียญ)
- ปุ่ม "เพิ่มของ" ที่หัวตะกร้า → `add_item_sheet.dart` (18 ชนิดจากแคตตาล็อก, แตะ = 1 ชิ้นลงตะกร้า, "เอาออก" ได้ทันที)
- หน้าหลักตอนตู้ว่างมีลิงก์ "ไปเพิ่มของในตู้เย็น"; ข้อความตะกร้าตอนตู้ว่างชี้ไปที่ปุ่ม
- เทสต์ `test/features/fridge/add_item_test.dart` + golden `add_item_sheet_390`

## ทำแล้วรอบล่าสุด (PHASE 1.5)
- A ตรวจสภาพ: ภาพ before 48 ภาพ (16 สถานะ × 360/390/430) + `design/audit.md`
- B วิจารณ์: 5 ความเห็นอิสระ `design/critique/*.md` + `design/critique/_synthesis.md`
- C reference 16 รายการ `design/references.md`; D ทิศทาง 3 แบบ `design/direction_v2.md` → เลือก A "Kitchen Ledger" สำรอง B "ป้ายตลาด" (ADR-012)
- E ลงมือ: tokens สเกลใหม่ 44/24/18/16/13 (+10); `Amount` / `LedgerRow` / `DotLeader` (`lib/shared/widgets/ledger.dart`); `freshnessColor()`; ทุกแท็บเลิกการ์ดเทมเพลต; เหรียญเป็นตราประทับ; ไอคอนใหม่ `wallet`/`tag`/`bowl`, ลบ `coin` — รายการเต็มใน `design/changelog_ui.md`
- F ตรวจ: ภาพ after 48 ภาพ; 5-second test (390) ก่อน 8/16 → หลัง 11/16 ผ่าน (`qa/five_second_test.md`); เช็กลิสต์ใน `ui_critique.md`
- แก้หลัง 5-second test: หน้าหลักแสดงยอดขาดตามแผนก่อน ยอดขาดถ้าซื้อกินทุกมื้อเบาลงเป็น ink2 (ซ่อนแถวซ้ำเมื่อตู้ว่าง); หน้าลิ้นชักผักตอนปิด 42% → 30% ของแถว; ชื่อเหรียญ `clear_expiring` ย่อเป็น "เคลียร์ของใกล้หมด" ไม่ตัดกลางคำ
- แก้บั๊ก: `menuSuggestionProvider` ไม่เสนอเมนูที่ไม่มีของในตู้เลย

## ค้างอยู่ / ปัญหา
- 5-second test: ทางตันเรื่องเพิ่มของแก้แล้ว (ADR-013) ยังไม่ได้รันเทสต์ซ้ำ
- sheet ผลสุ่มที่ของไม่ครบไม่มีการกระทำถัดไป
- ชิปตัวกรองชิดขอบขวาไม่มีสัญญาณว่าเลื่อนได้
- กรอบตู้ > ช่องแช่แข็ง > กระเบื้อง อ่านเหมือนกล่องซ้อน 3 ชั้น
- วันที่ไม่ได้บันทึกรายจ่ายนับเป็น "อยู่ในงบ" (ADR-010) — รอ "ปิดวันตอนค่ำ"
- ยังไม่ทดสอบบนมือถือจริง (ไม่มี Android SDK ในเครื่อง)

## ขั้นต่อไป (เสนอ)
1. merge `dev` เข้า `main` (CP2 ผ่านแล้ว)
2. รัน 5-second test ซ้ำหลังเพิ่มปุ่มเพิ่มของ
3. แก้จุดที่ 5-second test ยังไม่ผ่าน ที่ไม่ต้องรอ L3 (การกระทำถัดไปใน sheet ผลสุ่มไม่ครบ, สัญญาณเลื่อนชิปตัวกรอง, ลดกล่องซ้อนในตู้)
4. นอก sprint: แผนกินวนเมนูเดิมทุกวัน; เครื่องปรุงถูกนับแคลอรี่; ขาดวัตถุดิบหลักบ้านไทย; ภาพจานอาหาร
5. แท็บสแกน (หลังมี Android + ADR เลือกแพ็กเกจกล้อง/ML Kit)

## กติกาถาวรจากผู้ก่อตั้ง
- เมื่อ token ใกล้หมด: ส่ง build Android/iOS ให้ดาวน์โหลดผ่าน GitHub หรือ QR (เครื่องไม่มี Android SDK → ใช้ GitHub Actions)
- ตั้งแล้ว: `.github/workflows/android-apk.yml` (repo Private `Seeiwdum/recipix_app`) build APK เมื่อ push `main` หรือกด Run workflow → Release `build-N` มี `recipix.apk` + `recipix-qr.png`; ผ่านครั้งแรก run #4 (2026-10-17). ปุ่ม "Re-run jobs" ใช้ commit เดิม ให้กด "Run workflow" แทน. APK เซ็นด้วยคีย์ debug ของ runner (ต่างกันทุกรอบ ต้องลบแอปก่อนลงใหม่) — คีย์จริงเป็น L3

## คำถาม L3
- ยังเปิดอยู่: สิทธิ์อ่าน Figma; ไฟล์ Unity เดิม (+ เดโม HTML / `ui_design_prompt.md`); ติดตั้ง Android Studio; ฟีเจอร์ที่เลื่อนไว้ (รายการซื้อของ, แจ้งเตือน, ปิดวันตอนค่ำ); เปิดครั้งแรกเริ่มจากตู้ว่างไหม
- ตอบแล้ว: ADR-007, ADR-008, ADR-013

## ไฟล์ที่แก้ล่าสุด
`lib/app/{strings.dart,theme/**}`, `lib/features/{home,fridge,random,dashboard,scan,budget}/presentation/**`, `lib/features/home/domain/home_providers.dart`, `lib/shared/widgets/{ledger,ingredient_tile,recipix_page}.dart`, `lib/shared/utils/freshness_color.dart`, `lib/shared/icons/recipix_icon.dart`, `assets/icons/{home,dashboard,wallet,tag,bowl}.svg` (ลบ `coin.svg`), `tool/gen_icons.sh`, `test/**` (รวม `test/design/`, golden), `docs/**`, `handoff.md`
