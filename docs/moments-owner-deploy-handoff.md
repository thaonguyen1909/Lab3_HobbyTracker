# Nhờ chủ dự án hoàn tất quyền deploy Khoảnh khắc

> **Đã xử lý:** owner thêm Service Usage Consumer; kiểm tra IAM true và deploy Firestore thành công, indexes READY. Không còn yêu cầu owner cấp thêm role trong tài liệu này. Xem [kết quả sau IAM](moments-retest-report.md). Phần hướng dẫn bên dưới được giữ làm lịch sử bàn giao.

> **Cập nhật sau retest 04/11/2026:** testIamPermissions đã xác nhận tài khoản CLI đúng và có quyền Rules/indexes trong nhóm đã kiểm tra. Chỉ serviceusage.services.use bị thiếu. Owner chỉ cần bổ sung **Service Usage Consumer** cho thaontse184164@fpt.edu.vn trên hobbytracker-6ace6 trước khi retry; không cần cấp thêm các role khác một cách mặc định. [Bằng chứng retest](moments-retest-report.md) ưu tiên hơn danh sách quyền dự kiến bên dưới.

Đích duy nhất: **hobbytracker-6ace6**. Tài khoản CLI triển khai: **thaontse184164@fpt.edu.vn**. Ngày 04/11/2026, CLI bị 403 tại Service Usage API, thiếu serviceusage.services.use. Lệnh dừng trước khi deploy Rules/indexes. Người dùng xác nhận không có quyền quản lý IAM và sẽ nhờ owner. Không đổi billing hay tạo dự án thay thế.

## Tin nhắn có thể gửi owner

> Nhờ bạn kiểm tra quyền của thaontse184164@fpt.edu.vn trên hobbytracker-6ace6 để triển khai Firestore Rules/indexes Khoảnh khắc. Hiện Firebase CLI trả 403 thiếu serviceusage.services.use; cần bổ sung Service Usage Consumer (roles/serviceusage.serviceUsageConsumer). Đồng thời kiểm tra quyền publish Rules và tạo indexes: Firebase Rules Admin (roles/firebaserules.admin), Cloud Datastore Index Admin (roles/datastore.indexAdmin), hoặc quyền tương đương đã có. Chỉ thêm phần còn thiếu; không cần cấp Owner và không đổi gói cước. Nếu bạn muốn tự deploy thì mình có sẵn cấu hình chỉ Firestore trong firebase.moments-cloudinary.json.

Owner mở [IAM của đúng dự án](https://console.cloud.google.com/iam-admin/iam?project=hobbytracker-6ace6), chọn email trên, Edit principal → Add another role → chọn vai trò cần thiết → Save. Các quyền Service Usage/Rules/indexes là quyền deployment của người thao tác CLI, không phải Cloudinary credentials hoặc role nhúng trong app.

Để owner tự deploy từ checkout đã review, dùng tài khoản có quyền của owner trong CLI rồi chạy tại repository:

```powershell
firebase deploy --config firebase.moments-cloudinary.json --only "firestore:rules,firestore:indexes" --project hobbytracker-6ace6 --non-interactive
```

Không dùng --force, không deploy Functions/Storage, không dùng firebase deploy không giới hạn target. Cấu hình riêng chỉ chứa Firestore; không nâng billing. Trước khi chạy cần đối chiếu indexes lần nữa nếu có người khác sửa cloud: snapshot hiện tại có 0 composite indexes và 0 field overrides, file local chỉ thêm Moments. Backup Rules hiện tại đã giữ local trong deployment-artifacts/cloudinary-rollout (Git ignored); Rules diff chỉ thêm các đường Khoảnh khắc/settings, giữ các flow cũ.

## Trạng thái bàn giao

- Cloudinary credentials + Firebase Admin read-only readiness đã đạt.
- Đã upload ảnh tự sinh 32×32 authenticated, tải private HTTP 200 và xóa đúng ảnh thử; không dùng ảnh/người dùng/nhóm thật.
- 31 Firestore Rules regression tests đạt trên emulator riêng trước deploy. Không coi đây là nghiệm thu Rules cloud hoặc điện thoại.
- Sau khi owner cấp quyền hoặc deploy, kiểm tra Rules release/indexes READY, khởi động Node API local và build app với MOMENTS_API_URL. Worker/backend hiện chưa được tự chạy trong lượt kiểm tra này.
- Source/local checks trước đó và rủi ro còn lại xem [báo cáo](moments-cloudinary-report.md); chạy USB xem [hướng dẫn](moments-cloudinary-run.md).

Nguồn: [quyền Rules](https://docs.cloud.google.com/iam/docs/roles-permissions/firebaserules), [quyền indexes](https://firebase.google.com/docs/firestore/query-data/indexing). Quyền Service Usage Consumer được yêu cầu trực tiếp trong lỗi CLI đã lưu tại docs/evidence/07b/cloudinary/firestore-deploy.log.
