---
title: App icon and logo
owner: วีน่า (Design)
last_updated: 2026-10-17
version: 1.0
status: active
---

# โลโก้และไอคอนแอป Recipix

## ตัวโลโก้
- ตู้เย็นสองประตูสีครีม (`#F7F3EC`) บนพื้นเขียวแบรนด์ (`#2F6B4F`) มีใบไม้งอกจากหลังตู้ ความหมาย: เก็บของให้สดจนถึงวันเงินเดือนออก
- รูปทรงแบนล้วน ไม่มี gradient ไม่มีเงา ไม่มีอีโมจิ (ข้อห้าม UI ข้อ 1–3)
- ต้นฉบับมีที่เดียว: `lib/shared/widgets/recipix_logo.dart` (`RecipixLogo`, `RecipixLogoPainter`) ใช้ทั้งในแอป (หน้าต้อนรับ) และใช้สร้างไฟล์ไอคอน
- ไฟล์สำหรับงานออกแบบ: `assets/brand/logo.svg` (ขนาดตรงกับโค้ด)

## ไฟล์ไอคอนที่ใช้จริง
| ไฟล์ | ใช้ที่ |
|---|---|
| `assets/brand/app_icon.png` (1024×1024, พื้นเขียว) | iPhone, เว็บ, Android รุ่นเก่า |
| `assets/brand/app_icon_foreground.png` (1024×1024, พื้นโปร่งใส) | Android adaptive icon (พื้นหลังเป็นสีเขียว `#2F6B4F`) |

เครื่องมือ `flutter_launcher_icons` 0.14.4 (ตั้งค่าใน `flutter_launcher_icons.yaml`) แปลงไฟล์ 2 ไฟล์นี้เป็นไอคอนทุกขนาดใน `android/…/res`, `ios/…/AppIcon.appiconset`, `web/icons`

## วิธีเปลี่ยนโลโก้
### ก. แก้รูปทรงในโค้ด
1. แก้ `RecipixLogoPainter` ใน `lib/shared/widgets/recipix_logo.dart` (พิกัดอยู่บนตาราง 1024)
2. วาดไฟล์ PNG ใหม่: `flutter test --dart-define=RENDER_ICON=true test/tool`
3. สร้างไอคอนทุกแพลตฟอร์ม: `dart run flutter_launcher_icons`
4. **ย้อนไฟล์ iOS ที่เครื่องมือแก้ผิด**: `git checkout -- ios/Runner.xcodeproj/project.pbxproj`
   - เครื่องมือ (0.14.4) เปลี่ยน `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` จาก `YES` เป็น `AppIcon` ซึ่งไม่เกี่ยวกับไอคอน
5. รันเทสต์ แล้ว commit → merge เข้า `main` → push → กด Run workflow "Android APK" / "Web app"

### ข. ใช้รูปโลโก้ของตัวเอง (เช่น ให้ดีไซเนอร์ทำมา)
1. เตรียม PNG ขนาด 1024×1024 สองไฟล์
   - `app_icon.png`: ภาพเต็ม ไม่โปร่งใส ไม่ต้องทำมุมมน (ระบบตัดมุมเอง)
   - `app_icon_foreground.png`: พื้นโปร่งใส วางโลโก้กลางภาพ ไม่ให้เกินประมาณ 70% ของภาพ (Android ตัดขอบเป็นวงกลม/สี่เหลี่ยมมน)
2. วางทับไฟล์เดิมใน `assets/brand/`
3. ถ้าสีพื้นเปลี่ยน แก้ `adaptive_icon_background` / `background_color_ios` ใน `flutter_launcher_icons.yaml`
4. ทำข้อ ก.3–ก.5 (ข้ามข้อ ก.2 เพราะใช้ภาพของตัวเองแล้ว)

### ทดสอบบนมือถือ
- Android: ลบแอปเก่าก่อน (APK ทดสอบเซ็นด้วยคีย์ที่ต่างกันทุกรอบ) แล้วลง APK ใหม่ ไอคอนบางเครื่องอาจต้องรีสตาร์ต launcher
- iPhone (เว็บ): ลบไอคอนเก่าบนหน้าจอโฮม แล้ว Add to Home Screen ใหม่ (Safari เก็บไอคอนเก่าไว้ใน cache)
