# Phase 00 — bộ tài liệu để nhóm review

STATUS: PARTIAL. Tài liệu đã được biên soạn để review, chưa đánh dấu phase00 được nhóm/giảng viên nghiệm thu. Phase01 NOT STARTED.

## Đọc nhanh

1. [Đối chiếu Figma và HTML](figma-html-comparison.md): cấu trúc tương ứng, khác biệt và giới hạn kiểm tra.
2. [Traceability](design-traceability.md): 15 đích điều hướng, 6 Settings categories, 3 flow, dialogs và 10 component families.
3. [Design](design/DESIGN.md) và [Flutter handoff](design/handoff/flutter-handoff.md): thiết kế triển khai đề xuất, chưa có code.
4. [Gap review](gap-review.md), [quyết định](open-decisions.md), [rubric](rubric-checklist.md), [test plan](test-plan.md).

## Quyết định đã xác nhận và mục còn cần review

- **D06 APPROVED (02/11/2026):** người dùng xác nhận giao diện theo Figma, hành vi theo Specification/HTML; ghi và review mọi khác biệt.
- **D03 APPROVED (02/11/2026):** người dùng xác nhận Google + email/password thật, giữ Register/Forgot hoạt động thật; không có demo bypass trong bản nộp. Xử lý cùng email/hai provider cần thiết kế và test phase02.
- **D07/D08:** không mặc định priority từ ảnh Interested selected; chấp nhận state templates/loading/error/retry trong handoff và cập nhật design sau review.
- **D09:** bổ sung demo Firebase trong Settings/Profile, không thêm tab.
- **D01:** xác nhận Figma/HTML được dùng làm đầu vào chính thức. 6 trang Figma hiện không có reactions hoặc flow starting points; cần nối prototype/recovery hoặc quyết định giảng viên, chưa thể coi là prototype tương tác hoàn chỉnh.

Không cần chốt billing ngay để review tài liệu/shell. D02 phải có phương án trước upload phase07A; StudentID/tên repo và quyền mở link nộp trước phase08. Privacy matrix/lifecycle policy được giao mốc cụ thể trong open-decisions.

## Bằng chứng của audit

- `docs/requirements/reference/source-manifest.json`: 7 hash/kích thước **kỳ vọng** từ đợt cũ, không sửa để che mismatch; `docs/requirements/reference/archive-manifest.json`: hash tệp thực có; `docs/evidence/00/source-integrity.json`: 4 PASS/3 FAIL. Bản validation tự khai cũ lưu `docs/evidence/00/document-validation-original-2026-11-02.json`, không dùng làm kết quả hiện tại.
- docs/evidence/00/figma-structure.json: đọc trực tiếp 6 trang, reaction/flow-start counts.
- docs/evidence/00/figma-node-inventory.json: IDs/names/type đọc từ metadata, không phải code-generated mock.
- `docs/evidence/00/document-validation.json`: kết quả mới có thể chạy lại bằng `scripts/verify_phase00.py`; bao gồm hash FAIL, coverage, links. `docs/source-provenance.md` ghi thao tác khôi phục/cần người xác minh.
- 4 render Figma đã xem qua tool: Login 7:8, Home 9:44, Creator 9:356, Appearance 9:1697. Không có file PNG evidence được lưu; không claim đã kiểm tra thị giác mọi màn/theme.

## Kiểm tra đã thực hiện

- git status --short: kiểm tra trước và sau; trước thay đổi working tree sạch.
- Audit lịch sử 02/11 có ghi Python/pypdf/XML/HTML và sao chép 7 tệp. **Kiểm chứng mới 03/11 chỉ xác nhận giữ nguyên 7 tệp so với ZIP đầu vào**; không có quyền truy cập 7 đường dẫn gốc Windows nên không xác nhận “exact original copies”. Không render lại toàn bộ PDF/PPTX trong lần này.
- Figma MCP read-only: metadata + reactions/flowStartingPoints của 6 trang; render mẫu 4 node; không sửa canvas.
- Validation cũ được lưu để truy vết; script mới kiểm hash/bytes 7 nguồn, số màn/flow/component/test/rubric, link Markdown, ảnh hưởng Figma từ **evidence lịch sử**. Có thể tái chạy, không xem thống kê Figma cũ là kiểm tra Figma hiện tại.
- git diff --check: kiểm tra whitespace tài liệu.
- flutter analyze, flutter test, Rules Emulator, ARTEMIS: NOT RUN — repo chưa có Flutter app/pubspec/config; không có Firebase Console evidence hoặc runtime kết quả để báo PASS.

## Thay đổi và phạm vi

Thêm 7 nguồn + manifest/index, 6 tài liệu docs mới, DESIGN/handoff, bằng chứng đọc Figma và validation; cập nhật README, roadmap, open-decisions. Tất cả route/widget/services/test IDs mới là PLANNED. Không thay bản gốc HTML/PDF/PPTX, không sửa Figma, không triển khai app/Final, không billing/deploy, chưa commit/push trong công việc này.

READY FOR HUMAN REVIEW: YES, **Phase00 PARTIAL**. Có thêm blocker G12 (3 HTML sai hash), D01 (Figma/prototype/approval), và review handoff. Lần thử truy cập Figma ngày 03/11/2026 bị từ chối quyền Editor; không xác thực lại metadata/prototype hiện thời. D03/D06 chỉ là quyết định người dùng được ghi trong tài liệu, không phải giảng viên phê duyệt. Xem `docs/phase-00-handoff-checklist.md` để nghiệm thu. Không tự khởi chạy phase01.
