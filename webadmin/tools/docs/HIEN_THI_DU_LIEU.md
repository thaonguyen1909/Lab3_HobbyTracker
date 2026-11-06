# Hiển thị dữ liệu theo tên chức năng — 06/11/2026

## Thay đổi

- Dùng chung bộ nhãn và định dạng cho bảng, tìm kiếm, bộ lọc, trường chọn, chi tiết, xem thay đổi cấu hình, lịch sử quản trị và CSV.
- Trạng thái, mức ưu tiên, vai trò, loại nội dung, đối tượng nhận, loại thông báo, màn hình đích, biểu tượng và màu có tên tiếng Việt. Ngày giờ theo Việt Nam; thời lượng và dung lượng có đơn vị. Giá trị chưa biết có nhãn rõ ràng, không hiện mã nội bộ.
- API tra tên công khai của chủ sở hữu, tác giả, người dùng, người gửi/người thực hiện, người báo cáo và người phụ trách. Sở thích/lịch/sự kiện liên quan được tra tên. Không đổi khóa bản ghi hoặc schema dữ liệu gốc.
- Thông tin báo cáo chỉ hiện tên loại đối tượng ở danh sách; không tự lấy nội dung riêng tư. Xem bằng chứng vẫn cần quyền và lý do, có ghi audit.
- Chi tiết không hiện ID/Base64/đường dẫn Firestore làm nội dung chính. Bằng chứng và dữ liệu trước/sau dùng danh sách tên trường–giá trị thay JSON. Trường nội bộ/khóa bí mật không đưa vào chi tiết.
- Chủ nhóm, người dùng, người phụ trách và người nhận thông báo có danh sách chọn tên, hỗ trợ tải thêm. Email phụ chỉ trả cho vai trò có quyền xem người dùng; nhãn công khai không dùng email thay tên.
- Khắc phục endpoint chi tiết các bản ghi luyện tập: giải mã và kiểm tra đúng users/<owner>/<hobbies|plans|history>/<record>, giữ quyền practice và loại ghi chú riêng tư.
- Các ID cần thiết cho API vẫn được giữ nguyên trong giá trị lựa chọn và request, không biến nhãn hiển thị thành khóa ghi dữ liệu.

## Kiểm tra thực tế

- 21 tests đạt: 10 nghiệp vụ/quyền hiện có và 11 bài mới về định dạng, tham chiếu, dữ liệu thiếu, ngày lỗi, quyền lookup, không lộ email cho moderator, không vượt gate bằng chứng, chi tiết luyện tập và loại ghi chú riêng tư.
- TypeScript noEmit và build vinext đạt.
- Kiểm tra giao diện bằng fixture preview riêng trên cổng 5174: toàn bộ 18 module điều hướng, các bảng chính, chi tiết thông báo và các lựa chọn biểu mẫu. Không ghi dữ liệu fixture vào Firebase. Preview đã dừng sau kiểm tra.
- Kiểm tra đọc cloud bằng credential backend: 5 hobby và 2 history được lấy mẫu; tên chủ sở hữu được giải quyết đủ 7/7. Chỉ in số lượng, không xuất thông tin cá nhân hoặc khóa.
- API local đã khởi động lại. Kiểm tra health 200; endpoint danh sách lựa chọn khi không có token trả 401.
- Không deploy cloud hoặc thay Rules. Chưa thực hiện một lượt CRUD trên tài khoản quản trị qua trình duyệt trong lượt này; tab kiểm tra live đang ở màn đăng nhập.

## Tệp chính

- lib/admin/presentation.mjs: nhãn và định dạng dùng chung.
- functions/src/presentation.mjs: giải quyết tên tham chiếu.
- app/admin/AdminApp.tsx và lib/admin/modules.ts: bảng, chi tiết, biểu mẫu, CSV, cấu hình.
- functions/src/app.mjs: lookup có kiểm tra quyền, tích hợp tên và endpoint chi tiết luyện tập.
- functions/test/presentation.test.mjs và presentation-api.test.mjs: hồi quy định dạng, dữ liệu và quyền.
- scripts/preview-formatting.mjs: preview fixture riêng để kiểm tra, không dùng làm web thật.
