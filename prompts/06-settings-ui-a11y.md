# CODEX PHASE 06: 06-settings-ui-a11y

## Execution scope (from proposed roadmap, not yet implemented)

Settings, 7 themes và UI/A11y parity

**Mục tiêu:** đóng toàn bộ màn hình và chất lượng giao diện Lab 2. **Công việc:** Settings/Settings Detail: profile, external-tool shortcuts, notifications, Hyper prefs, appearance, privacy, signout confirmation; 7 theme với riêng style hợp lý, persistence; screen/device states; Semantics labels; screenshot comparison với DesignArchive; audit 15 màn tại 360/412. **DoD:** mọi route 15/15 có chức năng chủ yếu và trạng thái rõ; không overflow, 48dp targets, text >=14sp ở nội dung chính; theme switch không làm mất data; external links không giả là Spotify/YouTube integration.

## Run this task

Implement ONLY phase 06 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 7 Lab 2/Lab 3 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 06 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 06; do not start next phase unless requested.
