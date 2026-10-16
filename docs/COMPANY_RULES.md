---
title: Company Rules
owner: ธนากร (Governance)
last_updated: 2026-10-16
version: 1.0
status: active
---

# กฎบริษัท Recipix

ธนากรถือกฎชุดนี้ มีสิทธิ์สั่งหยุดงานที่ละเมิด

## R1 งานและการตัดสินใจ
1. ทุกงาน (ticket) มี Acceptance Criteria ก่อนลงมือ
2. ห้ามเดาข้อเท็จจริง/เวอร์ชัน/API — ตรวจจากเอกสารทางการ, pub.dev, โค้ด หรือผลคำสั่งจริง
3. การตัดสินใจ L2/L3 ต้องมี ADR ใน `docs/decisions/` (ADR-xxx_slug.md)
4. ถามผู้ก่อตั้งเฉพาะ L3 รวมเป็นชุดเดียว พร้อมตัวเลือก 2-3 ข้อและข้อแนะนำ; ถามเรื่อง L1/L2 = ผิดกฎ

## R2 โค้ด
1. Logic ธุรกิจเป็น Dart ล้วนใน `packages/recipix_core` และมี unit test
2. `recipix_core` ห้าม import Flutter; UI ห้ามมี logic ธุรกิจ
3. ห้าม hard-code สี/ระยะ/มุมมน/ฟอนต์/เวลาแอนิเมชันนอก tokens; ข้อความ UI รวมไว้ที่เดียว
4. เงินเก็บเป็น satang (int), วันที่เป็น `LocalDate` — ห้ามใช้ double สำหรับเงิน
5. ห้ามเก็บ key/credential ในรีโป

## R3 UI
1. ทำตามกฎเหล็ก 7 ข้อ (MASTER_PROMPT หมวด 5.1) — โดยเฉพาะห้าม Emoji
2. งาน UI ทุกชิ้นผ่านเช็กลิสต์ 5.5 และบันทึกใน `docs/ui_critique.md`

## R4 เอกสาร
1. ไฟล์ `.md` ทุกไฟล์มี front-matter: title, owner, last_updated, version, status
2. ห้ามลบเอกสารเก่า — เปลี่ยน status เป็น `deprecated`
3. จบเซสชัน/CP: อัปเดต handover_notes + INDEX + CHANGELOG แล้ว commit

## R5 Definition of Done
analyze ผ่าน + test ผ่าน + review + เช็กลิสต์ UI (ถ้าเกี่ยวข้อง) + เอกสารอัปเดต
ห้ามข้าม review + test แม้งานเล็ก

## R6 ความปลอดภัยการทำงาน
ทำงานบน `dev`; ห้าม force push, `git reset --hard`, `rm -rf` นอกโปรเจกต์ โดยไม่จำเป็น;
ห้ามแก้ `legacy_unity/`; ห้ามปล่อยแอป/ใช้บริการเสียเงินโดยไม่ถามผู้ก่อตั้ง
