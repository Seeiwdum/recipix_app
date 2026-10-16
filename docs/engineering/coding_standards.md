---
title: Coding Standards
owner: เมธ
last_updated: 2026-10-16
version: 1.0
status: active
---

# มาตรฐานโค้ด

- `dart format` ก่อน commit; lints: `flutter_lints` (แอป), `lints/recommended` + strict-casts/raw-types (core)
- Entity เป็น immutable (`final` ทุกฟิลด์, list ห่อ `List.unmodifiable`), ใช้ `copyWith`
- เงิน = `Money` (satang int); วันที่ = `LocalDate`; ปริมาณ = `Quantity`
- ห้าม `DateTime.now()` / `Random()` แบบไม่ฉีดเข้ามาใน logic — รับเป็นพารามิเตอร์เพื่อทดสอบได้
- คอมเมนต์อธิบาย "ทำไม" ไม่ใช่ "ทำอะไร"; ภาษาอังกฤษในโค้ด
- ข้อความ UI ภาษาไทยรวมไว้ที่ไฟล์ข้อความกลาง (Phase 1) ไม่กระจายใน widget
- ชื่อไฟล์ snake_case, คลาส PascalCase, 1 คลาสหลักต่อไฟล์
- commit message อังกฤษแบบ conventional (`feat:`, `fix:`, `docs:`, `chore:`, `test:`)
