# CODEX PHASE 04: 04-flow2-calendar-hyper

## Execution scope (from proposed roadmap, not yet implemented)

Flow 2: Home Calendar → Hyper Mode → History

**Mục tiêu:** hoàn thiện Khoa journey end-to-end. **Công việc:** Schedule + ActivityRecord Firestore; week/day list sort theo giờ; Add Schedule, CTA Hyper; accurate timer (Stopwatch/lifecycle), pause/resume/reset/finish, note snapshot; one record per finish (chống double-submit); mark linked schedule complete; History; preference pauseOnExit; links ngoài chỉ là shortcut. **DoD:** lưu và tải lại lịch, session duration/notes; pause không tăng elapsed; complete không tạo bản ghi đôi; không hobby có đường dẫn Create; RSVP không auto-add lịch (invariant chung).

## Run this task

Implement ONLY phase 04 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 7 Lab 2/Lab 3 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 04 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 04; do not start next phase unless requested.
