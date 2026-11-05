# Nút theo trạng thái — 06/11/2026

Dùng một quy tắc chung availableActions/actionAvailable cho bảng, chi tiết, bulk và gateway preview. API chặn những chuyển trạng thái không phù hợp (409) ở luồng bản ghi chính; các gate comments/sendCampaign vẫn kiểm tra tồn tại/trạng thái trong transaction. Không chỉ ẩn nút ở giao diện.

| Nhóm | Quy tắc |
|---|---|
| Tài khoản khóa | Chỉ Mở tài khoản |
| Tài khoản hoạt động | Khóa, thu hồi phiên (không phải chính mình/admin đang active); reset chỉ provider password + email; hạn chế chưa bật mới hiện nút bật |
| Tài khoản hạn chế | Hiện đúng hạn chế còn thiếu và Gỡ hạn chế; API trả hai cờ postingRestricted/messagingRestricted |
| Bài đang hiện/đã ghim/đã ẩn | Ẩn + Ghim / Ẩn + Bỏ ghim / Khôi phục |
| Nhóm mở/khóa | Khóa hoặc Mở, cùng Sửa/Chuyển chủ |
| Sự kiện nháp | Sửa, Xuất bản nếu ngày bắt đầu còn tương lai, Lưu trữ |
| Sự kiện đã xuất bản | Sửa, Hủy, Lưu trữ |
| Sự kiện hủy/lưu trữ | Hủy: sửa/khôi phục/lưu trữ; Lưu trữ: khôi phục. Khôi phục về nháp, không tự xuất bản |
| Chiến dịch nháp/lên lịch | Sửa, Gửi, Hủy |
| Chiến dịch gửi/đang gửi/lỗi/một phần/hủy | Không cho gửi lại hoặc sửa nội dung để tránh gửi trùng |
| Báo cáo mới/đang xử lý | Phân công, Xử lý, Bác bỏ |
| Báo cáo đóng/bác bỏ | Chỉ Mở lại |
| Ticket mở | Phân công, Phản hồi, Ghi chú, Xử lý |
| Ticket đã xử lý | Ghi chú nội bộ hoặc Mở lại; không phản hồi công khai khi chưa mở lại |
| CMS nháp/xuất bản/lưu trữ | Nháp: Sửa/Xuất bản/Lưu trữ; Xuất bản: Sửa/Lưu trữ; Lưu trữ: Khôi phục về nháp |
| Nhân sự | Không sửa quyền chính mình hoặc Super Admin cuối; disabled cho cấp vai trò lại; pending không tác động |
| Tệp | Chỉ tải khi available |
| Vận hành | Không hiện retry khi worker chưa được triển khai |

Bulk chỉ xuất hiện nếu TẤT CẢ bản ghi được chọn đều cho phép cùng hành động. Form Edit không cho đổi status để bỏ qua luồng trạng thái; đổi vai trò không liệt kê lại vai trò hiện tại. Xem chi tiết vẫn có ngay cả khi không có thao tác ghi.

Đã kiểm tra 43 tests cùng TypeScript/build. UI fixture kiểm tra menu + chi tiết tài khoản khóa, bài pinned và hidden. Chưa chạy toàn bộ thao tác ghi trên Firebase thật; không khóa/xóa tài khoản thực để thử.
