# CODEX PHASE 12: 12-ai-feature

## Execution scope (from proposed roadmap, not yet implemented)

Final: Gemini AI structured output (Level 2)

**Mục tiêu:** AI hữu ích ngay trong một flow Lab 2, không phá workflow gốc. **Ý tưởng đề xuất:** `Beginner Starter Plan` trong Create Hobby (Flow1): nhận hobby dạng phi cá nhân + thời lượng mong muốn, Gemini tạo JSON `{summary, starterSteps[], suggestedMinutes}` → parse thành Dart model → cho user sửa/chấp nhận trước khi lưu. Firebase AI Logic (Gemini Developer API; kiểm tra model và hạn mức free tier trước khi chọn), App Check, Remote Config `ai_enabled`, `ai_model`, `ai_prompt_template`, fallback manual khi lỗi quota/network, không gửi tên/email/hình ảnh con người; `ai_request`, `ai_result_accepted`, `ai_error`. **DoD:** 3 input-output thật + 1 failure case vào `docs/ai-feature.md`, AI off từ Remote Config và Create Hobby vẫn tạo được; không có API secret trong client/hardcode; AI output luôn gắn nhãn, có xác nhận trước khi ghi.

## Run this task

Implement ONLY phase 12 in the existing Hobby Tracker repository. Read `AGENTS.md`, `docs/implementation-roadmap.md`, the relevant original 8 references in `reference/`, and existing docs before editing. Preserve all previous completed phases.

### First response before touching code

State: current repo state, dependencies already completed, precise changes proposed, observable acceptance tests, and blockers that need owner/instructor approval. Do not expand scope to another phase.

### Definition of done and evidence

- Requirements explicitly listed for phase 12 have traceable files/tests and visible behavior.
- Existing completed flows still work; no regressions introduced.
- Run available static analysis/tests; if an emulator/device/cloud account is unavailable, report `NOT RUN` instead of pretending success.
- Document differences from Lab 2 and unresolved conflicts in `docs/design-traceability.md` and `docs/open-decisions.md`.
- Give a succinct handoff: change list, actual checks with PASS/FAIL/BLOCKED, evidence locations, commit/PR reference if created.
- Stop after phase 12; do not start next phase unless requested.
