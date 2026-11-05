> THAM KHẢO FINAL: không thực thi trong Lab 3; cần yêu cầu riêng của người dùng. Đọc planning/final/roadmap.md và PDF Final trước khi lập kế hoạch.

# CODEX PHASE 10: 10-final-web-admin

## Execution scope (from proposed roadmap, not yet implemented)

Final: Flutter Web Admin (4 screens + form)

**Mục tiêu:** web vận hành thật trên cùng Firestore. **Công việc:** Sign-in Google reject nonstaff; Management list/search/create/edit/archive **Events**; Review queue pending registrations approve/reject + reason; Dashboard ≥3 figures from queries + 1 chart; Announcement form tạo `announcements`; desktop width layout cùng tokens/Theme; analytics/remote config (Final), deploy Firebase Hosting sau khi người phụ trách duyệt. **DoD:** 4 màn + form, loading/empty/error; role rejection; sự kiện/announcement xuất hiện mobile đúng phân quyền; URL hoạt động cửa sổ ẩn danh; screenshots evidence.

## Run this task

Implement ONLY phase 10 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 8 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 10 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 10; do not start next phase unless requested.
