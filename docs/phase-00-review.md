# Phase 00 — bộ tài liệu để nhóm review

STATUS: PARTIAL. Tài liệu đã được biên soạn để review, chưa đánh dấu phase00 được nhóm/giảng viên nghiệm thu. Phase01 NOT STARTED.

## Đọc nhanh

1. [Đối chiếu Figma và HTML](figma-html-comparison.md): cấu trúc tương ứng, khác biệt và giới hạn kiểm tra.
2. [Traceability](design-traceability.md): 15 đích điều hướng, 6 Settings categories, 3 flow, dialogs và 10 component families.
3. [Design](../design/DESIGN.md) và [Flutter handoff](../handoff/flutter-handoff.md): thiết kế triển khai đề xuất, chưa có code.
4. [Gap review](gap-review.md), [quyết định](open-decisions.md), [rubric](rubric-checklist.md), [test plan](test-plan.md).

## Quyết định đã xác nhận và mục còn cần review

- **D06 APPROVED (02/11/2026):** người dùng xác nhận giao diện theo Figma, hành vi theo Specification/HTML; ghi và review mọi khác biệt.
- **D03 APPROVED (02/11/2026):** người dùng xác nhận Google + email/password thật, giữ Register/Forgot hoạt động thật; không có demo bypass trong bản nộp. Xử lý cùng email/hai provider cần thiết kế và test phase02.
- **D07/D08:** không mặc định priority từ ảnh Interested selected; chấp nhận state templates/loading/error/retry trong handoff và cập nhật design sau review.
- **D09:** bổ sung demo Firebase trong Settings/Profile, không thêm tab.
- **D01:** xác nhận Figma/HTML được dùng làm đầu vào chính thức. 6 trang Figma hiện không có reactions hoặc flow starting points; cần nối prototype/recovery hoặc quyết định giảng viên, chưa thể coi là prototype tương tác hoàn chỉnh.

Không cần chốt billing ngay để review tài liệu/shell. D02 phải có phương án trước upload phase07A; StudentID/tên repo và quyền mở link nộp trước phase08. Privacy matrix/lifecycle policy được giao mốc cụ thể trong open-decisions.

## Bằng chứng của audit

- reference/source-manifest.json: 7 file nguồn, đường dẫn gốc và SHA-256.
- evidence/00/figma-structure.json: đọc trực tiếp 6 trang, reaction/flow-start counts.
- evidence/00/figma-node-inventory.json: IDs/names/type đọc từ metadata, không phải code-generated mock.
- evidence/00/document-validation.json: kết quả script hash, coverage, local links và scope.
- 4 render Figma đã xem qua tool: Login 7:8, Home 9:44, Creator 9:356, Appearance 9:1697. Không có file PNG evidence được lưu; không claim đã kiểm tra thị giác mọi màn/theme.

## Kiểm tra đã thực hiện

- git status --short: kiểm tra trước và sau; trước thay đổi working tree sạch.
- Python + pypdf/XML/HTML reading: đọc văn bản nguồn, inventory slide và copy 7 file nguyên byte; không render toàn bộ PDF/PPTX trong lần này.
- Figma MCP read-only: metadata + reactions/flowStartingPoints của 6 trang; render mẫu 4 node; không sửa canvas.
- Python verification script: source hash/count, 15 màn/15 handoff entries, 23 test IDs, 20 rubric rows/tổng điểm10, Settings/component coverage, Figma zero-reaction evidence và local Markdown links.
- git diff --check: kiểm tra whitespace tài liệu.
- flutter analyze, flutter test, Rules Emulator, ARTEMIS: NOT RUN — repo chưa có Flutter app/pubspec/config; không có Firebase Console evidence hoặc runtime kết quả để báo PASS.

## Thay đổi và phạm vi

Thêm 7 nguồn + manifest/index, 6 tài liệu docs mới, DESIGN/handoff, bằng chứng đọc Figma và validation; cập nhật README, roadmap, open-decisions. Tất cả route/widget/services/test IDs mới là PLANNED. Không thay bản gốc HTML/PDF/PPTX, không sửa Figma, không triển khai app/Final, không billing/deploy, chưa commit/push trong công việc này.

READY FOR HUMAN REVIEW: YES. Review tài liệu không có nghĩa nghiệm thu app. D03/D06 đã ghi quyết định; các mục khác chưa tự chuyển thành APPROVED. Giữ phase00 PARTIAL vì formal prototype/approval và review chi tiết còn mở; không tự khởi chạy phase01.
