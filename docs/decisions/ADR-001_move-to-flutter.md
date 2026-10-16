---
title: ADR-001 Move from Unity to Flutter
owner: ผู้ก่อตั้ง (NAMOE) / บันทึก: เมธ
last_updated: 2026-10-16
version: 1.0
status: accepted
---

# ADR-001: ย้ายจาก Unity ไป Flutter และพัฒนาใน VS Code

- **ระดับ:** L3 — ผู้ก่อตั้งตัดสินแล้ว ห้ามเปิดประเด็นซ้ำ
- **บริบท:** การให้ AI ทำงานใน Unity ต้องเปิดคอมพิวเตอร์ เปิด Unity และเชื่อม MCP ทุกครั้ง ยุ่งยากเกินไป
- **การตัดสินใจ:** ใช้ Flutter + Dart พัฒนาใน VS Code ผ่าน Claude Code; โปรเจกต์ Unity เดิมเป็นเอกสารอ้างอิงอ่านอย่างเดียว (`legacy_unity/` ถ้ามี)
- **ผลที่ตามมา:** logic เดิม (Pure C#) พอร์ตเป็น `packages/recipix_core`; MVP เดิมเปลี่ยนเป็น Notifier + Widget; ไม่ดูแลโค้ด Unity ต่อ
- **เงื่อนไขเปิดใหม่:** เจอ blocker ร้ายแรงจริง (ฟีเจอร์หลักทำไม่ได้ใน Flutter) — รายงานพร้อมหลักฐานและทางเลือก (L3)
