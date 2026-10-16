---
name: recipix-handover
description: End-of-session or checkpoint wrap-up for Recipix — update handover notes, docs index and changelog, then commit.
disable-model-invocation: true
---

# Handover

1. Run checks and note the results: `flutter analyze` (PowerShell), `dart test` in `packages/recipix_core`, `flutter test`.
2. Rewrite `docs/handover_notes.md` (keep front-matter, bump `last_updated`):
   สถานะล่าสุด (1-3 lines) · ทำแล้ว · ค้างอยู่/ปัญหา · ขั้นต่อไป (ordered) · คำถาม L3 ที่รอคำตอบ · ไฟล์ที่แก้ล่าสุด
3. `docs/INDEX.md`: add any new doc with a one-line purpose; mark deprecated ones.
4. `docs/CHANGELOG.md`: add dated entries under the current version.
5. Commit on `dev` with a conventional message. Merge to `main` only at a passed checkpoint.
