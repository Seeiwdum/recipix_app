---
title: Test Plan
owner: ฎา
last_updated: 2026-10-16
version: 1.0
status: active
---

# Test Plan

## ชั้นทดสอบ
| ชั้น | เครื่องมือ | ที่อยู่ | คำสั่ง |
|---|---|---|---|
| Unit (logic) | `package:test` | `packages/recipix_core/test/` | `dart test` |
| Widget | `flutter_test` | `test/` | `flutter test` |
| Golden (ต่อแท็บ, กว้าง 360/390/430) | `flutter_test` matchesGoldenFile | `test/golden/` | `flutter test --update-goldens` เมื่อจงใจเปลี่ยน |

## ความครอบคลุม core (CP1) — 47 เทสต์ผ่าน
- Survival: นับเฉพาะของไม่หมดอายุ, ÷2000, คูณตามปริมาณ, ของปริศนาแยก, urgent 0-2 วัน, วันเงินเข้า (สิ้นเดือน/วันที่ตั้ง/clamp เดือนสั้น/ข้ามปี), งบต่อวันปัดลง, BudgetDeficit ตาม ADR-002
- Slot: matcher %/jackpot/optional, rank, น้ำหนัก ExpiringFirst, ไม่ซ้ำ, ล็อกแกน, ตู้ว่าง, seed เดิมได้ผลเดิม
- Inventory: ตัดตามปริมาณ, FEFO, shortfall, ข้ามของหมดอายุ/หน่วยไม่เข้ากัน, หลาย batch
- Badges: นับ urgent, streak รีเซ็ต, stream ส่งครั้งเดียว, ปลดล็อกถาวร, โหลด progress เดิม, กฎกำหนดเอง
- Value types: LocalDate, Money, Quantity

## Regression ที่ต้องมีเสมอ (บั๊กเดโมเดิม)
คะแนนโอกาสรอดมั่ว / ของปริศนานับแคลอรี่ / ตัดสต็อกทั้งชิ้น / วันหมดอายุคงที่ / badge ฮาร์ดโค้ด / ราคาฮาร์ดโค้ด — ทั้งหมดมีเทสต์ใน core แล้ว

## ความครอบคลุมแอป (Phase 1) — 34 เทสต์ผ่าน
- `test/app_shell_test.dart`: 5 แท็บ, สลับหน้า, เวลาทรานซิชัน 220ms, กดซ้อนเร็ว, reduce-motion, ไม่ overflow ที่ 360
- `test/tokens_test.dart`: คอนทราสต์ทุกคู่ข้อความ >= 4.5:1, รัศมี 10/16/24, เวลา motion, line height ไทย >= 1.5
- `test/governance_test.dart`: emoji, สีนอก theme, รัศมีตัวเลข, gradient/blur/repeat, สเปกไอคอน, core ไม่ import Flutter
- `test/golden/`: home + fridge ที่ 360/390/430 (โหลดฟอนต์ไทยจริงใน test)

## แท็บตู้เย็น (Phase 2) — app รวม 61 เทสต์ผ่าน
- `test/features/fridge/fridge_layout_test.dart`: ขอบเขต/ชนกัน, ของกว้าง 2 กับชั้นประตู, closeGap, firstFree
- `test/features/fridge/fridge_controller_test.dart`: catalog (ไฟล์ + asset bundle), วาง/ปฏิเสธ, ใช้แล้ว+undo คืนเพื่อนบ้าน, undo หลังย้าย → ตะกร้า, ตัวกรอง/ความสด
- `test/features/fridge/fridge_page_test.dart`: ลากจากตะกร้าเข้าชั้น, เด้งกลับ (ประตู/ช่องเต็ม), ลากกลับตะกร้า, sheet → ใช้แล้ว → toast → เลิกทำ, จัดเข้าตู้ให้, ตัวกรองหรี่, ลิ้นชัก, ไม่ล้นที่ 360/430
- golden: `fridge_{360,390,430}`, `fridge_sheet_390`, `fridge_drag_390`

## แท็บหน้าหลัก (Phase 2) — app รวม 73 เทสต์ผ่าน, core 48
- `test/features/home/home_page_test.dart`: format (เลข/บาท/วัน/วันที่ไทย/ปัดบาทเต็ม), สูตรอ้างคีย์ใน catalog ครบ, ลำดับต้องใช้ก่อน, เมนูแนะนำ, รายงานนับตะกร้า/แยกของปริศนา, แสดงตัวเลข/ยอดขาด, ปัดขวา+เลิกทำ, ปัดซ้าย, ใช้ของแล้วตัวเลขลด, แตะเปิด sheet, ไม่ล้น 360/430
- golden: `home_{360,390,430}`

## บันทึกค่ากิน + แผนกิน — app 87, core 63
- core `budget_ledger_test.dart`: เริ่มรอบ (สิ้นเดือน/วันเงินเข้า/เดือนสั้น/ข้ามปี), นับเฉพาะในรอบ, งบวันนี้คงที่ตั้งแต่เช้า, ใช้เกิน
- core `meal_planner_test.dart`: จำนวนช่องมื้อ, ข้ามมื้อที่กินแล้ว, ตัดตามปริมาณ, ของเร่งด่วนก่อน/ไม่ใช้ของหมดอายุ, จะเสีย, ไม่นับของที่ไม่มีสูตรใช้, ไม่ซ้ำมื้อติดกัน, ไม่ใช้ของปริศนา
- app `spending_and_plan_test.dart`: ledger ตัวอย่าง, บันทึกแล้วยอดขาดขึ้น, กินข้างนอก = 1 มื้อ, ทำกิน+เลิกทำ, ของหมดออกจากชั้น, ทำไม่ได้ไม่เปลี่ยนอะไร, flow บันทึก+เลิกทำ, ปุ่มลัด/หมวด/ปุ่มปิด, เปิดแผน→ทำกิน→เลิกทำ→กลับ, toast หายใน 5 วินาที, ไม่ล้น 360/430

## บันทึกข้อมูลในเครื่อง (ADR-009) — app 95
- `test/persistence_test.dart`: codec ไป-กลับ (ของ, ตำแหน่ง, รายจ่าย, ราคา), ตำแหน่งที่วางไม่ได้แล้วกลับตะกร้า, เปิดครั้งแรกบันทึกตัวอย่าง, เปิดใหม่วันถัดไปข้อมูลครบ (วาง/ใช้/ทำกิน/จ่าย) และวันที่ตัวอย่างไม่เลื่อน, ประวัติทำกินที่โหลดมา undo ไม่ได้, ข้อมูลเสียถูกสำรองก่อน, schema ไม่รู้จัก = เสีย, เปลี่ยนรัวๆ เขียนครั้งเดียว
- ตรวจมือบน Chrome: บันทึก 75 บาท → reload หน้า → ยังแสดง "ใช้ไป 75 · เหลือ 25 บาท", ยอดขาด 856

## แดชบอร์ด (ADR-010) — app 109+, core 64
- `test/features/dashboard/dashboard_test.dart`: setter งบ/วันเงินเข้า/ราคาไหลไปทุกตัวเลข, ขอบเขต, ไม่มีเหรียญจากตัวอย่างล้วน, ใช้ของเร่งด่วน+undo, ทำกิน+undo, streak งบจากงบรายวันตอนเช้า (ปลดล็อก 7 ต.ค.), วันก่อนติดตามไม่นับ zero-waste, เส้นเวลา 31 วัน, อันดับเมนู, stepper บนจอ, กดค้างเร่ง, แตะเหรียญเห็นกติกา, ไม่ล้น 360/430
- core: วันที่ไม่ได้ติดตาม (discardedCount = null) ไม่นับ zero-waste แต่ยังนับงบ
- persistence: activity / urgentItemsUsed / trackingSince ผ่านการเปิดใหม่
- golden: `dashboard_{360,390,430}`
