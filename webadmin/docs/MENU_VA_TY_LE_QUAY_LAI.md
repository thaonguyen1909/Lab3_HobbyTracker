# Menu nổi và thống kê quay lại luyện tập — 06/11/2026

## Menu

Nguyên nhân cũ: row-dropdown dùng position fixed và right cố định nhưng không tính top theo nút bấm. Tọa độ tĩnh không phù hợp khi cuộn bảng/trang.

Đã dùng FloatingPopover chung cho menu dấu ba chấm, chọn cột, công việc và tài khoản. Panel được đưa ra body qua portal; tính vị trí từ getBoundingClientRect của nút, tự mở trên/dưới theo khoảng trống, giới hạn chiều rộng/chiều cao và cuộn bên trong nếu cần. Cập nhật vị trí khi cuộn/resize; đóng khi bấm ra ngoài, Escape hoặc khi nút ra khỏi viewport. Không bị overflow của bảng cắt mất.

Đã kiểm tra bằng giao diện fixture riêng: menu mở xuống, mở lên ở dòng gần cuối, menu chọn cột/công việc, đóng bằng Escape/bấm ngoài; màn hình 390×600 có menu nằm trong màn hình và cuộn được. Không kích hoạt thao tác khóa/xóa hoặc ghi dữ liệu production.

## Quay lại luyện tập

Thông báo cũ về cohort Analytics là nút giữ chỗ, chưa có tính toán. Thay bằng chỉ số quay lại luyện tập từ Firestore history, không dùng lastSignIn để giả lập Google Analytics retention.

- Gộp theo chủ sở hữu và lấy buổi luyện tập đầu tiên trong lịch sử hiện có.
- Chỉ đưa vào mẫu khi đã qua đủ 7×24 giờ từ buổi đầu tiên.
- Được tính là quay lại nếu có buổi hoàn thành vào ngày Việt Nam khác, trong 7 ngày kể từ buổi đầu.
- Mỗi người chỉ tính một lần; nhiều buổi cùng ngày không tính là quay lại.
- Có mẫu đủ điều kiện nhưng không ai quay lại: 0%. Chưa có mẫu đủ thời gian: không hiện phần trăm, giải thích đang chờ.
- Hơn 1.000 history: không tính tỷ lệ từ dữ liệu cắt ngắn; hiển thị giới hạn rõ ràng.
- Bấm thẻ mở giải thích, số người quay lại/đủ điều kiện/đang chờ. Chỉ số độc lập với khoảng ngày của biểu đồ.

Đọc cloud thực tế: 2 bản ghi history, 2 người đang chờ đủ 7 ngày, 0 người đủ điều kiện, phần trăm null. Không thêm lịch sử giả để tạo tỷ lệ.

## Kiểm tra

- 33 test đạt, gồm 5 regression vị trí menu và 7 bài tính tỷ lệ quay lại; các bài dữ liệu/quyền cũ vẫn đạt.
- TypeScript noEmit và vinext build đạt.
- Giao diện thống kê được kiểm tra trên fixture, có giải thích rõ và không còn thông báo cohort. Không coi số liệu fixture là số liệu cloud.
- Admin API local đã khởi động lại với code mới. Không deploy cloud, thay Rules hoặc cấu hình Analytics/billing.
