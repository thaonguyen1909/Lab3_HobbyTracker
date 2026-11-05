# Phạm vi và bằng chứng nghiệm thu

## Bản đã xây dựng

Không chỉ có dashboard: có đủ 18 mục điều hướng trong prompt, quyền theo vai trò, danh sách/tìm kiếm/sắp xếp/phân trang/cột/chọn nhiều, form, panel chi tiết, hộp thoại lý do, skeleton/empty/error/retry, ma trận quyền, lịch sự kiện và 7 theme. Dữ liệu mẫu chỉ lưu trong trình duyệt; không tự ghi Firebase.

| Nhóm | Đã có | Giới hạn / phần còn thiếu |
|---|---|---|
| Đăng nhập | Email/Google qua Firebase Web SDK, kiểm tra token/claims/staff phía API, đăng xuất, quên mật khẩu | Chưa có MFA challenge/enrollment, trang quản lý nhiều phiên và lời mời qua email |
| Dashboard / báo cáo | KPI, biểu đồ ngày, Active/Interested, sự kiện, báo cáo, audit; số liệu từ nguồn thật qua API | Tổng hợp tối đa 1.000 bản ghi mỗi nguồn và 100 sự kiện/báo cáo; ghi rõ phạm vi. Chưa có cohort retention, so sánh kỳ, custom range hoặc kho Analytics |
| Người dùng | Danh sách Auth, chi tiết, tổng hobbies/plans/history, khóa/mở, hạn chế đăng/gửi tin, thu hồi phiên, tạo link reset theo quyền | Chưa có quy trình xóa toàn bộ tài khoản, chi tiết tất cả tab, bộ lọc kết hợp nâng cao và gửi email reset qua server |
| Sở thích / lịch / lịch sử | Ba tab đọc dữ liệu đúng subcollection, metadata không lộ ghi chú, xuất CSV có audit | Chưa có đề nghị sửa dữ liệu, phát hiện trùng/bất thường hoặc lịch luyện tập dạng calendar |
| Bài viết / bình luận | Tạo bài quản trị; xem ngữ cảnh; ẩn/khôi phục bài và bình luận; bulk có lý do; cờ ghim | Chưa có purge vĩnh viễn và ưu tiên ghim trong feed Flutter |
| Nhóm | Tạo/sửa, xem thành viên, chuyển chủ, khóa/mở đồng bộ rules | Chưa có quản lý xóa thành viên/lưu trữ/duyệt nhóm hoặc các tab báo cáo chuyên biệt |
| Sự kiện | Tạo/sửa/nháp/xuất bản/hủy/lưu trữ, bảng/lịch, RSVP metadata | RSVP scan có giới hạn; chưa có gửi cập nhật trực tiếp từ màn sự kiện, xuất RSVP riêng, upload banner hoặc kiểm soát sức chứa. Không tự tạo lịch cá nhân |
| Hội thoại | Metadata DM, đọc nội dung qua báo cáo có quyền + lý do + audit | Chưa tổng hợp metadata group chat, không duyệt tùy ý tin nhắn riêng |
| Báo cáo | Tạo từ admin hoặc mobile API, target whitelist, phân công, xử lý/bác bỏ/mở lại, bằng chứng có audit | Chưa có workflow khiếu nại/nhắc SLA/ghi chú nội bộ riêng cho báo cáo |
| Thông báo | Nháp/đặt lịch/hủy/gửi FCM, Android preview, đối tượng all/user/group/event, opt-in, chống gửi lại, kết quả accepted/failed | Worker theo lịch phải deploy riêng; giới hạn 1.000 đối tượng; chưa có gửi thử riêng và retry có điều phối |
| Hỗ trợ | Ticket, phân công/phản hồi/ghi chú nội bộ/đóng/mở lại; mobile API lọc ghi chú nội bộ | App chưa có màn ticket; chưa đính kèm file, mẫu trả lời, workflow xóa/xuất tài khoản |
| Nội dung | CMS nháp/xuất bản/lưu trữ, form/chi tiết | Chưa có lịch xuất bản, khôi phục phiên bản lịch sử, đa ngôn ngữ hoặc màn tiêu thụ CMS trong Flutter |
| Nhân sự | 5 vai trò kiểm tra trên API, cấp/đổi/thu hồi, chống tự hạ quyền và Super Admin cuối | Cấp cho email đã tồn tại, chưa gửi/chấp nhận lời mời hoặc chỉnh permission matrix tùy biến |
| Files | Metadata Storage và tải PDF có audit/URL 120 giây | Chưa xóa file, dọn file mồ côi và file processing jobs |
| Cấu hình | Validation, xem diff, version/concurrency, ghi Firestore và audit; bridge flags/banner/maintenance/min version | Chưa có lịch sử/rollback UI hoặc đồng bộ Remote Config server. Bridge Flutter chưa được analyzer/test/build tại đây |
| Nhật ký | Log có actor/role/reason/before-after redacted, tìm kiếm/xuất theo quyền, không sửa/xóa trên UI | Auth/FCM là thao tác liên dịch vụ: có intent/pending log; cần đối chiếu khi một dịch vụ lỗi. Không có distributed transaction giữa Auth, Firestore và FCM |
| Vận hành | Trang trạng thái có nhãn nguồn/chưa tích hợp, danh sách job đọc từ Firestore | Chưa có job retry worker, Crashlytics/Analytics API, backup/restore, dung lượng/quota hoặc cảnh báo tự động |
| Cài đặt | Theme, tài khoản/role, kết nối Firebase, timezone Việt Nam, logout; thử role chỉ trong demo | Chưa sửa hồ sơ admin/mật khẩu, MFA enrollment, phiên, timezone/ngôn ngữ tùy chọn |

Các giới hạn trên là tình trạng thực tế của mã nguồn, không đánh dấu PASS chỉ vì màn hình đã xuất hiện. Backend cloud/FCM thiết bị thật chưa được cấu hình hoặc xác nhận. Những nghiệp vụ nâng cao không được giả lập báo thành công ở production.

## Màu đã đối chiếu

Nguồn: `design/figma-palettes.json` và `lib/theme/hobby_theme.dart` trong app nguồn đã cung cấp. `lib/admin/palettes.json` giữ nguyên 7 bộ giá trị; font `public/fonts/Inter.ttf` lấy từ app. Light mặc định:

| Token | Màu |
|---|---|
| Primary | #087F72 |
| Background | #F7FAF7 |
| Surface | #FFFFFF |
| Text | #213D36 |
| Muted | #4F6F63 |
| Soft | #E7F5ED |
| Hero | #C5EADC |
| Border | #D8E9DF |

Theme Dark của app sử dụng primary xanh lam #88B8FF; không tự đổi nó thành mint. Radius, outline icons và spacing web giữ cùng hướng Design System nhưng điều chỉnh cho bảng quản trị desktop. Không tuyên bố mọi pixel web tương ứng một màn mobile trong Figma.

## Các kiểm tra

Kết quả kiểm thử thực tế được ghi tại `docs/test-results.txt`. TypeScript được kiểm tra bằng `tsc --noEmit`; build production bằng Vinext/Workers. API/rules được chạy bằng Firebase Auth + Firestore Emulator; FCM dùng mock. Hai bộ rules test gốc của Flutter được chạy lại với rules tích hợp để phát hiện hồi quy Active/Interested, claims tên sở thích, luyện tập, RSVP và quyền sở hữu.

Browser QA: dashboard, tìm kiếm UID, panel chi tiết, khóa tài khoản mẫu kèm lý do/audit, chuyển đủ 7 theme, mở thiết lập Firebase, responsive iframe 390 px và 1024 px. Đã sửa lỗi ID mẫu trên preview HTTP sau khi phát hiện trong browser QA. Các screenshot là dữ liệu mẫu.

Chưa kiểm thử Firebase production, Google popup thật, gửi email thật, Storage signing, push tới Android, Android APK hoặc bridge Flutter. Các bước cần chủ project thực hiện nằm trong `KET_NOI_FIREBASE_VA_APP.md`.
