> THAM KHẢO FINAL: không thực thi trong Lab 3; cần yêu cầu riêng của người dùng. Đọc planning/final/roadmap.md và PDF Final trước khi lập kế hoạch.

# CODEX PHASE 13: 13-final-qa

## Execution scope (from proposed roadmap, not yet implemented)

Final: hardening, review và nộp bài

**Mục tiêu:** đạt rubric Final, kiểm tra toàn hệ thống thay vì thêm tính năng. **Công việc:** ARTEMIS 3 runs/case (3 Lab 2 flows + mobile cross-role + AI); Security Rules test toàn bộ collection/role; web checklist 4 màn + form + roles/empty/error; cross-role live 3 runs; AI code review phần code mới ≥3 findings/decisions; `docs/test-report.md`, `docs/gap-review.md` closed; report Final 10–15 trang, slides 12–15, video 8–12 phút (mobile/web/AI/off toggle/tests); links private-window; README versions/setup/roles/accounts/evidence. **DoD:** rubric coverage không có mục chưa chứng minh được; ghi đúng `PASS / FAIL / BLOCKED / NOT RUN`; code freeze sau QA; giữ lịch sử Git nhiều đợt; không bịa ảnh/traces.

## Run this task

Implement ONLY phase 13 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 8 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 13 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 13; do not start next phase unless requested.
