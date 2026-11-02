# Đối chiếu Figma và HTML

Ngày: 02/11/2026. File key: 5JiJtLyXN6DEpC1LycQPBb. Đọc bằng MCP, không chỉnh canvas. Session: 67b70401-4f9c-4d3d-b082-f19d216181f7.

## Phương pháp và giới hạn

Đọc metadata 6 trang, quét reactions và flowStartingPoints trên từng trang; kết quả lưu trong evidence/00/*.json. Xem ảnh render trực tiếp 7:8 (Login), 9:44 (Home), 9:356 (Creator), 9:1697 (Appearance). Các ảnh đã xem qua tool, không có ảnh PNG lưu trong repo; không ghi là evidence screenshot đã nộp. Các màn còn lại đối chiếu cấu trúc/tên node, chưa kiểm tra thị giác từng pixel. HTML được đọc Specification, DesignArchive và các handler trong Prototype; không có báo cáo chạy lại toàn bộ flow trong lần audit này. Đây không phải test report E2E.

## Kết quả

| Phần | Figma | HTML | Kết luận |
|---|---|---|---|
| Trang | 01 Tổng, 02 Authentication, 03 Home + Hyper, 04 My Hobbies, 05 Community, 06 Settings | 3 HTML chia prototype/spec/archive | Đủ 6 trang về số lượng; không tự suy ra đáp ứng đúng cấu trúc nội dung rubric Lab2 |
| Giao diện | 23 screen components + 7 theme previews; Tổng dùng instances | 15 screen destinations + dialog/category | Không xung đột số lượng khi phân loại đúng; xem traceability |
| Tương tác | Cả 6 trang đều 0 reaction nodes, flowStartingPoints=[] | Có handler create/schedule/timer/chat/RSVP/theme | Chưa có prototype Figma tương tác để nghiệm thu 3 flow |
| Login | Email/password, Try Demo Account, không Google CTA trong 7:8 | Form mô phỏng và sessionStorage | Cần Google thật; không đưa demo login thành lối vượt auth trong bản nộp |
| Home | Tuần, Schedule, Start, History tại 410×930 | Ngày động, sort giờ, Add Schedule | Cấu trúc chính tương ứng; dữ liệu ngày cố định trên ảnh là minh họa |
| Creator | Icon grid 12, màu 6, live preview; Interested selected | Create priority=null, validation tên/priority, edit giữ ID | Hình thức phù hợp; giá trị khởi tạo phải chốt theo D07 |
| Theme | Appearance có 7 lựa chọn và theme screen components | CSS thay palette, hình dạng và persist | Không đồng nghĩa 7 theme đã đạt contrast/360/412 |
| Component | 4 button variants, Input, Headers, 4 Nav, Checkbox | Button/input/card/dialog/loading-empty-error được mô tả | Chưa thấy component riêng đầy đủ loading/error/retry; tên node không chứng minh behavior |
| Dữ liệu | Thiết kế tĩnh, sample user/date | localStorage, chat local echo và notification preview | Lab3 phải chuyển sang backend/dịch vụ thật |

## Các hành vi dễ bỏ sót khi chuyển sang Flutter

- Hủy RSVP trong handler event-rsvp bỏ schedule có eventId tương ứng; không xóa lịch khác.
- Remove hobby xóa schedule của hobby nhưng giữ record snapshot; đổi priority hoàn toàn không xóa gì.
- Reset timer giữ notes; pauseOnExit là tùy chọn; Finish phải idempotent khi chuyển sang mạng async.
- Chat local không có bảo mật; privacy toggle của prototype chưa enforce, cần query/Rules thật.
- Connected Apps thực chất là shortcut, không tích hợp tài khoản Spotify/YouTube.

## Baseline đã được người dùng xác nhận

Ngày 02/11/2026, người dùng xác nhận giữ giao diện theo Figma, hành vi theo Specification/HTML; Light làm chuẩn đầu tiên. Mọi chênh lệch ghi DX01–DX08 trong traceability. D03 cũng được xác nhận: Google + email/password thật. Đây là quyết định của người dùng, không phải bằng chứng giảng viên phê duyệt hoặc Figma đã có prototype tương tác. Không sửa Figma, không thêm web/Staff/Gemini trong audit.
