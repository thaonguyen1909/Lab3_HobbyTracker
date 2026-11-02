# CODEX PHASE 08: 08-lab3-qa

## Execution scope (from proposed roadmap, not yet implemented)

ARTEMIS E2E, AI Code Review, khóa mốc Lab 3

**Mục tiêu:** nghiệm thu Lab 3 có evidence, không chỉ ảnh giao diện. **Công việc:** `docs/test-plan.md` ≥10 case; pytest/Google ARTEMIS (mỗi case ≥3 runs, assert kết quả nhìn thấy, test native Google picker/notification, 1 Pro exploratory 15–30 phút), traces/pass-rate/flaky report; AI code review PR ≥5 findings thuộc ≥2 loại, quyết định và ≥3 fixes ở commits riêng; report Lab 3 8–12 trang, slide 12–15, video 5–10 phút. **DoD:** test records là kết quả thực, code review có file:line/commit, README có versions, AI disclosure, links mở được; đánh tag mốc `lab3-submission` (chỉ sau kiểm tra). Không bịa kết quả/chạy test giả.

## Run this task

Implement ONLY phase 08 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 8 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 08 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 08; do not start next phase unless requested.
