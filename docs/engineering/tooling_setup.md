---
title: Tooling Setup
owner: นุ่น (Tooling)
last_updated: 2026-10-16
version: 1.1
status: active
---

# สภาพเครื่องและเครื่องมือ (ตรวจเมื่อ 2026-10-16)

| รายการ | ค่า |
|---|---|
| OS | Windows 11 Pro 24H2 (10.0.26100), locale th-TH |
| Git | 2.55.0.windows.5 |
| Flutter | 3.47.7 stable (`D:\Ok bro\flutter`) |
| Dart | 3.13.5 |
| DevTools | 2.60.0 |
| VS Code | ติดตั้งแล้ว (`code` CLI ใช้ได้) + extension `dart-code.dart-code`, `dart-code.flutter` |
| อุปกรณ์รัน | Chrome (web), Edge (web), Windows desktop (แต่ build ไม่ได้ ดูด้านล่าง) |

## flutter doctor
- OK: Flutter, Windows version, Chrome, Connected device, Network
- ขาด: **Android toolchain** (ไม่มี Android SDK) — ต้องติดตั้ง Android Studio เอง (มีหน้าต่างติดตั้ง/ยอมรับ license) → ยังไม่จำเป็นตอนนี้ ใช้ Chrome ไปก่อน
- ขาด: **Visual Studio (Desktop C++)** — จำเป็นเฉพาะ build Windows desktop ซึ่งไม่ใช่เป้าหมาย ข้ามได้
- iOS ต้องใช้ Mac — L3 ภายหลัง

## เป้าหมายรันหลัก
`flutter run -d chrome` (mobile viewport ทดสอบด้วย DevTools/Browser pane 360/390/430)

## ปัญหาที่เจอ
1. **path ของ Flutter มีช่องว่าง** (`D:\Ok bro\flutter`): `flutter pub add` ผ่าน Git Bash ล้มด้วย `'D:\Ok' is not recognized` → ใช้ PowerShell เรียก `flutter` หรือแก้ `pubspec.yaml` เองแล้ว `flutter pub get`. `dart` ใน Git Bash ใช้ได้ปกติ
   - ทางแก้ถาวร (ทางเลือก): ย้าย SDK ไป path ไม่มีช่องว่าง เช่น `D:\flutter` แล้วแก้ PATH — เครื่องผู้ก่อตั้ง ไม่ทำเอง
2. โปรเจกต์ถูกสร้างไว้แล้วชื่อ `recipix_app` (ไม่ใช่ `recipix`) — คงชื่อนี้ (L1)

## MCP
- Dart/Flutter มี MCP server ทางการ: `dart mcp-server` (มากับ Dart SDK 3.13.5 — ตรวจด้วย `dart mcp-server --help`) มีเครื่องมือ analyze_files, run_tests, hot_reload, widget_inspector, pub_dev_search ฯลฯ
- ตั้งค่าแล้วใน `.mcp.json` (ขอบเขตโปรเจกต์) — เซสชันถัดไป Claude Code จะถามให้อนุมัติ server นี้; ตรวจสถานะด้วย `/mcp`
- วงจรหลักไม่พึ่ง MCP: แก้ไฟล์ → analyze → test → run

## Git
- `main` = commit แรก (scaffold); `dev` = งานปัจจุบัน

## Preview บนเว็บ (เพิ่ม 2026-10-16)
- `.claude/launch.json` → `flutter run -d web-server --release --web-port 8080` ใช้กับ browser pane ของ Claude
- โหมด debug ของ `web-server` ค้างหน้าขาว (รอ Dart Debug extension) → ใช้ `--release` สำหรับ preview; build ครั้งแรกประมาณ 30 วินาที
- ถ้าเปิดหน้าก่อน build เสร็จ จะค้างหน้าเก่า → โหลดใหม่หลังเห็น "Built build\web"
- ผู้ก่อตั้งรันเองใน VS Code: `flutter run -d chrome` (มี hot reload)

## เครื่องมือในรีโป
- `tool/gen_icons.sh`, `tool/gen_ingredients.sh` สร้าง SVG ใน `assets/` (รันด้วย Git Bash)
- goldens: `flutter test --update-goldens test/golden` เฉพาะเมื่อจงใจเปลี่ยนหน้าตา
