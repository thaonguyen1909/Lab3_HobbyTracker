# Demo và nghiệm thu Khoảnh khắc

Dùng dữ liệu thử riêng, không đưa tài khoản/token cá nhân lên video hoặc log chia sẻ. Đây là checklist thao tác, không phải biên bản đã chạy. Trạng thái mới nhất: [báo cáo bước 4](moments-cleanup-step4-report.md).

## Chuẩn bị

- A và B cùng nhóm `Cầu lông Demo`; C chưa tham gia. A có hobby `Cầu lông Demo 01` (Active hoặc Interested).
- B bật Thông báo khoảnh khắc trước khi A đăng ảnh mới; Groups chung bật, nhóm chưa mute. Chọn cùng một ngôn ngữ để quay.
- Chọn đúng môi trường: local có nhãn LOCAL EMULATORS và tài khoản email/password demo; cloud cần backend/Rules/index đã được owner cho phép deploy và thử thật. Chưa có deployment trong các bước 1–4.
- Popup đồng thời cần hai phiên đăng nhập riêng. Một điện thoại logout A→B chỉ kiểm tra inbox/viewer khi đăng nhập lại, không chứng minh push tới máy đang đóng app.

## Demo ngắn 4–6 phút

| Thời điểm | Thao tác | Kết quả phải thấy |
|---|---|---|
| 0:00–0:30 | Giới thiệu A/B cùng nhóm, ảnh tồn tại ba giờ từ publish | Nêu rõ môi trường local/cloud đang dùng |
| 0:30–1:30 | A chọn/chụp ảnh, chọn hobby, nhập `Hôm nay luyện cầu lông cùng nhóm`, Post | Preview, progress/xử lý, đúng một bài; mở viewer thấy countdown |
| 1:30–2:30 | B đang foreground | Inbox mới và popup có thumbnail khi tải được; View mở đúng ảnh A; B không có nút thu hồi |
| 2:30–3:15 | B chạy Hyper rồi A đăng một bài mới | Timer vẫn chạy, không tự chuyển màn; có mục chờ; Pause rồi mới xem |
| 3:15–4:00 | B mute nhóm hoặc tắt alert, A đăng bài mới | Không nhận popup mới; vẫn tự xem được danh sách ảnh nhóm |
| 4:00–4:45 | A thu hồi ảnh đầu tiên, B mở lại | Không còn khả dụng; C ngoài nhóm không mở được ảnh |
| 4:45–6:00 | Trình bày log test cleanup và chạy preview local | Nói rõ test dùng clock inject, không giả là đã chờ đủ ba giờ trên điện thoại |

Không phải chờ ba giờ trong video ngắn. Muốn xác nhận hành vi ngoài đời, giữ một bài và ghi riêng timestamp publish/expiresAt cùng ảnh/log trước/sau hạn. Không đổi đồng hồ máy hoặc sửa metadata production để thay phép thử này.

## Checklist nghiệm thu thiết bị/cloud — chưa chạy

| ID | Ca | Kết quả mong đợi | Evidence cần ghi |
|---|---|---|---|
| MM01 | A đăng, B cùng nhóm, C ngoài nhóm | B xem được, C bị chặn metadata/ảnh | Máy/tài khoản thử, video và lỗi đã che thông tin |
| MM02 | Hủy picker/từ chối quyền | Draft/ảnh cũ giữ nguyên, có lỗi hoặc hủy an toàn | Camera/gallery Android thực |
| MM03 | Mất mạng khi upload/publish, Retry | Không nhân đôi; thời hạn không được kéo dài | ID và timestamps đã ẩn UID khi chia sẻ |
| MM04 | Đủ ba giờ khi viewer đang mở | Ảnh bị ẩn, đọc mới bị từ chối dù cleanup chậm | Mốc server và ghi hình trước/sau |
| MM05 | Thu hồi/mất membership | Lần tải/mở lại bị chặn | A/B cùng một bài thử |
| MM06 | Hyper đang chạy và notification tap | Không tự rời luyện tập; xem sau | Timer/route trước và sau |
| MM07 | Foreground/background/đóng app bình thường | Popup hoặc notification phù hợp; tap mở đúng viewer | Hai điện thoại, phiên bản Android, trạng thái app |
| MM08 | Khóa màn hình, preview off/on | Tôn trọng lựa chọn và Android redaction | Ảnh lockscreen từ máy thật |
| MM09 | Logout A→B, message A đến muộn | Không hiện ảnh A trong phiên B | Video cùng máy + log đã che thông tin |
| MM10 | Mute, opt-out, Groups chung off, permission denied | Không nhận alert mới; vẫn xem nhóm nếu có quyền | Setting và bài đăng mới tương ứng |
| MM11 | Cleanup lỗi rồi phục hồi | Quyền đọc hết hạn vẫn bị chặn; file được dọn khi retry | Log cleanup/scheduler thật |
| MM12 | Đồng bộ/xóa lịch luyện tập | Không xóa nhầm notification Khoảnh khắc | Notification và Home trước/sau |

Toàn bộ bảng này hiện **NOT RUN trên thiết bị/cloud**. Các test tự động local tương ứng đạt được ghi riêng trong báo cáo; không chuyển trạng thái bằng suy luận.

## Hồi quy ba flow gốc

Tiếp tục dùng [demo-three-flows.md](demo-three-flows.md): tạo hobby/duplicate/priority → lịch/Hyper/Finish đúng một history → nhóm/chat/RSVP và Add to Home chủ động. Bộ Flutter hiện tại đã chạy lại 145 test, Rules cũ 35 test đạt. Thao tác trên hai tài khoản cloud và quay video vẫn cần làm thực tế.

## Sau khi review source

Chỉ deploy khi owner cho phép thay đổi cụ thể và đã kiểm tra bucket/region/IAM/billing, index collection-group, hai scheduled functions, soft delete/retention và dependency audit. Chưa có deployment/tag/commit trong bước này. ARTEMIS và Console evidence của toàn Lab 3 giữ gate riêng; checklist này không thay thế các yêu cầu đó.
