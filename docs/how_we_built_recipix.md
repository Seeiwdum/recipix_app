---
title: How Recipix was built — Flutter + VS Code + GitHub, start to finish
owner: แพรว (Docs)
last_updated: 2026-10-17
version: 1.0
status: active
---

# Recipix สร้างขึ้นมาอย่างไร (Flutter + VS Code + GitHub ตั้งแต่ต้นจนจบ)

## ภาพรวมเครื่องมือ
| เครื่องมือ | ใช้ทำอะไร |
|---|---|
| **Flutter 3.47.7 / Dart 3.13.5** | เขียนแอปครั้งเดียว ได้ทั้ง Android, iPhone, เว็บ |
| **VS Code** | เขียนโค้ด กด F5 รันแอปใน Chrome (`.vscode/launch.json` "Recipix (Chrome)") |
| **Git** | เก็บประวัติโค้ด สาขา `dev` ไว้ทำงาน สาขา `main` ไว้เก็บของที่ผ่านแล้ว |
| **GitHub** (`Seeiwdum/recipix_app`, Private) | ฝากโค้ดบนคลาวด์ + สั่ง build อัตโนมัติด้วย GitHub Actions |
| **GitHub Actions** | build ไฟล์ APK (Android) และเว็บแอปให้ เพราะเครื่องเราไม่มี Android SDK |
| **GitHub Pages** (`Seeiwdum/recipix_web`, Public) | เปิดเว็บแอปให้คนที่ไม่มี Android ใช้ |

## ขั้นตอนตั้งแต่ต้นจนจบ

### ช่วงที่ 0 — ตั้งเครื่องและโปรเจกต์ (16 ต.ค.)
1. ติดตั้ง Flutter SDK ไว้ที่ `D:\Ok bro\flutter` แล้วเพิ่ม `flutter\bin` ใน PATH
   - path มีช่องว่าง จึงรัน `flutter` ใน PowerShell ไม่ใช่ Git Bash
2. ติดตั้ง VS Code + ส่วนเสริม Flutter และ Dart
3. สร้างโปรเจกต์ด้วย `flutter create recipix_app` (commit แรก: "initial Flutter scaffold")
4. `git init`, สร้างสาขา `dev` สำหรับทำงานประจำวัน, `main` สำหรับเวอร์ชันที่ผ่านการตรวจ
5. ตัดสินใจย้ายจาก Unity มา Flutter (ADR-001)
6. แยก logic ธุรกิจเป็นแพ็กเกจ Dart ล้วน `packages/recipix_core` ซึ่งไม่ผูกกับหน้าจอ เทสต์ได้เร็ว เช่น:
   - การคำนวณ "อยู่ได้อีกกี่วัน" (`SurvivalEngine`)
   - วงล้อสุ่มวัตถุดิบ และการจับคู่เมนู
   - การตัดของตามปริมาณ (ใช้ของที่หมดอายุก่อนก่อน)
   - เหรียญรางวัล
7. วางระบบทีม: `CLAUDE.md` (กติกาโปรเจกต์), `.claude/agents` (ผู้ช่วย 9 บทบาท), `.claude/skills` (คู่มือ 6 ชุด), `docs/` (เอกสาร + ADR ทุกการตัดสินใจ)

### ช่วงที่ 1 — ระบบหน้าตา (16 ต.ค.)
8. **Design tokens**: สี ระยะ ฟอนต์ ความเร็วแอนิเมชัน อยู่ที่ `lib/app/theme/recipix_tokens.dart` ไฟล์เดียว
9. ฟอนต์ไทย IBM Plex Sans Thai (ฟรี, OFL) ฝังในแอป
10. ไอคอนและภาพวัตถุดิบเป็น SVG ที่วาดเอง ไม่มีอีโมจิ
11. โครงแอป 5 แท็บ พร้อมแอนิเมชันเปลี่ยนแท็บ ใช้:
    - `go_router` สำหรับเปลี่ยนหน้า
    - `flutter_riverpod` สำหรับเก็บสถานะ

### ช่วงที่ 2 — ทำทีละแท็บ (16 ต.ค.)
12. **ตู้เย็น**: เกมลากของจากตะกร้าขึ้นชั้น ช่องแช่แข็ง ลิ้นชักผัก ป้ายวันหมดอายุ
13. **หน้าหลัก**: ใบรายงานประจำวัน ของที่ต้องใช้ก่อน (ปัดซ้าย/ขวา)
14. **บันทึกค่ากิน + แผนกินถึงวันเงินเข้า** (ADR-008)
15. **บันทึกข้อมูลในเครื่อง** ด้วย `shared_preferences` ปิดแอปแล้วข้อมูลยังอยู่ (ADR-009)
16. **สมุดค่ากิน (แดชบอร์ด)**: แก้งบ วันเงินเข้า ราคาต่อมื้อ ไทม์ไลน์ เหรียญ
17. **สุ่มเมนู**: วงล้อ 3 แกน + โหมดสั่งข้างนอก

### ช่วงที่ 1.5 — ปรับ UI ให้ไม่ดูเหมือน AI ทำ (17 ต.ค.)
18. ถ่ายภาพทุกจอ 48 ภาพ (`test/design/shots_test.dart`) ให้ 5 มุมมองวิจารณ์ หา reference 16 ชิ้น แล้วเลือกทิศ "Kitchen Ledger" (ADR-012)
19. ปรับจากกล่องการ์ดเป็นบรรทัดแบบสมุดบัญชีที่มีจุดไข่ปลา ใช้ตัวเลขใหญ่ตัวเดียวต่อจอ และใช้สีแดงเฉพาะของที่หมดอายุ
20. ทดสอบ 5 วินาทีกับมุมมองผู้ใช้ใหม่: ผ่านจาก 8/16 เป็น 11/16 จอ

### ช่วงที่ 3 — ข้อมูลจริง (17 ต.ค.)
21. ปุ่ม **เพิ่มของ** เข้าตะกร้าเอง (ADR-013)
22. **สแกนบาร์โค้ด** (ADR-014):
    - ใช้ `mobile_scanner` อ่านบาร์โค้ด
    - ส่งเฉพาะตัวเลขบาร์โค้ดไปค้นชื่อสินค้าใน Open Food Facts
    - แอปจำบาร์โค้ดที่เคยสแกนไว้ในเครื่อง
23. **ถ่ายของ** (ADR-016): ถ่ายภาพ ให้ ML Kit ในเครื่องตีกรอบรอบของแต่ละชิ้น แล้วแตะกรอบเพื่อเลือกว่าเป็นอะไร ภาพไม่ออกนอกมือถือ

### ช่วงที่ 4 — เมนูและผู้ใช้ (17 ต.ค.)
24. **เมนูแนะนำ** 3 เมนูบนหน้าหลัก + **หน้าสูตร** (ADR-015): วัตถุดิบ วิธีทำ ระดับความยาก เหรียญที่จะได้
25. **คำถามตอนเปิดแอปครั้งแรก** (ADR-017): ชื่อ เมนูที่ชอบ เงินค่ากิน แล้วตั้งงบให้อัตโนมัติ

### วิธีทำงานแต่ละรอบ (ใช้ซ้ำทุกฟีเจอร์)
1. อ่าน `docs/handover_notes.md` + `docs/INDEX.md`
2. ถ้าเป็นการตัดสินใจระดับ L2 ขึ้นไป เขียน ADR ใน `docs/decisions/` ก่อน
3. เขียนโค้ด: logic ไว้ใน `packages/recipix_core` หรือ `lib/features/<แท็บ>/domain`, หน้าจอไว้ใน `presentation`
4. เขียนเทสต์คู่กัน
5. รันตรวจ 3 อย่าง (ต้องผ่านหมดก่อน commit):
   ```
   flutter analyze
   flutter test
   cd packages/recipix_core; dart test
   ```
6. ถ้าหน้าตาเปลี่ยนตั้งใจ: `flutter test --update-goldens test/golden` แล้วเปิดดูภาพ
7. `git commit` บน `dev` → `git merge` เข้า `main` → `git push`

## ส่วนของ GitHub ตั้งแต่ต้นจนจบ
1. **สร้าง repo**: github.com/new → ชื่อ `recipix_app` → Private → ไม่ติ๊ก README
2. **ผูกและ push** (ทำครั้งเดียว):
   ```
   git remote add origin https://github.com/Seeiwdum/recipix_app.git
   git push -u origin main dev
   ```
   ครั้งแรก Windows จะเปิดหน้าล็อกอิน GitHub ในเบราว์เซอร์
3. **Build APK อัตโนมัติ** (`.github/workflows/android-apk.yml`)
   - ทุกครั้งที่ push เข้า `main` หรือกด Actions → Android APK → Run workflow:
     1. ติดตั้ง Java 17 + Flutter
     2. `flutter analyze` + เทสต์ core
     3. `flutter build apk`
     4. สร้าง Release `build-N` พร้อม `recipix.apk` + `recipix-qr.png`
   - ปัญหาที่เจอและแก้แล้ว: ครั้งแรก analyze พังเพราะยังไม่ได้ `dart pub get` ใน `recipix_core`
   - ข้อควรระวัง: ปุ่ม Re-run ใช้โค้ดชุดเก่า ให้กด Run workflow แทน
4. **ลงแอปบนมือถือ**: เปิด Releases (repo Private ต้องล็อกอิน GitHub ในเบราว์เซอร์มือถือก่อน) → โหลด `recipix.apk` → อนุญาตติดตั้ง → ติดตั้ง
5. **เว็บแอป** (`.github/workflows/web.yml`): build เว็บแล้ว push ไฟล์ที่ได้ไป repo สาธารณะ `recipix_web` ซึ่งเปิด GitHub Pages ไว้ (ขั้นตอนตั้งค่าอยู่ด้านล่าง)

## ตั้งค่าเว็บแอป (ผู้ก่อตั้งทำครั้งเดียว ประมาณ 5 นาที)
1. github.com/new → ชื่อ `recipix_web` → **Public** → ติ๊ก **Add a README** (ให้มี branch เริ่มต้น) → Create
2. สร้าง token: github.com/settings/personal-access-tokens/new (Fine-grained)
   - Token name: `recipix-web-deploy`, Expiration ตามสะดวก
   - Repository access: **Only select repositories** → `recipix_web`
   - Permissions → Repository permissions → **Contents: Read and write**
   - Generate token แล้วคัดลอก (โชว์ครั้งเดียว)
3. ใส่ token เป็น secret ใน `recipix_app`: Settings → Secrets and variables → Actions → New repository secret
   - Name: `WEB_DEPLOY_TOKEN`
   - Secret: วาง token
4. สั่ง build: `recipix_app` → Actions → **Web app** → Run workflow → main (รอประมาณ 5 นาที)
5. เปิด Pages: `recipix_web` → Settings → Pages → Source: **Deploy from a branch** → Branch: `gh-pages` / `(root)` → Save
6. รอ 1–2 นาที แล้วเปิด **https://seeiwdum.github.io/recipix_web/**
   - iPhone: Safari → ปุ่ม Share → Add to Home Screen จะได้ไอคอนเหมือนแอป

## โครงสร้างโค้ดโดยย่อ
```
packages/recipix_core/   logic ล้วน (ไม่มี Flutter) + 69 เทสต์
lib/app/                 router, theme/tokens, shell (แถบแท็บ), strings (ข้อความไทยทั้งหมด)
lib/features/<แท็บ>/     data / domain / presentation
lib/shared/              widget, ไอคอน, motion, persistence ที่ใช้ร่วมกัน
assets/                  ฟอนต์ ไอคอน ภาพวัตถุดิบ ข้อมูลวัตถุดิบ/สูตร (JSON)
test/                    widget test + golden (ภาพหน้าจอเทียบ) 185+ เทสต์
docs/                    เอกสาร ADR handover CHANGELOG
.github/workflows/       android-apk.yml, web.yml
```
