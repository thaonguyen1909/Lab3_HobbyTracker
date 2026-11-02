> THAM KHẢO FINAL: không thực thi trong Lab 3; cần yêu cầu riêng của người dùng. Đọc planning/final/roadmap.md và PDF Final trước khi lập kế hoạch.

# CODEX PHASE 09: 09-final-core-rules

## Execution scope (from proposed roadmap, not yet implemented)

Final: shared core, roles, data model và rules

**Mục tiêu:** mở rộng Lab 3 sang hệ thống 2 client có quyền phân tách rõ. **Công việc:** lưu tag Lab 3 trước; restructure repo thành `mobile/`, `web/`, `packages/core/` theo PDF Final, preserve history; chung model/service/Theme tokens; `users/{uid}.role` (`user`, `staff`, `admin`), bootstrap Admin bằng Console do người phụ trách, không auto-escalate; Firestore `deny by default`/shape validation/status transitions; Firebase Emulator tests allowed & denied per role per collection; App Check cho Firestore/AI, `docs/data-model.md`. **DoD:** mobile regressions green; nonstaff blocked web, tự sửa role denied; Rules tests pass, `README` mô tả quyền và admin bootstrap; không có rules `allow read, write: if true`.

## Run this task

Implement ONLY phase 09 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 8 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 09 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 09; do not start next phase unless requested.
