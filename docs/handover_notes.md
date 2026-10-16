---
title: Handover Notes
owner: แพรว
last_updated: 2026-10-17
version: 1.8
status: active
---

# Handover

## สถานะล่าสุด
PHASE 1.5 (UI Refinement Sprint, ทิศ A "Kitchen Ledger", ADR-012) ทำขั้น A–E ครบ; ขั้น F เสร็จทั้งหมด **เหลือผู้ก่อตั้งรีวิว CP2**
เทสต์: `flutter analyze` สะอาด, `flutter test` 128 ผ่าน (shot test 48 ตัวข้ามเมื่อไม่ใส่ `SHOTS`), core `dart test` 65 ผ่าน, golden 14 ภาพ regenerate แล้ว
งาน sprint อยู่ใน working copy บน `dev` (ยังไม่ commit ตอนเขียนบันทึกนี้)

## ทำแล้วรอบล่าสุด (PHASE 1.5)
- A ตรวจสภาพ: ภาพ before 48 ภาพ (16 สถานะ × 360/390/430) + `design/audit.md`
- B วิจารณ์: 5 ความเห็นอิสระ `design/critique/*.md` + `design/critique/_synthesis.md`
- C reference 16 รายการ `design/references.md`; D ทิศทาง 3 แบบ `design/direction_v2.md` → เลือก A "Kitchen Ledger" สำรอง B "ป้ายตลาด" (ADR-012)
- E ลงมือ: tokens สเกลใหม่ 44/24/18/16/13 (+10); `Amount` / `LedgerRow` / `DotLeader` (`lib/shared/widgets/ledger.dart`); `freshnessColor()`; ทุกแท็บเลิกการ์ดเทมเพลต; เหรียญเป็นตราประทับ; ไอคอนใหม่ `wallet`/`tag`/`bowl`, ลบ `coin` — รายการเต็มใน `design/changelog_ui.md`
- F ตรวจ: ภาพ after 48 ภาพ; 5-second test (390) ก่อน 8/16 → หลัง 11/16 ผ่าน (`qa/five_second_test.md`); เช็กลิสต์ใน `ui_critique.md`
- แก้หลัง 5-second test: หน้าหลักแสดงยอดขาดตามแผนก่อน ยอดขาดถ้าซื้อกินทุกมื้อเบาลงเป็น ink2 (ซ่อนแถวซ้ำเมื่อตู้ว่าง); หน้าลิ้นชักผักตอนปิด 42% → 30% ของแถว; ชื่อเหรียญ `clear_expiring` ย่อเป็น "เคลียร์ของใกล้หมด" ไม่ตัดกลางคำ
- แก้บั๊ก: `menuSuggestionProvider` ไม่เสนอเมนูที่ไม่มีของในตู้เลย

## ค้างอยู่ / ปัญหา
- 5-second test ยังไม่ผ่าน 5 จอ สาเหตุหลัก: ไม่มีทางเพิ่มของเข้าตู้เอง (สแกนยังไม่มี; เพิ่มเองเป็นฟีเจอร์ → L3) ทำให้ตู้ว่าง / สแกน / หน้าหลักตอนตู้ว่างเป็นทางตัน
- sheet ผลสุ่มที่ของไม่ครบไม่มีการกระทำถัดไป
- ชิปตัวกรองชิดขอบขวาไม่มีสัญญาณว่าเลื่อนได้
- กรอบตู้ > ช่องแช่แข็ง > กระเบื้อง อ่านเหมือนกล่องซ้อน 3 ชั้น
- วันที่ไม่ได้บันทึกรายจ่ายนับเป็น "อยู่ในงบ" (ADR-010) — รอ "ปิดวันตอนค่ำ"
- ยังไม่ทดสอบบนมือถือจริง (ไม่มี Android SDK ในเครื่อง)
- `test/golden/failures/*.png` ถูก track ใน git และมีการเปลี่ยน — เป็นไฟล์ผลเทสต์ล้ม ไม่ควร commit (เสนอเพิ่มใน `.gitignore`)

## ขั้นต่อไป (เสนอ)
1. ผู้ก่อตั้งรีวิว CP2: ภาพ `design/shots/{before,after}/`, ทิศ A + สำรอง B, ตอบคำถาม L3 ด้านล่าง
2. commit งาน sprint บน `dev` แล้ว merge เข้า `main` เมื่อ CP2 ผ่าน
3. แก้จุดที่ 5-second test ยังไม่ผ่าน ที่ไม่ต้องรอ L3 (การกระทำถัดไปใน sheet ผลสุ่มไม่ครบ, สัญญาณเลื่อนชิปตัวกรอง, ลดกล่องซ้อนในตู้)
4. นอก sprint: แผนกินวนเมนูเดิมทุกวัน; เครื่องปรุงถูกนับแคลอรี่; ขาดวัตถุดิบหลักบ้านไทย; ภาพจานอาหาร
5. แท็บสแกน (หลังมี Android + ADR เลือกแพ็กเกจกล้อง/ML Kit)

## กติกาถาวรจากผู้ก่อตั้ง
- เมื่อ token ใกล้หมด: ส่ง build Android/iOS ให้ดาวน์โหลดผ่าน GitHub หรือ QR (เครื่องไม่มี Android SDK → ใช้ GitHub Actions)

## คำถาม L3
- ใช้แล้ว รอยืนยัน (ย้อนได้ใน `strings.dart` / `home_page.dart` เท่านั้น):
  1. หัวข้อหน้าหลักเป็น "ทำกินเองจากของในตู้ได้อีก x มื้อ" แทน "วัน" ตามสเปก 5.3
  2. ชื่อแท็บ "แดชบอร์ด" → "สมุดค่ากิน"
- ยังเปิดอยู่: สิทธิ์อ่าน Figma; ไฟล์ Unity เดิม (+ เดโม HTML / `ui_design_prompt.md`); ติดตั้ง Android Studio; ฟีเจอร์ที่เลื่อนไว้ (รายการซื้อของ, แจ้งเตือน, ปิดวันตอนค่ำ); เพิ่มของเข้าตู้เอง; เปิดครั้งแรกเริ่มจากตู้ว่างไหม
- ตอบแล้ว: ADR-007, ADR-008

## ไฟล์ที่แก้ล่าสุด
`lib/app/{strings.dart,theme/**}`, `lib/features/{home,fridge,random,dashboard,scan,budget}/presentation/**`, `lib/features/home/domain/home_providers.dart`, `lib/shared/widgets/{ledger,ingredient_tile,recipix_page}.dart`, `lib/shared/utils/freshness_color.dart`, `lib/shared/icons/recipix_icon.dart`, `assets/icons/{home,dashboard,wallet,tag,bowl}.svg` (ลบ `coin.svg`), `tool/gen_icons.sh`, `test/**` (รวม `test/design/`, golden), `docs/**`, `handoff.md`
