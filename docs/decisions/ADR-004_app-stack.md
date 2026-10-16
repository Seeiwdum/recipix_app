---
title: ADR-004 App stack - state, navigation, SVG, font
owner: เมธ
last_updated: 2026-10-16
version: 1.0
status: accepted
---

# ADR-004: แพ็กเกจหลักของแอป

- **ระดับ:** L2
- **ตรวจเวอร์ชันจาก:** `flutter pub add` (resolve จาก pub.dev จริง) + CHANGELOG ใน pub cache เมื่อ 2026-10-16

| ด้าน | เลือก | เวอร์ชัน | เหตุผล |
|---|---|---|---|
| State | `flutter_riverpod` | ^3.4.3 | Notifier แทน Presenter ของ MVP เดิม, override ใน test ง่าย (เช่น ฉีด `today`) |
| Navigation | `go_router` | ^18.1.0 | `StatefulShellRoute.indexedStack` เก็บสถานะแต่ละแท็บ; `goBranch` สลับแท็บ; รองรับ deep link ภายหลัง |
| SVG | `flutter_svg` | ^2.3.0 | ไอคอนวาดเองเป็นไฟล์ SVG `currentColor` ผ่าน `colorFilter` |
| ฟอนต์ | IBM Plex Sans Thai (OFL 1.1) | google/fonts repo | ฟอนต์เดียวตามสเปก บันเดิลใน `assets/fonts/` น้ำหนัก 400/500/600 |

## หมายเหตุ
- go_router 18 ย้ายไปพึ่ง `material_ui`/`cupertino_ui` แต่ `package:flutter/material.dart` ยังอยู่ใน Flutter 3.47.7 — แอปใช้ตามเดิม
- Tab bar เขียนเอง (ไม่ใช้ `NavigationBar` ของ Material) เพื่อคุมรูปลักษณ์และทรานซิชันตาม design system
- ยังไม่เลือก DB/แจ้งเตือน/กล้อง — ทำใน Phase 3 พร้อม ADR แยก
