---
title: ADR-007 Founder decisions batch (Android, data, scanning, legacy files)
owner: ผู้ก่อตั้ง (NAMOE) / บันทึก: พิม
last_updated: 2026-10-16
version: 1.0
status: accepted
---

# ADR-007: การตัดสินใจของผู้ก่อตั้ง ชุด 2026-10-16 (L3)

| เรื่อง | ตัดสินใจ | ผลที่ตามมา |
|---|---|---|
| ทดสอบบนมือถือ | ติดตั้ง Android Studio + emulator | ผู้ก่อตั้งติดตั้งเอง (ต้องกดยอมรับ license); ทีมตั้ง emulator และรัน `flutter doctor` ต่อ; ขั้นตอนอยู่ใน `engineering/tooling_setup.md` |
| ที่เก็บข้อมูลผู้ใช้ | **ในเครื่องเท่านั้น** ไม่มีบัญชี ไม่มี server | ใช้ DB ในเครื่อง (Phase 3, ADR แยก); ไม่มีข้อมูลส่วนบุคคลออกนอกเครื่อง; sync/แชร์ตู้เป็นเรื่อง L3 ใหม่ถ้าจะทำ |
| จำของจากกล้อง | **ML Kit ในเครื่อง** (ฟรี, offline) | บาร์โค้ด + อ่านใบเสร็จ (text recognition) เป็นหลัก; ของที่จำไม่ได้กลายเป็น "ของปริศนา" ให้ผู้ใช้แก้ชื่อ; ไม่ส่งภาพออกนอกเครื่อง ไม่มีค่าใช้จ่าย API |
| ไฟล์ต้นฉบับเดิม | ผู้ก่อตั้งจะวางให้ (Unity `legacy_unity/`, เดโม HTML 2.2, `docs/ui_design_prompt.md`) | เมื่อได้ไฟล์: เทียบสูตร BudgetDeficit กับ ADR-002, ชื่อเหรียญเดิม, และสเปก UI ฉบับเต็ม แล้วออก ADR แก้ถ้าต่างกัน |
