---
title: Ingredient Data Spec
owner: วุฒิ
last_updated: 2026-10-16
version: 1.0
status: draft
---

# สเปกข้อมูลวัตถุดิบ (`assets/data/ingredients.json`)

| ฟิลด์ | ชนิด | ความหมาย |
|---|---|---|
| key | string | คีย์มาตรฐาน snake_case อังกฤษ ใช้จับคู่สูตรและชื่อไฟล์ภาพ `assets/ingredients/<key>.svg` |
| name | string | ชื่อไทยที่ผู้ใช้เห็น |
| category | enum | `IngredientCategory` ใน recipix_core |
| unit | enum | piece / gram / milliliter (`QuantityUnit`) |
| defaultAmount | number | ปริมาณตอนซื้อมาตามปกติ |
| kcalPerUnit | number | kcal ต่อ 1 หน่วยของ unit |
| shelfLifeDays | int | อายุโดยประมาณในที่เก็บปกติ |
| zone | enum | shelf / crisper / freezer / door — ที่ที่ "จัดเข้าตู้ให้" จะเลือกก่อน |
| width | 1 or 2 | จำนวนช่องที่กินบนชั้นในเกมตู้เย็น |

สถานะ: ค่าทุกตัวเป็นค่าประมาณรอบแรก (18 รายการ) — **ต้องตรวจกับแหล่งอ้างอิงทางการก่อนปล่อย** (เช่น ตารางคุณค่าทางโภชนาการอาหารไทย/USDA FoodData Central) แล้วบันทึกแหล่งที่มาต่อรายการ
