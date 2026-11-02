# CODEX PHASE 01: 01-shell-theme

## Execution scope (from proposed roadmap, not yet implemented)

Flutter shell, navigation và design system

**Mục tiêu:** app Android khởi chạy, đủ route để tiếp tục implement mà không tạo kiến trúc rối. **Công việc:** Flutter stable, go_router, Riverpod, MVVM, 4 tabs, 15 route có placeholder minh bạch, design tokens/ThemeData, components chung Button/Input/Card/AppBar/Nav/Dialog/Loading/Empty/Error, responsive 360/412. Tạo `docs/architecture.md` có diagram, sequence, services-ViewModels table. **DoD:** app launch, navigate/back, 4 tab đúng, component demo state có test; không có Firebase SDK trong widget, không fake thành màn hình đã hoàn thành. Chủ yếu hoàn thiện Light; giữ khung 7 theme.

## Run this task

Implement ONLY phase 01 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 7 Lab 2/Lab 3 references in `docs/requirements/reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 01 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 01; do not start next phase unless requested.
