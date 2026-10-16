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
- `.claude/launch.json` → `flutter run -d web-server --release --web-port 8765` ใช้กับ browser pane ของ Claude
- โหมด debug ของ `web-server` ค้างหน้าขาว (รอ Dart Debug extension) → ใช้ `--release` สำหรับ preview; build ครั้งแรกประมาณ 30 วินาที
- ถ้าเปิดหน้าก่อน build เสร็จ จะค้างหน้าเก่า → โหลดใหม่หลังเห็น "Built build\web"
- ผู้ก่อตั้งรันเองใน VS Code: `flutter run -d chrome` (มี hot reload)

## เครื่องมือในรีโป
- `tool/gen_icons.sh`, `tool/gen_ingredients.sh` สร้าง SVG ใน `assets/` (รันด้วย Git Bash)
- goldens: `flutter test --update-goldens test/golden` เฉพาะเมื่อจงใจเปลี่ยนหน้าตา

## ติดตั้ง Android (ADR-007) — ตรวจกับ docs.flutter.dev/platform-integration/android/setup (Flutter 3.47) เมื่อ 2026-10-16
ส่วนที่ผู้ก่อตั้งทำเอง (ต้องกดยอมรับ license และอาจขอสิทธิ์ผู้ดูแลระบบ):
1. ติดตั้ง Android Studio รุ่น stable ล่าสุดจาก developer.android.com/studio
2. เปิด Android Studio → More Actions → SDK Manager
   - แท็บ SDK Platforms: เลือกรายการแรกที่เป็น API Level 36 → Apply
   - แท็บ SDK Tools: เลือก Android SDK Build-Tools, Android SDK Command-line Tools, Android Emulator, Android SDK Platform-Tools, CMake, NDK (Side by side) → Apply
3. ในเทอร์มินัล: `flutter doctor --android-licenses` แล้วอ่านและยอมรับ
ส่วนที่ทีมทำต่อได้: สร้าง emulator (Device Manager), เปิด hardware graphics, รัน `flutter doctor`, `flutter emulators`, `flutter devices`
- หลัง `preview_stop` ทันที บางครั้ง `preview_start` แจ้งว่า port "reserved by the OS" แต่ไม่ได้อยู่ใน excluded range จริง (ตรวจด้วย `netsh interface ipv4 show excludedportrange protocol=tcp`) → รอสักครู่แล้วสั่งใหม่ ไม่ต้องเปลี่ยน port

## Windows Developer Mode (เพิ่ม 2026-10-16)
- `flutter pub add` แพ็กเกจที่มีปลั๊กอิน (เช่น shared_preferences) บน Windows ขึ้นข้อความให้เปิด Developer Mode เพื่อสร้าง symlink — จำเป็นเฉพาะ build Windows/Linux desktop; เว็บและ Android ใช้ได้ (ตรวจแล้ว: `pub get` ผ่าน, web build ผ่าน)
- ถ้าจะ build บน Windows desktop หรือเครื่องมืออื่นต้องการ: ผู้ก่อตั้งเปิดเองที่ `start ms-settings:developers` (เป็นการตั้งค่าระบบ ทีมไม่แตะ)
