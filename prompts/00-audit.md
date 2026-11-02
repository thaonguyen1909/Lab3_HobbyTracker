# CODEX PHASE 00: 00-audit

## Execution scope (from proposed roadmap, not yet implemented)

Chốt đầu vào và truy vết yêu cầu (CHỈ TÀI LIỆU)

**Mục tiêu:** tránh viết code sai vì thiếu spec. **Công việc:** đọc 7 nguồn Lab 2/Lab 3, xác lập danh sách 15 màn hình/3 flow/7 theme/4 tab; lập ma trận `Lab2 -> Flutter route -> widget -> viewmodel -> data source -> test case`; lập checklist rubric Lab 3; liệt kê gaps Figma/Handoff, Cloud Storage/billing, auth. **Deliverables:** `docs/gap-review.md`, `docs/design-traceability.md`, `docs/open-decisions.md`, `docs/rubric-checklist.md`, draft `design/DESIGN.md`, draft `handoff/flutter-handoff.md`. **DoD:** không có màn hình hoặc recovery path bị bỏ sót; mỗi yêu cầu có nguồn; các quyết định chưa được phê duyệt có `OPEN/BLOCKED`, không coi là đã hoàn thành.

**Prompt Codex:** `prompts/00-audit.md`.

## Run this task

Implement ONLY phase 00 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 7 Lab 2/Lab 3 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 00 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 00; do not start next phase unless requested.
