# CODEX PHASE 03: 03-flow1-hobbies

## Execution scope (from proposed roadmap, not yet implemented)

Flow 1: My Hobbies + Firestore CRUD

**Mục tiêu:** hoàn thiện Minh journey end-to-end. **Công việc:** models/repos/services/ViewModels cho Hobby, My Hobbies, Create/Edit dialog, Hobby Detail; icon grid/color swatch/priority, validation required/duplicate, empty/retry, owner-scoped reads/writes; indexes/rules và tests. **DoD:** tạo hobby tự đặt tên và thấy ở collection sau tải lại/re-login; cả Interested/Active có đầy đủ quyền lịch/timer; edit không làm mất plan/history; trùng tên hiện lỗi không ghi đè bản cũ. **Không** dựng catalog.

## Run this task

Implement ONLY phase 03 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 7 Lab 2/Lab 3 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 03 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 03; do not start next phase unless requested.
