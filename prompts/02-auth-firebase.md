# CODEX PHASE 02: 02-auth-firebase

## Execution scope (from proposed roadmap, not yet implemented)

Firebase foundation, Auth và route guards

**Mục tiêu:** người dùng thực đăng nhập và dữ liệu tách theo UID. **Công việc:** Firebase project/FlutterFire CLI setup dưới hướng dẫn người phụ trách; Google Sign-In (required), auth-state routing, sign-out, cancel/no-network/retry; Google và email/password thật đã được người dùng duyệt tại D03: Login hỗ trợ cả hai, Register tạo tài khoản thật, Forgot gửi reset thật; xử lý cùng email/hai provider bằng quy trình conflict/linking có xác thực, không tự gộp hoặc nhân đôi hồ sơ; ghi design traceability; `users/{uid}` profile và Firestore Rules tối thiểu, DI auth service, separate demo account. **DoD:** signed-out không truy cập app; login thành công tới Home; signout xác nhận ở Settings; cancel không crash; không lưu password trong Firestore. **Lưu ý:** giảng viên có thể yêu cầu demo profile, nhưng profile nằm trong Settings theo Lab2.

## Run this task

Implement ONLY phase 02 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 7 Lab 2/Lab 3 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 02 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 02; do not start next phase unless requested.
