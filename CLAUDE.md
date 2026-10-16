# Recipix — CLAUDE.md

**ก่อนเริ่มงานทุกครั้ง: อ่าน `docs/handover_notes.md` และ `docs/INDEX.md` ก่อน** แล้วค่อยลงมือ
คุยกับผู้ก่อตั้ง (NAMOE) เป็นภาษาไทย; ชื่อคลาส โค้ด คำสั่ง commit message เป็นภาษาอังกฤษ

## ภารกิจ
- Recipix = แอปมือถือจัดการวัตถุดิบในตู้เย็น + งบอาหารให้รอดถึงวันเงินเดือนออก (Survival Mode)
- แนะนำเมนูจากของที่มี (Recipe Matching) และสุ่มเมนูด้วยวงล้อ (Slot Machine) + เหรียญรางวัล (Badge)
- ผู้ใช้: คนทำงาน/นักศึกษาในไทย อาหารไทยชีวิตประจำวัน
- งานตอนนี้: พอร์ตจาก Unity เป็น Flutter + ออกแบบ UI ใหม่ ("ครัวกระดาษ" มินิมอล ไม่ใช่โฆษณา)
- สเปกเต็ม: `docs/MASTER_PROMPT.md` (ภาพรวม) และ `docs/ui_design_prompt.md` (UI — ถ้ามี)

## ADR-001 (ปิดแล้ว ห้ามเปิดซ้ำ)
ย้ายจาก Unity มา Flutter + VS Code แล้ว โปรเจกต์ Unity (ถ้ามีใน `legacy_unity/`) อ่านอย่างเดียว ห้ามแก้
เปิดประเด็นได้เฉพาะเจอ blocker ร้ายแรงจริง พร้อมหลักฐาน (L3)

## คำสั่งหลัก
Flutter SDK อยู่ที่ `D:\Ok bro\flutter` (path มีช่องว่าง) — ใช้ PowerShell เรียก `flutter` ไม่ใช่ Git Bash
```
flutter analyze                      # ทั้งรีโป รวม packages/
flutter test                         # widget/golden test ของแอป
cd packages/recipix_core; dart test  # unit test ของ logic ธุรกิจ
flutter run -d chrome                # เป้าหมายรันหลักตอนนี้ (ยังไม่มี Android SDK)
dart format .
```

## โครงสร้าง
```
packages/recipix_core/  Dart ล้วน: entities, SurvivalEngine, IngredientSlotMachine,
                        InventoryService, AchievementManager (+ test/) ห้าม import Flutter
lib/app/                router, theme/tokens, shell (tab bar)
lib/features/<tab>/{data,domain,presentation}   tabs: home fridge scan random dashboard
lib/shared/             widgets, icons, motion, utils
assets/                 icons/ ingredients/ fonts/ data/
docs/                   เอกสารทั้งหมด (ดู docs/INDEX.md)
.claude/agents, .claude/skills   ทีมและ skill ประจำโปรเจกต์
```
กฎชั้น: UI ห้ามมี logic ธุรกิจ; สี/ระยะ/ฟอนต์/เวลาแอนิเมชันมาจาก tokens เท่านั้น; ข้อความ UI ไม่ฮาร์ดโค้ดกระจาย

## ข้อห้าม UI 7 ข้อ (ละเอียดใน skill `recipix-design-system`)
1. ห้าม Emoji ทุกที่ (ไอคอน รูปอาหาร ข้อความ ชื่อเหรียญ) — ใช้ SVG วาดเอง
2. ห้ามพื้นหลังเรืองแสง/aurora/อนุภาค/กริดซ้อน, ห้าม glassmorphism
3. ห้าม gradient เป็นสีหลัก, ห้าม glow, ห้ามเงาฟุ้ง
4. ห้ามแอนิเมชันวนไม่จบ (ยกเว้นตัวโหลดจริง)
5. ห้ามป้ายอังกฤษตัวใหญ่/ศัพท์การตลาด, ห้าม ! พร่ำเพรื่อ
6. ห้ามการ์ดซ้อนการ์ด, ปุ่ม Primary ไม่เกิน 1 ต่อจอ, ห้าม confetti/pop-up ลอย
7. สงสัยว่าควรเพิ่มไหม = ไม่เพิ่ม

## ระดับการตัดสินใจ
- L1 (ชื่อ, implement, โฟลเดอร์, บั๊ก, เทสต์, UI เล็ก, ค่าบาลานซ์): ทำเลย บันทึกไว้
- L2 (state mgmt/DB/แพ็กเกจหลัก, โครงโมดูล, requirement ย่อย, ลำดับงาน): ทำเลย ต้องมี ADR ใน `docs/decisions/` และแจ้งในรายงาน CP
- L3 (เปลี่ยนเทคหลัก, เพิ่ม/ตัดฟีเจอร์หลัก, เงิน/บริการเสียเงิน, ขึ้น Store, ข้อมูลส่วนบุคคล, ลบข้อมูลกู้ไม่ได้, ข้อมูลที่หาเองไม่ได้): ถามผู้ก่อตั้ง รวมเป็นชุดเดียว พร้อมตัวเลือกและข้อแนะนำ
- ระหว่างรอ L3 ให้ทำงานส่วนอื่นต่อ; ไม่ถาม ≠ ไม่ตรวจ

## Definition of Done
`flutter analyze` ผ่าน + `flutter test` + `dart test` ผ่าน + review ตัวเอง (หรือ subagent `meth-reviewer`)
+ เช็กลิสต์ UI (ถ้าแตะ UI, บันทึกใน `docs/ui_critique.md`) + อัปเดตเอกสาร
ห้ามเดาเวอร์ชัน/API — ตรวจจาก pub.dev, เอกสารทางการ หรือผลคำสั่งจริง

## Git
ทำงานบน `dev`, `main` เก็บสถานะที่ผ่าน CP; commit ทีละช่วง; ห้าม force push / reset --hard / เก็บ credential

## จบเซสชัน
รัน `/recipix-handover` (อัปเดต handover_notes, INDEX, CHANGELOG แล้ว commit) — ห้ามลืม
