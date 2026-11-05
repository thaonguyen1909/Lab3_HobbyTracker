# Review source Khoảnh khắc — bước 4

Ngày 04/11/2026. Review local trong lúc triển khai, không phải GitHub PR review đã hoàn thành rubric Lab 3. Không có PR/commit mới hoặc xác nhận từ giảng viên. Các finding dưới đây được đối chiếu bằng code và test chạy thật; chưa coi là ba fix ở ba commit riêng.

| ID | Mức / loại | Finding và cách tái hiện | Đánh giá / sửa | Test thực |
|---|---|---|---|---|
| M4-01 | P1 / reliability | Ghi receipt vào subcollection rồi crash trước khi ghi parent; query collection deliveries không thấy parent bị thiếu, cleanup bỏ sót receipt | ACCEPTED: ghi parent sending trước receipt; cleanup quét devices với document-name bounds chỉ thuộc outbox đó. [cleanup](../functions/src/moment_cleanup.ts#L86), [sender](../functions/src/moment_delivery.ts#L79) | cleanup integration “outbox retention...” lỗi ở lượt đầu, đạt ở lượt cuối |
| M4-02 | P1 / data safety | List object generation A, Admin test ghi generation B rồi xóa A; Storage Emulator bỏ qua DELETE precondition và xóa nhầm B | ACCEPTED: so generation hiện tại trước khi xóa, vẫn gửi generation + ifGenerationMatch cho GCS. [adapter](../functions/src/moment_cleanup_media.ts#L28) | “storage generation targeting...” đạt trên emulator; cloud TOCTOU atomic acceptance NOT RUN |
| M4-03 | P1 / expiry | Permission lookup/khởi tạo plugin kéo dài hơn thời gian ảnh còn hạn; truyền remaining cũ có thể hiển thị notification muộn | ACCEPTED: tính lại sau init trong worker, trừ Stopwatch elapsed trong notification adapter, bỏ khi <=0. [adapter](../lib/services/moment_local_notifications.dart#L44) | test “elapsed permission lookup...” đạt |
| M4-04 | P1 / privacy | Đổi UID trong lúc chờ quyền native; owner check cũ không còn hợp lệ | ACCEPTED: kiểm tra active_owner sau các await và trước show; kiểm tra sau show vẫn giữ. [adapter](../lib/services/moment_local_notifications.dart#L43) | “late account switch...” đạt, không gọi show |
| M4-05 | P2 / retention | Marker seen và index notification chỉ được dọn khi logout, tăng mãi trong phiên dài | ACCEPTED: TTL một ngày, prune theo UID, migration legacy bảo thủ, giữ index khi cancel lỗi. [retention](../lib/services/moment_local_retention.dart#L26) | 8 retention tests: UID, legacy, retry, giữ Hyper/preferences và wrong-ID namespace |
| M4-06 | P2 / migration | Chỉ query cleanupPending sẽ bỏ qua dữ liệu từ bước cũ chưa có cờ | ACCEPTED: backfill tối đa 10 doc/collection/lượt với cursor, không sửa lại false đã xử lý. [backfill](../functions/src/moment_cleanup.ts#L127) | “legacy metadata...” đạt, 23 mục được xử lý qua nhiều lượt |

Những ca tách biệt với evidence nộp bài: FCM nhận thật/lockscreen, native picker, ARTEMIS ≥3 lượt/ca, cloud Console, audit dependency và chính sách bucket vẫn mở. Không dùng bảng này để tự chấm PASS toàn bộ phase 08.
