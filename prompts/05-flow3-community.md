# CODEX PHASE 05: 05-flow3-community

## Execution scope (from proposed roadmap, not yet implemented)

Flow 3: Community dùng dữ liệu thật

**Mục tiêu:** hoàn thiện Connect & Participate trước khi mở thêm vai trò. **Công việc:** Feed/Post/Like/Comments; Groups + Join/Create + Chat; Activities/Events + RSVP + optional Add to Home; People + DM; Chats + Conversation; Firestore snapshots + participant rules; validation/empty/error. **DoD:** 2 tài khoản thực có thể nhìn nội dung chia sẻ phù hợp, trao đổi tin nhắn được phân quyền, data persist; người không thuộc chat không đọc messages; RSVP một mình không thêm schedule. Ghi nhận rõ nếu dùng dữ liệu seed **chỉ trong emulator**, không hard-code data vào production.

## Run this task

Implement ONLY phase 05 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 8 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 05 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 05; do not start next phase unless requested.
