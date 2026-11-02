# CODEX PHASE 07A: 07a-report-storage

## Execution scope (from proposed roadmap, not yet implemented)

File report và chiến lược Cloud Storage (BLOCKER PHẢI CHỐT)

**Mục tiêu:** PDF export thực và đường upload theo yêu cầu Lab 3 nếu hạ tầng được duyệt. **Công việc:** `ReportExportService` dựng PDF summary từ các dữ liệu hiện tại; `ReportUploadService` abstract; nếu đã được duyệt Blaze thì Firebase Storage upload `reports/{uid}/...` + progress + URL + storage.rules + denied tests + offline error. Nếu chưa có quyết định billing, chỉ implement local export và đánh dấu Cloud Storage requirement còn thiếu, không giả evidence. **DoD:** file tương ứng số liệu màn hình; local export/share hoạt động; upload chỉ tính DONE nếu cloud upload thật + console evidence + rules tests; Final có thể tắt upload mà giữ local export.

## Run this task

Implement ONLY phase 07A in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 8 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 07A have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 07A; do not start next phase unless requested.
