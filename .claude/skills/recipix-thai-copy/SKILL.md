---
name: recipix-thai-copy
description: Use when writing any Thai user-facing text in Recipix — labels, buttons, toasts, empty states, badge names, notifications. Sets the voice (short, direct, calm) and banned words.
---

# Thai copy voice

Voice: a calm friend who is good with money and food. Short, direct, plain. Say the number, then what to do.

## Do
- Lead with the fact: "อยู่ได้อีก 2.1 วัน", "งบวันนี้ 85 บาท", "ขาดอีก 300 บาทถึงวันเงินเข้า"
- Verbs on buttons: "เพิ่มเข้าตู้เย็น (3)", "หมุน", "ใช้แล้ว", "ทิ้ง", "เลิกทำ"
- Estimates say so: "ประมาณ", "ยังไม่รู้ชนิด"
- Full match: "ครบทุกอย่าง" (no fanfare)
- Neutral register; skip ครับ/ค่ะ in UI labels

## Don't
- No emoji; no "!" except rare true warnings
- No marketing/English hype: Jackpot, Pulse, Aurora, Chef's Pick, "สุดปัง", "เริ่ดมาก", "ห้ามพลาด"
- No guilt or alarm: avoid "อันตราย", "แย่แล้ว"; use "ใกล้หมดอายุ", "ควรใช้วันนี้"
- No uppercase English labels

## Badge names (original concepts, no emoji)
`clear_expiring` เคลียร์ของใกล้หมดอายุ · `budget_saver` ประหยัดงบสำเร็จ · `home_cook` ทำกินเองบ่อย · `zero_waste_week` ไม่ทิ้งของ 7 วัน · `first_scan` สแกนครั้งแรก
Replace with the original demo names if that file becomes available.

All strings live in one strings file in the app, not inline in widgets.
