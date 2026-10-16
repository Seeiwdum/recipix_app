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
