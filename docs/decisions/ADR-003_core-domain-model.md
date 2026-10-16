---
title: ADR-003 Core domain model (dates, money, quantities, badges)
owner: เมธ / ริน
last_updated: 2026-10-16
version: 1.0
status: accepted
---

# ADR-003: โมเดลโดเมนใน recipix_core

- **ระดับ:** L2
- **การตัดสินใจ:**
  1. วันที่ใช้ `LocalDate` (ไม่มีเวลา/เขตเวลา) คำนวณด้วย UTC ภายใน — วันหมดอายุเก็บเป็น "วันที่" จริง แล้วคำนวณวันเหลือจาก `today` ที่ส่งเข้ามา (แก้บั๊กเดโมที่เก็บเป็นตัวเลขวันคงที่)
  2. เงินใช้ `Money` เก็บเป็นสตางค์ (int) — ไม่มีเศษ float
  3. ปริมาณใช้ `Quantity(amount, unit)` แปลงหน่วยในมิติเดียวกัน (ชิ้น / กรัม-กิโลกรัม / มล.-ลิตร); `kcalPerUnit` อิงหน่วยของชิ้นนั้น
  4. ของปริศนา = `IngredientItem.key == null`; แคลอรี่เป็นค่าประมาณ ไม่จับคู่สูตร
  5. ทำเมนูผ่าน `InventoryService.cook` ตัดตามปริมาณ เรียงของหมดอายุก่อน (FEFO) คืน shortfall ถ้าไม่พอ
  6. Badge = `BadgeRule` (CountingRule / StreakRule) ประเมินจาก `RecipixEvent` (sealed) ใน `AchievementManager`; ปลดล็อกแล้วถาวร; กระจายผ่าน `Stream<BadgeUnlocked>`; ชื่อเหรียญภาษาไทยอยู่ฝั่งแอป core รู้แค่ id
  7. `ExpiringFirstRollStrategy` สุ่มแบบถ่วงน้ำหนัก `1/(daysLeft+1)^2` ไม่ใช่เรียงตายตัว เพื่อให้ยังสุ่มจริง
  8. `matchPercentage` ปัดลง (99.6% ไม่แสดงเป็น 100%); `isJackpot` = ไม่ขาดอะไร; วัตถุดิบ optional ไม่นับว่าขาด
- **ผลที่ตามมา:** core ไม่มี dependency ภายนอกนอกจาก dev (`test`, `lints`); ทุกฟังก์ชันรับ `today` ทำให้ทดสอบได้แน่นอน
