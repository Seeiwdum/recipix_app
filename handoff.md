---
title: Handoff — Recipix (Flutter)
owner: พิม (Chief of Staff) / ผู้ก่อตั้ง: NAMOE
last_updated: 2026-10-17
version: 1.0
status: active
---

# Handoff — Recipix

สรุปทุกอย่างที่ต้องรู้เพื่อทำต่อ: เป้าหมาย, แผนงาน, สถานะ ณ ตอนหยุด, และโค้ด/ตรรกะสำคัญ
อ่านคู่กับ `CLAUDE.md` (กติกาทำงาน) และ `docs/handover_notes.md` (สถานะละเอียดก่อน sprint นี้)

---

## 1. สถานะตอนหยุด (อ่านก่อน)

| | |
|---|---|
| branch | `dev` |
| commit ล่าสุด | งาน PHASE 1.5 commit บน `dev` แล้ว (ต่อจาก `ab73121`) |
| งานที่ค้าง | UI Refinement Sprint (Phase 1.5) ขั้น A–F เสร็จ เหลือผู้ก่อตั้งรีวิว CP2 |
| สภาพ working copy | คอมไพล์ผ่าน, `flutter analyze` สะอาด |
| เทสต์ | แอป 128 ผ่าน (shot test 48 ตัวข้ามเมื่อไม่ใส่ `SHOTS`), core 65 ผ่าน, golden 14 ภาพ regenerate แล้ว |

**ทำต่อ:** ผู้ก่อตั้งรีวิว CP2 (ภาพ `docs/design/shots/{before,after}/`, 5-second test 8/16 → 11/16, คำถาม L3 ข้อ 6) → merge `main` เมื่อผ่าน

---

## 2. เป้าหมาย

- **Recipix** = แอปมือถือ (Flutter) สำหรับคนทำงาน/นักศึกษาไทย: จัดการของในตู้เย็น + งบค่ากินให้รอดถึงวันเงินเข้า (Survival Mode) + แนะนำเมนูจากของที่มี + สุ่มเมนู (สล็อต) + เหรียญรางวัล
- ย้ายจาก Unity มา Flutter แล้ว (ADR-001, ปิดแล้ว)
- UI: "ครัวกระดาษ" มินิมอล อบอุ่น **ไม่ใช่ AI slop และไม่ใช่โฆษณา**; ห้าม emoji / gradient / glow / blur ตกแต่ง / แอนิเมชันวนไม่จบ / ปุ่มหลักเกิน 1 ต่อจอ
- ข้อมูลผู้ใช้เก็บ **ในเครื่องเท่านั้น** (ADR-007)

---

## 3. แผนงานและความคืบหน้า

| Phase | งาน | สถานะ |
|---|---|---|
| 0 | สภาพแวดล้อม, git, ระบบทีม (`CLAUDE.md`, `.claude/agents` 9, `.claude/skills` 6), พอร์ต `recipix_core` + เทสต์ | เสร็จ |
| 1 | tokens, ฟอนต์ไทย, ไอคอน SVG, ภาพวัตถุดิบ, app shell 5 แท็บ + ทรานซิชัน | เสร็จ |
| 2 | ตู้เย็น (เกมจัดตู้) · หน้าหลัก (ใบรายงาน) · สุ่มเมนู · แดชบอร์ด | เสร็จ (เหลือ **แท็บสแกน** — รอ Android) |
| + | บันทึกค่ากิน, แผนกินถึงวันเงินเข้า (ADR-008), บันทึกข้อมูลในเครื่อง (ADR-009) | เสร็จ |
| 1.5 | **UI Refinement Sprint** (`docs/ui_refinement_sprint.md`) | เสร็จ เหลือรีวิว CP2 |
| 3 | แท็บสแกน (กล้อง/บาร์โค้ด/ML Kit), แจ้งเตือน, accessibility, empty/error states | รอ |
| Release | L3 — ต้องถามผู้ก่อตั้ง | รอ |

ฟีเจอร์ที่ผู้ก่อตั้ง **ให้รอ** (ยังไม่อนุมัติ): รายการซื้อของ, แจ้งเตือนตอนเช้า, ปิดวันตอนค่ำ

### 3.1 UI Refinement Sprint — ทำถึงไหน

| ขั้น | ผลลัพธ์ | สถานะ |
|---|---|---|
| A ตรวจสภาพ | 48 ภาพ `docs/design/shots/before/` (16 สถานะ × 360/390/430) จาก `test/design/shots_test.dart`; `docs/design/audit.md` | เสร็จ |
| B วิจารณ์ | 5 ความเห็นอิสระ `docs/design/critique/*.md` + `_synthesis.md` | เสร็จ |
| C Reference | 16 รายการ `docs/design/references.md` (Figma ของผู้ก่อตั้งเข้าไม่ได้ → คำถาม L3) | เสร็จ |
| D ทิศทาง | `docs/design/direction_v2.md` (3 ทิศทาง + คะแนน + ตรวจ slop); เลือก **A "สมุดค่ากินในครัว"** สำรอง **B "ป้ายตลาด"** → `docs/decisions/ADR-012_ui_direction_v2.md` | เสร็จ |
| E ลงมือ | ดูข้อ 4; ทุกการเปลี่ยนจดใน `docs/design/changelog_ui.md` (อ้างประเด็น + R#) | เสร็จ |
| F ตรวจ/ส่ง | ภาพ after 48 ภาพ, `docs/qa/five_second_test.md` (8/16 → 11/16), เช็กลิสต์ใน `docs/ui_critique.md`, เอกสาร, commit | เสร็จ เหลือ CP2 |

**ผลวินิจฉัย "ขาดอะไร" (synthesis):** 1) ตัวเลขไม่มีภาษาเดียว/ขัดกันข้ามหน้า (781 vs 620) 2) โครงเป็นการ์ดเทมเพลต (กล่องขาว+ตัวเลขใหญ่+ปุ่ม ซ้ำทุกหน้า) 3) สีแดงใช้จนไร้ความหมาย อ่านเหมือนโดนดุ 4) สถานะว่างพูดไม่จริง ("จัดของเข้าตู้ครบแล้ว" ตอนตู้ว่าง, เมนู "เข้ากัน 0%") 5) วัตถุไม่มีมิติ/บุคลิก

**กติกา ADR-012:** บรรทัดแทนกล่อง (กล่องเฉพาะวัตถุจริง) · หนึ่งจอหนึ่งตัวเลขใหญ่ · signature = **dot leader** ระหว่างป้ายกับค่า (เฉพาะบรรทัดอ่านค่า) · ไวยากรณ์ตัวเลขเดียว (`Amount`) · สีความสดกลาง (แดง = หมดอายุ/วันนี้, เหลือง = 1–5 วัน) · ตัวอักษร 44/24/18/16/13 (+10)

---

## 4. งานขั้น E ที่ค้าง (ยังไม่ commit)

### 4.1 ทำแล้วในโค้ด
- **tokens** (`lib/app/theme/recipix_tokens.dart`): สเกลใหม่ `display` 44, `pageTitle` 24 (ใหม่), `title` 18, `body` 16, `label` 13/600, `caption` 13/400, `micro` 10; `number` = body 600 tabular; `unitScale` 0.55; `leaderDot`, `leaderGap`
- **คอมโพเนนต์ใหม่** `lib/shared/widgets/ledger.dart`: `Amount` (ตัวเลข+หน่วยเล็ก), `LedgerRow` (ป้าย…dot leader…ค่า), `DotLeader`
- `lib/shared/utils/freshness_color.dart`: `freshnessColor(t, daysLeft)` สีความสดกลาง
- `IngredientTile(framed:)` — ปิดกระเบื้องเบจได้ (ของยืนบนชั้น / ในหน้าต่างวงล้อ)
- **ตู้เย็น:** ของในมือลอย (scale 1.05 + เงาแข็งไม่เบลอ), โซนมีวัสดุด้วยเส้น (`_Compartment`: ขอบหน้าชั้นหนา, ช่องแช่แข็งกรอบคู่), บอกเหตุผลเมื่อวางไม่ได้ในบรรทัดตะกร้า (`_basketLine`), ข้อความตู้ว่างที่จริง, ของบนชั้นไม่มีกระเบื้อง
- **หน้าหลัก:** เลิกกล่องรายงาน → ตัวเลขใหญ่ + แถบ + `LedgerRow` (งบวันนี้ / เงินเข้าอีก / พลังงานในตู้ / ยอดขาดถ้าซื้อกิน / ยอดขาดถ้าทำเองตามแผน); หัวข้อส่วนย้ายคำแนะนำไปบรรทัดล่าง; แถว "ต้องใช้ก่อน" มี dot leader + สีกลาง; มื้อถัดไป/เมนูเป็นบรรทัดไม่ใช่การ์ด; ตู้ว่างแสดงข้อความแทน "0.0 วัน"; **แก้บั๊ก** `menuSuggestionProvider` ไม่เสนอเมนูที่ไม่มีของเลย
- **สุ่มเมนู:** วงล้อ 3 แกนเป็นหน้าต่างเดียวมีเส้นแบ่ง (เลิกการ์ดซ้อน), แกนที่ล็อกมีเส้นเขียวล่าง; พัก 350ms ก่อนเปิดผล; sheet สูงไม่เกิน 58% (เห็นวงล้อ); ตู้ว่าง → ปุ่มหมุนปิด + ลิงก์ไปโหมดสั่งข้างนอก; ผลแยกกลุ่ม "ทำได้ครบเลย" กับ "เมนูอื่น"; ป้าย "มีของ x จาก y · z%"; สั่งข้างนอกเป็นบรรทัดแบบใบสั่ง (ไม่ใช่การ์ดโปรโมชัน)
- **แดชบอร์ด:** ตัวใหญ่ = "เหลือรอบนี้" (เดิมเป็นงบรวม); ตั้งค่า 3 อย่างเป็นบรรทัดมี stepper; ไม่ซ้ำยอดขาด (อยู่หน้าหลักที่เดียว); แท่งเกินงบเป็นเหลือง; ตาราง "เงินที่เหลือซื้อได้" เป็น `LedgerRow`; เหรียญเป็น **ตราประทับ** (เส้นประ = ยังไม่ได้ + "x/y", เส้นเต็มเขียว = ได้แล้ว + วันที่) ไม่มีการ์ด
- **ไอคอนใหม่** (`tool/gen_icons.sh`): `home` = ช้อนส้อม, `dashboard` = สมุดบัญชี, `wallet`, `tag`, `bowl` (ลบ `coin`); เหรียญใช้ tag/wallet/pan/bowl/barcode
- แผนกิน: สรุปเลิกกล่อง → ตัวเลข + `LedgerRow`; สแกน: ข้อความตรงๆ ไม่มีกล่อง; หัวหน้าทุกแท็บใช้ `t.pageTitle`

### 4.2 หลัง 5-second test
- แก้: หน้าหลักขึ้นยอดขาดตามแผนก่อน ยอดขาดถ้าซื้อกินทุกมื้อเป็นสี ink2 (ตู้ว่างแสดงแถวเดียว); ลิ้นชักผักตอนปิดจาก 42% เหลือ 30% ของแถว; ชื่อเหรียญ `clear_expiring` = "เคลียร์ของใกล้หมด" (เดิมตัดคำ "หมดอายุ")
- ยังไม่ผ่าน: เพิ่มของเข้าตู้เองไม่ได้ (ฟีเจอร์ใหม่ = L3); sheet ผลสุ่มที่ของไม่ครบไม่มีการกระทำถัดไป; ชิปตัวกรองไม่มีสัญญาณว่าเลื่อนได้; ตู้ > ช่องแช่แข็ง > ไทล์ ดูเป็นกล่องซ้อน 3 ชั้น

---

## 5. โครงสร้างและโค้ด/ตรรกะสำคัญ

### 5.1 โครงสร้าง
```
packages/recipix_core/      Dart ล้วน (ห้าม import Flutter) — กติกาธุรกิจทั้งหมด + test/ (65)
lib/app/                    router (go_router StatefulShellRoute), theme/tokens, strings (S), providers
lib/features/<tab>/         data / domain (Riverpod Notifier) / presentation
  fridge/ home/ random/ dashboard/ scan/ budget/
lib/shared/                 widgets (Pressable, IngredientTile, ledger, toast, value_stepper…),
                            icons, motion (entrance, reduce motion), utils (format, freshness_color),
                            persistence (app_store, codecs), data (recipe_book)
assets/                     fonts (IBM Plex Sans Thai), icons (24 SVG), ingredients (18 SVG),
                            data (ingredients.json, recipes.json, eat_out.json)
tool/gen_icons.sh, gen_ingredients.sh   แหล่งของ SVG (แก้ที่นี่แล้วรัน ไม่แก้ไฟล์ SVG ตรงๆ)
test/                       widget, golden, governance, persistence, features/*, design/shots
docs/                       ทุกอย่างเรื่องเอกสาร; ADR ใน docs/decisions/ (001–012)
```

### 5.2 กติกาธุรกิจหลัก (`recipix_core`)
- **SurvivalEngine** (ADR-002): แคลอรี่ของที่ยังไม่หมดอายุและรู้ชนิด ÷ 2000 = วันที่อยู่ได้; ของปริศนา (`key == null`) แยกเป็นประมาณการ; urgent = เหลือ 0–2 วัน; `nextPayday` (ไม่ตั้ง = 1 ของเดือนหน้า; ตั้งวันที่ N = clamp วันสุดท้ายของเดือน); `BudgetDeficit` = max(0, วันที่ไม่พอ × ราคามื้อ × มื้อ/วัน − งบเหลือ)
- **BudgetLedger** (ADR-008): งบรอบ − รายจ่ายในรอบ = เหลือ; **งบวันนี้คงที่ตั้งแต่เช้า** (เหลือตอนเริ่มวัน ÷ วันถึงเงินเข้า); นับมื้อกินข้างนอกวันนี้
- **MealPlanner** (ADR-008): greedy ทีละมื้อถึงวันเงินเข้า ใช้ของในตู้ก่อน (จำลองตัดตามปริมาณ+วันหมดอายุจริง) คะแนน Σ 1/(วันเหลือ+1) ห้ามซ้ำเมนูติดกัน; ทำไม่ได้ = ซื้อกิน; ยอดขาดตามแผน; รายการของที่จะเสีย (เฉพาะของที่มีสูตรใช้)
- **IngredientSlotMachine + SlotRollStrategy** (`ExpiringFirst` น้ำหนัก 1/(d+1)², `PureRandom`); ผลตัดสินก่อนแอนิเมชัน; อันดับของสล็อตถ่วงจำนวนแกนที่ใช้ (`RecipeMatcher.rank(weighFocus: true)`, ADR-011)
- **InventoryService.cook**: ตัดตามปริมาณ FEFO, หน่วยต้องเข้ากัน, คืน shortfall
- **AchievementManager + BadgeRule** (Counting/Streak), `Stream<BadgeUnlocked>`; `DayClosed.discardedCount` เป็น null ได้ (วันที่ยังไม่ติดตาม)
- ชนิดค่า: `Money` (สตางค์ int), `LocalDate` (ไม่มีเวลา), `Quantity` (แปลงหน่วยในมิติเดียว)

### 5.3 ฝั่งแอป
- **State (Riverpod 3.4):** `fridgeProvider` (ของ, ตำแหน่ง, ประวัติใช้/ทิ้ง `activity`, ทำกิน `cooked`, `trackingSince`, undo), `budgetProvider` (งบรอบ, วันเงินเข้า, ราคา, รายจ่าย), `randomProvider`; derived: `ledgerProvider`, `budgetProfileProvider`, `survivalReportProvider`, `mealPlanProvider`, `useFirstProvider`, `menuSuggestionProvider`, `badgeProgressProvider` (เล่นประวัติซ้ำผ่าน core), `timelineProvider`
- **ตู้เย็น (ADR-005):** กริด 25 ช่องใน `fridge_layout.dart` (Dart ล้วน), ลากเขียนเอง (`fridge_board.dart`) บน Stack เดียว (`FridgeGeometry`), spring snap/bounce, **item ต้นทางต้องอยู่ใน tree ระหว่างลาก** และใช้ `DragStartBehavior.down` (บั๊กที่เคยเจอ)
- **Persistence (ADR-009):** `shared_preferences` + JSON 2 ก้อน `recipix.fridge.v1` / `recipix.budget.v1` โหลดก่อนเฟรมแรกใน `main()`, บันทึกผ่าน `listenSelf` แบบรวมต่อ microtask; ข้อมูลเสีย → สำรอง `<key>.corrupt.<ts>` ก่อนเริ่มใหม่
- **ข้อมูลตัวอย่าง** เติมตอนเปิดครั้งแรก (ยังเพิ่มของเองไม่ได้จนกว่าจะมีสแกน)
- **Toast เลิกทำ** `showUndoToast` ต้อง `persist: false` (Flutter 3.47 ค้างไว้ถ้ามี action)
- **governance test** บังคับ: ไม่มี emoji, สีเฉพาะใน theme, ไม่มีรัศมีตัวเลขตรงๆ, ไม่มี gradient/blur/repeat, ไอคอนตามสเปก, core ไม่ import Flutter

### 5.4 คำสั่ง
```
flutter analyze                      # ใช้ PowerShell (path Flutter มีช่องว่าง: D:\Ok bro\flutter)
flutter test                         # แอป
cd packages/recipix_core; dart test  # core
flutter test --update-goldens test/golden
flutter test --update-goldens --dart-define=SHOTS=after test/design   # ภาพรีวิวดีไซน์
```
รันดูเอง: VS Code → Run and Debug → **Recipix (Chrome)** (`.vscode/launch.json`); preview ของ Claude: `.claude/launch.json` "recipix-web" (port 8765, release)

---

## 6. คำถาม L3 ที่ค้างถึงผู้ก่อตั้ง
1. **Figma reference:** connector ไม่มีสิทธิ์อ่านไฟล์ — ขอลิงก์เฟรม moodboard หรือให้สิทธิ์อ่าน
2. ตัวเลขหลักหน้าแรกเป็น "มื้อ" แทน "วัน" (สเปก 5.3) — **ใช้แล้ว รอยืนยัน** ย้อนได้ใน `strings.dart`/`home_page.dart`
3. ชื่อแท็บ "แดชบอร์ด" → "สมุดค่ากิน" — **ใช้แล้ว รอยืนยัน** ย้อนได้ใน `strings.dart`
4. ไฟล์ต้นฉบับเดิม (Unity / เดโม HTML / `ui_design_prompt.md`) — ผู้ก่อตั้งบอกว่าจะวางให้
5. ติดตั้ง Android Studio (ขั้นตอนใน `docs/engineering/tooling_setup.md`) เพื่อทำแท็บสแกน
6. ฟีเจอร์ที่ให้รอ: รายการซื้อของ, แจ้งเตือนเช้า, ปิดวันตอนค่ำ; เปิดครั้งแรกเริ่มจากตู้ว่างไหม
7. เพิ่มของเข้าตู้เองด้วยมือ (ฟีเจอร์ใหม่ — ผู้ใช้ใหม่ติดตันใน 5-second test)

กติกาถาวรจากผู้ก่อตั้ง: ถ้า token ใกล้หมด ให้ส่ง build Android/iOS ผ่าน GitHub Actions หรือ QR

## 7. งานต่อที่บันทึกไว้ (นอก sprint)
แผนกินวนเมนูเดิมทุกวัน (planner) · เครื่องปรุงถูกนับแคลอรี่ / ขาดวัตถุดิบบ้านไทย (ข้าวสาร มาม่า ลูกชิ้น ซอสหอยนางรม) / กระเทียมถูกนับเป็น "ของที่ขาด" · ภาพจานอาหาร flat สำหรับมื้อถัดไป/ผลสุ่ม · ค่าแคลอรี่/อายุ/สูตรเป็นประมาณการ รอวุฒิตรวจแหล่งอ้างอิง · ทดสอบบนมือถือจริง (แฮปติก, ลากด้วยนิ้ว, 60 FPS)
