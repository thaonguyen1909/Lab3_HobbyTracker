# Gap review — phase 00

Ngày: 02/11/2026. Phạm vi: nguồn Lab2 → Android Lab3, tài liệu và đối chiếu Figma; không implement app. STATUS: PARTIAL — bộ draft sẵn sàng review, D03/D06 đã được người dùng duyệt; các review còn mở và prototype Figma chưa nối tương tác.

## Đã xác minh

- 7 file nguồn đã có trong reference/ và khớp SHA-256 nguồn gốc. Hai slide deck có 12 và 70 slide; nghiên cứu mô phỏng được ghi rõ.
- 6 trang Figma và 23 screen components + 7 theme previews; node IDs được lưu evidence/00.
- 0 reaction nodes và flowStartingPoints rỗng trên cả 6 trang tại thời điểm đọc. Chưa chạy Figma prototype play-through; không thể ghi 3 flow Figma PASS.
- Specification mô tả 15 destinations, 4 tab, 3 flows và 7 theme. HTML có handler cho các hành vi; screenshot Figma đã xem chọn mẫu 4 màn, không claim pixel parity 15/15.
- Tài liệu traceability, rubric, design, handoff và test plan hiện là kế hoạch, không code hoặc evidence app.

## Khoảng trống / hành động

| Gap | Tác động | Bước xử lý | Gate |
|---|---|---|---|
| G01 Figma tĩnh, baseline/chấp nhận formal chưa xác nhận | Không đủ chứng minh prototype và prerequisite Lab2 được duyệt | D06 đã được người dùng duyệt; còn D01: nối flow/error hoặc xác nhận giảng viên về HTML; không sửa canvas trong task này | Trước nghiệm thu parity; phase00 review |
| G02 Auth demo khác Google | Chưa thể triển khai auth đúng flow nếu tự bỏ Register/Forgot | D03 đã duyệt Google + email/password thật; triển khai và kiểm thử phase02, cập nhật Figma khi được giao | Phase02 |
| G03 Loading/error/retry component còn thiếu | Screen mạng cần state thật | D08, C07–C09, handoff; design update + test | Phase01–06 |
| G04 Demo area 6 services chưa có layout riêng | Không đủ nơi trình diễn dịch vụ theo Lab3 | D09: bổ sung Settings/Profile theo theme | Phase07A/B |
| G05 Storage/service/billing chưa xác minh | Upload bắt buộc chưa có hạ tầng | D02 owner/giảng viên chốt; không miễn bằng local PDF | Phase07A/08 |
| G06 Private data/chat/privacy chỉ local | Không an toàn hoặc không realtime khi nộp | Firestore/services/Rules và two-account tests | Phase02–05 |
| G07 SDK/version/device/project chưa khởi tạo | Không thể chạy test app | Phase01 inspect/pin tools; phase02 configure project/account | Phase01/02 |
| G08 Small text/410px screenshot chưa kiểm chứng mobile | Chưa có evidence 360/412/contrast/semantics | TC13/16/22; không coi screenshot là chứng nhận | Phase06 |
| G09 Hành vi remove/RSVP/timer lifecycle dễ bỏ sót | Sai liên kết data hoặc mất notes | Handoff + TC09/17/18; D10/D11 | Phase03–06 |
| G10 AI prompt logs/Stitch/lịch sử approval chưa có | Nguồn HTML ghi thiếu evidence formal Lab2; 6 trang không giải quyết tự động | Nhóm kiểm tra evidence riêng; không tái dựng thành chứng cứ gốc | D01 |
| G11 StudentID/tên repo/access khi nộp | Không đủ thông tin deliverables | D04/D12; chưa đổi tên/quyền remote | Phase08 |

## Gate phase00

| Gate | Kết quả thực tế |
|---|---|
| Có 7 nguồn và index/hash | PASS sau verification script |
| Đọc Figma/HTML và ghi khác biệt | PASS cho cấu trúc + ảnh chọn mẫu; chưa visual toàn bộ |
| Coverage 15 màn, 6 Settings categories, dialogs, 3 flow/recovery, 10 component families | PASS tài liệu; không là runtime PASS |
| Rubric Lab3 và kế hoạch evidence/test | PASS tài liệu; toàn bộ tests NOT RUN |
| Chấp nhận baseline/auth | APPROVED — D03/D06, người dùng xác nhận 02/11/2026; chưa triển khai |
| Review chi tiết handoff | OPEN — D07/D08/D09 và các mục còn mở |
| Formal Figma prototype/approval | OPEN — D01, không đánh PASS |

## Kiểm tra và giới hạn

Git diff --check; source hash check; coverage/link check được thực hiện và ghi phase-00-review.md. flutter analyze/test, Firebase Rules/Console/ARTEMIS NOT RUN vì chưa có pubspec.yaml/config/app. Không deploy/commit/push hoặc thay Figma trong task này. Final scope giữ ở planning/final và không phải điều kiện hoàn thành Lab3.

## Bước tiếp theo

Review docs/phase-00-review.md; nhóm chốt baseline/auth và các đề xuất trước phase tương ứng. Sau review và khi người dùng giao phase01 mới tạo Flutter shell. Không tự mở rộng scope để che các gap.
