# CODEX PHASE 11: 11-cross-role-inbox

## Execution scope (from proposed roadmap, not yet implemented)

Final: cross-role flow + inbox realtime

**Mục tiêu:** chứng minh mobile ↔ staff web liên thông. **Flow đề xuất:** mobile RSVP event theo `registrations.status=pending` → staff web approve/reject và ghi reason → Firestore cập nhật realtime → mobile thấy status và inbox notification; **chỉ Add to Home nếu người dùng chủ động bấm**. Đây là **đề xuất mở rộng trạng thái** so với Lab 2, phải cập nhật Figma/traceability và xin xác nhận giảng viên. `announcements` hiển thị trong mobile inbox; không giả rằng FCM tự gửi push cho mọi thay đổi (không dùng Cloud Functions). **DoD:** test end-to-end trên deployed system 3 lần, đo latency và evidence; `docs/cross-role-flow.md` gồm actor/screen/write/rule/visible result/timing/sequence diagram.

## Run this task

Implement ONLY phase 11 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 8 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 11 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 11; do not start next phase unless requested.
