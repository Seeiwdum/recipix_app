---
title: ADR-002 BudgetDeficit definition and payday rules
owner: เมธ
last_updated: 2026-10-16
version: 1.0
status: accepted
---

# ADR-002: นิยาม BudgetDeficit และวันเงินเดือนออก

- **ระดับ:** L2 (ไม่มีต้นฉบับ C# ในรีโป จึงกำหนดสูตรเอง)
- **บริบท:** MASTER_PROMPT 3.1 ให้ BudgetDeficit = "ยอดเงินที่ขาดแคลน" แต่ไม่มีสูตร; เดโม HTML ใช้คะแนน "โอกาสรอด" ที่ไม่มีที่มา

## การตัดสินใจ
```
daysUntilPayday = วันนับจากวันนี้ถึงวันก่อนเงินเข้า (อย่างน้อย 1)
survivalDays    = แคลอรี่ที่ยืนยันแล้ว (ไม่นับของปริศนา, ไม่นับของหมดอายุ) / 2000
uncoveredDays   = max(0, daysUntilPayday - survivalDays)
costToCover     = uncoveredDays × mealOutPrice × mealsPerDay      (ค่าตั้งต้น 60 บาท × 3 มื้อ แก้ได้)
BudgetDeficit   = max(0, costToCover - foodBudget)
dailyAllowance  = foodBudget ÷ daysUntilPayday (ปัดลงเป็นสตางค์)
```
- **วันเงินเข้า:** ถ้าไม่ตั้ง = 1 ของเดือนถัดไป (งบใช้ถึงสิ้นเดือน ตรงกับ "จำนวนวันที่เหลือถึงสิ้นเดือน"); ถ้าตั้งวันที่ N = วันที่ N ถัดจากวันนี้ (ถ้าเดือนนั้นสั้นกว่า N ใช้วันสุดท้ายของเดือน); วันเงินเข้าวันนี้ = ถือว่าเป็นรอบใหม่ นับไปถึงรอบหน้า
- **ของปริศนา:** ไม่ลด deficit เพราะยังไม่รู้ชนิด แสดงแยกเป็น "ประมาณการ" (`survivalDaysWithEstimate`)
- **ตัดทิ้ง:** คะแนน "โอกาสรอด" ของเดโม — ใช้ `isCovered` (deficit = 0) และตัวเลขข้างบนแทน

## ผลที่ตามมา
ตัวเลขทุกตัวในหน้าหลัก/แดชบอร์ดอธิบายได้และมีเทสต์ (`survival_engine_test.dart`)
ถ้าภายหลังได้ต้นฉบับ C# และสูตรต่างกัน ให้เทียบแล้วออก ADR ใหม่ (ไม่ลบอันนี้ เปลี่ยนเป็น superseded)
