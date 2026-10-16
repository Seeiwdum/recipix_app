---
name: recipix-release-checklist
description: Pre-release checklist for Recipix (CP3). Release itself is L3 — always ask the founder before building for or uploading to a store.
disable-model-invocation: true
---

# Release checklist (L3 gate)

Stop and ask the founder (batched) before any of: store accounts, signing keys, paid services, privacy policy text, store upload.

1. All tabs pass the `docs/ui_critique.md` checklist; emoji grep clean.
2. `flutter analyze` clean; `dart test` + `flutter test` (incl. goldens) pass.
3. Real-device run on Android (and iOS if the founder provides a Mac).
4. Permissions: camera, notifications — Thai rationale strings, graceful denial.
5. Personal data: what is stored on device; nothing leaves the device without consent -> founder approves the privacy text (L3).
6. App name, icon, version bump, changelog.
7. Founder signs off -> then build release artifacts.
