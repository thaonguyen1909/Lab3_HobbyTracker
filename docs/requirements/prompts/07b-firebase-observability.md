# CODEX PHASE 07B: 07b-firebase-observability

## Execution scope (from proposed roadmap, not yet implemented)

FCM, Analytics, Crashlytics, Remote Config

**Mục tiêu:** hoàn tất các dịch vụ Lab 3 còn lại, có bằng chứng. **Công việc:** FCM permission Android 13+, foreground/background/terminated, local inbox & deep link; ≥7 analytics events map Flow1-3 và export (không PII), DebugView; Crashlytics nonfatal error + gated test crash (ID/key); Remote Config 2 giá trị thay đổi hành vi thực có defaults, offline fallback; Firebase demo area trong Settings/Profile; `docs/analytics-plan.md`. **DoD:** mỗi dịch vụ có thành công + failure path và screenshots/console proof; events seen in DebugView; configs thay đổi không rebuild; crash test không bao giờ vô tình chạy trên màn thường.

## Run this task

Implement ONLY phase 07B in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 7 Lab 2/Lab 3 references in `docs/requirements/reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 07B have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 07B; do not start next phase unless requested.
