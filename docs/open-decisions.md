# Quyết định và đầu vào còn mở — Lab 3

Cập nhật 02/11/2026 trong audit phase00. OPEN/PROPOSED không phải phê duyệt. Chủ sở hữu là vai trò cần nhóm phân công, chưa tự suy ra tên thành viên.

| ID | Nguồn / vấn đề | Đề xuất và ảnh hưởng | Người chốt | Hạn cần chốt | Trạng thái |
|---|---|---|---|---|---|
| D01 | Specification mục11; PDF Lab3 prerequisite; Figma audit | Đã truy cập 6 trang nhưng 0 reactions/flow start; trang hiện chia theo chức năng, không chứng minh đúng cấu trúc formal Lab2. Nối 3 flow + recovery và xác nhận design chính thức, hoặc xin chấp nhận HTML; chưa có bằng chứng giảng viên duyệt | Nhóm + giảng viên | Trước nghiệm thu design parity | OPEN |
| D02 | Lab3 mục3/6: cloud upload | Xác minh điều kiện Storage/chi phí hiện hành với project; owner duyệt hạ tầng hoặc giảng viên duyệt ngoại lệ. Không tự nâng gói; local PDF chưa đủ | Chủ Firebase + giảng viên | Trước 07A | OPEN |
| D03 | Figma 7:8/7:52/7:101 và Lab3 mục6 | Người dùng xác nhận Google Sign-In + email/password thật để giữ Register/Forgot; bỏ demo bypass ở submission. Cần thiết kế xử lý cùng email/hai provider trước triển khai | Người dùng — xác nhận trong chat 02/11/2026 | Trước 02 | APPROVED — phạm vi, chưa triển khai |
| D04 | Lab3 mục9: tên repo và thông tin nộp | Nhóm cung cấp StudentID/thành viên và chốt PRM393_Lab03_<StudentID>; giữ remote hiện tại đến khi được giao đổi | Nhóm | Trước nộp | OPEN |
| D05 | Thiếu reference/ trong repo trước audit | Đã gom 7 nguồn nguyên byte, SHA-256 tại reference/source-manifest.json | Codex | Phase00 | RESOLVED — kiểm tra hash |
| D06 | Figma và HTML khác vai trò | Người dùng xác nhận giao diện theo Figma, hành vi theo Specification/HTML; Light làm baseline đầu tiên, mọi khác biệt có DX ID. Không thay thế phê duyệt giảng viên hoặc review chi tiết còn mở | Người dùng — xác nhận trong chat 02/11/2026 | Trước 01 | APPROVED — baseline |
| D07 | Creator Figma Interested selected; HTML priority=null | Đề xuất giữ priority chưa chọn để đáp ứng validation; snapshot là trạng thái minh họa | Nhóm | Trước 03 | PROPOSED |
| D08 | Chưa có state đầy đủ/network recovery trong thiết kế | Đề xuất C07–C09 và state templates trong handoff; cập nhật Figma và review layout/contrast | Nhóm | Trước 06 | PROPOSED |
| D09 | Lab3 mục3 yêu cầu demo area; UI chưa có đầy đủ | Đề xuất Settings/Profile chứa export-upload, notification center, RC values và crash actions có confirm; không thêm tab | Nhóm | Trước 07A/07B | PROPOSED |
| D10 | Privacy toggle và notification options của HTML chưa enforce | Chốt DM policy/visibility thành allowed/denied matrix; chốt reminder local vs FCM, âm thanh/weekly summary để không hứa behavior giả | Nhóm | Trước 05/06 | OPEN |
| D11 | Prototype timer Date.now và session draft | Chốt khôi phục khi background/process kill, notes/draft và lifecycle policy; monotonic timer cho active duration | Nhóm | Trước 04 | OPEN |
| D12 | Repo private; Lab3 mục9/11 yêu cầu link mở được | Chốt cách cấp quyền giảng viên và kiểm tra access trước deadline, không tự publish source | Nhóm + giảng viên | Trước 08 | OPEN |

Phase00 có thể review bộ tài liệu với các mục OPEN nêu rõ. D03/D06 đã được người dùng xác nhận; không đồng nghĩa các mục còn mở hoặc toàn bộ handoff được phê duyệt. Chưa bắt đầu phase01. Final là tham khảo riêng, không thêm gate cho Lab3.

## Xác nhận người dùng ngày 02/11/2026

> Đồng ý giao diện theo Figma, hành vi theo Specification/HTML; dùng Google và email/password thật.

Áp dụng cho D06 và D03. Login hỗ trợ Google và email/password; Register tạo tài khoản email/password thật; Forgot Password gửi yêu cầu reset thật qua Firebase Authentication. Không lưu password trong Firestore. Cùng email qua hai provider cần xử lý account linking/conflict theo xác thực hợp lệ, không tự gộp tài khoản chỉ vì email trùng. Chi tiết SDK và trường hợp lỗi sẽ được thiết kế/kiểm thử tại phase02.

D01 về prototype và bằng chứng chấp nhận giảng viên vẫn OPEN. D08/D09 về state/demo area cùng các mục khác giữ trạng thái riêng; xác nhận này không cấp quyền sửa Figma, deploy, billing hoặc chuyển phase.
