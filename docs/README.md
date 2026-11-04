# Tài liệu Hobby Tracker

**Lập lịch mới theo ảnh team:** [Thiết kế, hành vi và kiểm tra](quick-schedule-update.md) — ô sở thích, tự điền tên, thời lượng nhanh/tùy chỉnh và lặp có ngày kết thúc.

**Khoảnh khắc hiện hành:** [Node.js + Cloudinary, chạy USB](moments-cloudinary-run.md) · [Báo cáo chuyển kiến trúc](moments-cloudinary-report.md). Tài liệu này thay hướng Storage/Functions cũ cho phần Khoảnh khắc; chưa có nghiệm thu cloud.

Mã ứng dụng nằm ngoài thư mục này: `lib/`, `android/`, `assets/`, `firebase/`, `test/`, `e2e_test/` và `scripts/`. Các tài liệu/yêu cầu được gom ở đây để root repository gọn và dễ đọc trên GitHub.

| Nhóm | Vị trí | Nội dung |
|---|---|---|
| Yêu cầu gốc | [requirements/reference](requirements/reference/) | HTML, PPTX, PDF do người dùng cung cấp; giữ nguyên bytes |
| Quy tắc gốc | [AGENTS-original.md](requirements/AGENTS-original.md) | Bản lưu trước khi cập nhật đường dẫn; bản có hiệu lực nằm ở `../AGENTS.md` |
| Prompts triển khai | [requirements/prompts](requirements/prompts/) | Hướng dẫn phase 00–08 |
| Kế hoạch lưu trữ | [requirements/planning](requirements/planning/) | Final chỉ là tham khảo, không thuộc phạm vi Lab 3 |
| Thiết kế | [design](design/) | Tokens/spec và snapshots/context Figma |
| Handoff | [design/handoff](design/handoff/) | Hướng dẫn chuyển thiết kế sang Flutter |
| Evidence | [evidence](evidence/) | Logs, XML và bằng chứng thực đã tạo; giữ nguyên nội dung |
| Hồ sơ nộp | [submission](submission/) | Báo cáo PDF và outline slide hiện có |
| Lịch sử | [history](history/) | Changelog, README cũ, manifest và bản đồ di chuyển |

## Đọc trước

1. [Trạng thái tích hợp](full-implementation-report.md).
2. [Kiến trúc](architecture.md), [data model](data-model.md), [traceability](design-traceability.md).
3. [Quyết định còn mở](open-decisions.md) và [checklist nghiệm thu](full-manual-checklist.md).
4. [Báo cáo Anh/Việt](localization-report.md), [sửa điều hướng/thông báo](navigation-feedback-report.md), [sửa lỗi](bugfix-report.md).
5. [Kết quả sắp xếp repository](repository-layout-report.md).
6. [Kịch bản demo 3 flow](demo-three-flows.md): dữ liệu chuẩn bị, thao tác, kết quả cần thấy và lời thuyết trình.
7. [Đề xuất Khoảnh khắc 3 giờ](moments-implementation-proposal.md), [backend bước 1](moments-backend-step1-report.md), [giao diện bước 2](moments-ui-step2-report.md) và [cách chạy local](moments-local-run.md).
8. [Popup và thông báo bước 3](moments-alerts-step3-report.md): source outbox, inbox, popup và Android worker; kết quả test local và phần còn cần thử hai điện thoại được tách rõ trong báo cáo.
9. [Cleanup và QA bước 4](moments-cleanup-step4-report.md), [review findings](moments-step4-review.md), [demo/acceptance](moments-demo-acceptance.md): kết quả local mới nhất, công cụ cleanup demo và các ca thiết bị/cloud chưa chạy.
10. [Triển khai cloud đợt 5](moments-cloud-step5-report.md): đã chọn đúng tài khoản/dự án; preflight bị chặn vì billing chưa bật và bucket đích chưa tồn tại; chưa deploy hoặc đổi gói cước.

Manifest/evidence lịch sử có thể ghi đường dẫn cũ, ví dụ `reference/` hoặc `evidence/`. Đây là nội dung ghi nhận tại thời điểm thực thi, được giữ nguyên để truy vết; dùng [bản đồ di chuyển](history/reorganization-manifest.json) để tìm vị trí mới. Các kiểm tra phase cũ cũng không thay thế kết quả hiện tại.

Không upload hoặc chia sẻ secret/keystore/.env. Tài liệu này không khẳng định toàn bộ Lab 3 đã được nghiệm thu.
