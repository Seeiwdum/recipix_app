---
title: ADR-009 On-device persistence
owner: เมธ / นุ่น
last_updated: 2026-10-16
version: 1.0
status: accepted
---

# ADR-009: บันทึกข้อมูลในเครื่อง

- **ระดับ:** L2 (เลือก DB) ภายใต้ L3 ของ ADR-007 "เก็บในเครื่องเท่านั้น"
- **ตรวจเวอร์ชัน:** `flutter pub add shared_preferences` → ^2.5.6 (pub.dev, 2026-10-16); ใช้ `SharedPreferencesAsync` (API ใหม่ที่แพ็กเกจแนะนำ)

## ตัวเลือกที่เทียบ
| ตัวเลือก | ข้อดี | ข้อเสีย |
|---|---|---|
| **shared_preferences + JSON snapshot** (เลือก) | ง่าย, ทำงานบน Android/iOS/web ทันที (web = localStorage), ทดสอบง่าย | ไม่ใช่ DB: ทุกครั้งเขียนทั้งก้อน, ไม่มี query |
| drift (SQLite) | query, migration ดี | บนเว็บต้องตั้ง sqlite3.wasm + worker; code generation; หนักเกินข้อมูลตอนนี้ |
| sembast / hive_ce | document store | อีกหนึ่ง dependency ที่ทีมต้องดูแล ยังไม่จำเป็น |

ขนาดข้อมูลตอนนี้เล็ก (ของในตู้ ~25 ชิ้น, รายจ่าย ~100 รายการ/เดือน) → JSON ทั้งก้อน < 50 KB ต่อ section; ถ้าโตเกิน (เช่น ประวัติหลายปี) ค่อยย้ายเป็น drift — โค้ดอ่าน/เขียนอยู่หลัง `KeyValueStore` และ codec จึงเปลี่ยนเฉพาะชั้นนี้

## การตัดสินใจ
1. **2 section แยก key:** `recipix.fridge.v1` (ของในตู้ + ตำแหน่งบนชั้น + ประวัติทำกิน `{recipeId, date}`) และ `recipix.budget.v1` (งบรอบ, วันเงินเข้า, ราคา, ปุ่มลัด, รายจ่าย) — มี `"v": 1` ในเนื้อข้อมูลสำหรับ migration
2. **Codec เป็น Dart ล้วน** (`lib/shared/persistence/codecs.dart`) แปลงเงินเป็นสตางค์ int, วันที่เป็น `YYYY-MM-DD`, enum เป็นชื่อ — ไม่ใส่ JSON ใน `recipix_core` เพื่อให้ core สะอาด
3. **โหลดก่อนเฟรมแรก** ใน `main()` แล้ว inject ผ่าน `savedDataProvider`; controller ใช้ข้อมูลที่บันทึกไว้ถ้ามี ไม่งั้นใช้ข้อมูลตัวอย่าง
4. **บันทึกทุกครั้งที่ state เปลี่ยน** (`listenSelf` ใน Notifier) แบบรวมเป็นครั้งเดียวต่อ microtask; การลากของยังไม่เปลี่ยน state จนกว่าจะวาง จึงไม่เขียนถี่
5. **ข้อมูลเสียห้ามเขียนทับเงียบๆ** (กติกา L3 เรื่องลบข้อมูลกู้คืนไม่ได้): ถ้าอ่านไม่ออก เก็บต้นฉบับไว้ที่ `<key>.corrupt.<timestamp>` ก่อน แล้วเริ่มจากข้อมูลตัวอย่าง
6. **ไม่บันทึก:** ตัวกรอง, สถานะ undo (หมดอายุตาม toast อยู่แล้ว)
7. **ครั้งแรกที่เปิดแอป** ยังเติมข้อมูลตัวอย่าง เพราะยังเพิ่มของเองไม่ได้ (แท็บสแกนยังไม่มี) — เมื่อมีทางเพิ่มของจริงแล้ว ควรเริ่มจากตู้ว่าง (ให้ผู้ก่อตั้งตัดสินตอนนั้น)
8. **Windows Developer Mode:** `flutter pub add` บน Windows ขอ symlink สำหรับปลั๊กอิน — จำเป็นเฉพาะ build Windows/Linux desktop ไม่กระทบเว็บ/Android; เปิดได้ที่ `start ms-settings:developers` (ผู้ก่อตั้งทำเอง — เป็นการตั้งค่าระบบ)
