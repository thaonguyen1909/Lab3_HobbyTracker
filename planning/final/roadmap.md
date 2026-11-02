# Kế hoạch Final — chỉ tham khảo

Không thuộc target Lab 3. Chỉ thực hiện sau nghiệm thu Lab 3 và khi người dùng giao riêng. Cần đối chiếu PDF Final trước khi triển khai; tài liệu này không phải phê duyệt thiết kế hay hạ tầng.

### ĐỢT 09 — Final: shared core, roles, data model và rules

**Mục tiêu:** mở rộng Lab 3 sang hệ thống 2 client có quyền phân tách rõ. **Công việc:** lưu tag Lab 3 trước; restructure repo thành `mobile/`, `web/`, `packages/core/` theo PDF Final, preserve history; chung model/service/Theme tokens; `users/{uid}.role` (`user`, `staff`, `admin`), bootstrap Admin bằng Console do người phụ trách, không auto-escalate; Firestore `deny by default`/shape validation/status transitions; Firebase Emulator tests allowed & denied per role per collection; App Check cho Firestore/AI, `docs/data-model.md`. **DoD:** mobile regressions green; nonstaff blocked web, tự sửa role denied; Rules tests pass, `README` mô tả quyền và admin bootstrap; không có rules `allow read, write: if true`.

### ĐỢT 10 — Final: Flutter Web Admin (4 screens + form)

**Mục tiêu:** web vận hành thật trên cùng Firestore. **Công việc:** Sign-in Google reject nonstaff; Management list/search/create/edit/archive **Events**; Review queue pending registrations approve/reject + reason; Dashboard ≥3 figures from queries + 1 chart; Announcement form tạo `announcements`; desktop width layout cùng tokens/Theme; analytics/remote config (Final), deploy Firebase Hosting sau khi người phụ trách duyệt. **DoD:** 4 màn + form, loading/empty/error; role rejection; sự kiện/announcement xuất hiện mobile đúng phân quyền; URL hoạt động cửa sổ ẩn danh; screenshots evidence.

### ĐỢT 11 — Final: cross-role flow + inbox realtime

**Mục tiêu:** chứng minh mobile ↔ staff web liên thông. **Flow đề xuất:** mobile RSVP event theo `registrations.status=pending` → staff web approve/reject và ghi reason → Firestore cập nhật realtime → mobile thấy status và inbox notification; **chỉ Add to Home nếu người dùng chủ động bấm**. Đây là **đề xuất mở rộng trạng thái** so với Lab 2, phải cập nhật Figma/traceability và xin xác nhận giảng viên. `announcements` hiển thị trong mobile inbox; không giả rằng FCM tự gửi push cho mọi thay đổi (không dùng Cloud Functions). **DoD:** test end-to-end trên deployed system 3 lần, đo latency và evidence; `docs/cross-role-flow.md` gồm actor/screen/write/rule/visible result/timing/sequence diagram.

### ĐỢT 12 — Final: Gemini AI structured output (Level 2)

**Mục tiêu:** AI hữu ích ngay trong một flow Lab 2, không phá workflow gốc. **Ý tưởng đề xuất:** `Beginner Starter Plan` trong Create Hobby (Flow1): nhận hobby dạng phi cá nhân + thời lượng mong muốn, Gemini tạo JSON `{summary, starterSteps[], suggestedMinutes}` → parse thành Dart model → cho user sửa/chấp nhận trước khi lưu. Firebase AI Logic (Gemini Developer API; kiểm tra model và hạn mức free tier trước khi chọn), App Check, Remote Config `ai_enabled`, `ai_model`, `ai_prompt_template`, fallback manual khi lỗi quota/network, không gửi tên/email/hình ảnh con người; `ai_request`, `ai_result_accepted`, `ai_error`. **DoD:** 3 input-output thật + 1 failure case vào `docs/ai-feature.md`, AI off từ Remote Config và Create Hobby vẫn tạo được; không có API secret trong client/hardcode; AI output luôn gắn nhãn, có xác nhận trước khi ghi.

### ĐỢT 13 — Final: hardening, review và nộp bài

**Mục tiêu:** đạt rubric Final, kiểm tra toàn hệ thống thay vì thêm tính năng. **Công việc:** ARTEMIS 3 runs/case (3 Lab 2 flows + mobile cross-role + AI); Security Rules test toàn bộ collection/role; web checklist 4 màn + form + roles/empty/error; cross-role live 3 runs; AI code review phần code mới ≥3 findings/decisions; `docs/test-report.md`, `docs/gap-review.md` closed; report Final 10–15 trang, slides 12–15, video 8–12 phút (mobile/web/AI/off toggle/tests); links private-window; README versions/setup/roles/accounts/evidence. **DoD:** rubric coverage không có mục chưa chứng minh được; ghi đúng `PASS / FAIL / BLOCKED / NOT RUN`; code freeze sau QA; giữ lịch sử Git nhiều đợt; không bịa ảnh/traces.

