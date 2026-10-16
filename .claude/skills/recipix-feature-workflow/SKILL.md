---
name: recipix-feature-workflow
description: Use when starting a Recipix ticket or feature — the team's per-ticket flow, how to write Acceptance Criteria, which subagent does what, and the Definition of Done.
---

# Per-ticket workflow

1. **Intake** (พิม, main session): one-line goal, decision level (L1/L2/L3). L3 -> batch the question to the founder and keep working elsewhere.
2. **Context brief** (แพรว / `praew-docs`): relevant ADRs, files, rules — 5-10 lines.
3. **Rules** (ธนากร): which COMPANY_RULES apply.
4. **Plan + Acceptance Criteria** (lead: เมธ for code, วีน่า for UI/product, ฎา for QA). L2 -> write ADR.
5. **Build**: `rin-logic` (core/domain) or `thee-ui` (UI). Small, reversible commits on `dev`.
6. **Review**: `meth-reviewer`, or `/code-review`.
7. **QA**: `da-qa` — tests and, for UI, golden + checklist.
8. **Governance**: `thanakorn-governance` before a checkpoint.
9. **Docs**: แพรว updates docs; พิม summarises.
Small low-risk tasks may compress steps; **never skip review + tests**. Use subagents only when the work is separable or context-heavy.

## Acceptance Criteria template
```
Given <state>, when <action>, then <observable result>.
- Edge: <empty / expired / over budget / narrow screen>
- Non-goals: <what this ticket does not do>
```

## Definition of Done
- `flutter analyze` clean (PowerShell; SDK path has a space)
- `dart test` (core) and `flutter test` (app) pass — report counts
- reviewed
- UI: checklist logged in `docs/ui_critique.md`, ran in Chrome and looked at it
- docs/ADR updated; CHANGELOG line added
