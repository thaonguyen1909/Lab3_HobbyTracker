# Khoảnh khắc — Node.js riêng + Cloudinary

Người dùng chốt kiến trúc ngày 04/11/2026 và chọn thử backend trên PC qua USB. Theo người dùng, giảng viên cho phép Cloudinary/S3 thay nơi upload. Hướng dẫn này ưu tiên hơn hướng Firebase Storage/Functions cũ cho **Khoảnh khắc**. Không sửa tài liệu gốc, không tự đánh dấu yêu cầu upload PDF của toàn Lab 3 đã đạt.

## Kiến trúc hiện hành

Flutter → Firebase Authentication thật → Node API xác minh ID token/thành viên/hobby → Cloudinary lưu ảnh authenticated. Firestore lưu sessions, metadata, outbox/inbox. API trả bytes sau kiểm tra quyền/hạn; không cấp URL ảnh công khai hoặc API secret cho app.

Backend dùng lại MomentService/Delivery/Cleanup: poll outbox sau mỗi lượt + 15 giây, cleanup sau mỗi lượt + 5 phút. Không cần deploy Cloud Functions/Cloud Scheduler hoặc tạo Firebase Storage cho Khoảnh khắc. Firebase giữ nguyên gói. Hosting/Cloudinary vẫn cần kiểm tra quota/gói thật; không hứa miễn phí vô hạn.

Thời hạn 10.800 giây từ server publish. Tải mới bị chặn khi hết hạn/thu hồi/mất membership; xóa file là job riêng có retry. Không thu hồi screenshot/bản sao đã tải. Server dùng private_download_url hạn 30 giây nội bộ; URL không được gửi ra app. Ảnh qua backend để kiểm tra 5 MiB/định dạng và bỏ EXIF/GPS trước khi lưu.

## Cấu hình cần owner chuẩn bị

1. Cloudinary cloud name, API key, API secret. **Chỉ cloud name được gửi trong chat**; key/secret điền local. Không dùng unsigned preset/public delivery cho ảnh nhóm riêng tư.
2. Firebase Admin credentials cho hobbytracker-6ace6. CLI login không thay thế credentials của backend. Owner vào Firebase Console → Project settings → Service accounts → Generate new private key nếu chính sách tổ chức cho phép. Lưu tại `secrets/firebase-admin.json` (Git ignored); không gửi file hoặc token qua chat. Cần quyền Firestore; kiểm tra token bị thu hồi cần quyền Auth; gửi FCM cần quyền FCM. Không cấp Owner chỉ để thử.
3. Firestore Rules/indexes Khoảnh khắc cần đối chiếu và deploy đúng dự án để Flutter đọc inbox/settings. Chạy API không tự deploy các file này. Không mở allow true để chữa lỗi. Chưa deploy mới trong lần chuyển kiến trúc này.

## PowerShell A — backend thật trên PC

```powershell
cd D:\Ki-8\PRM393\project\Lab3\Lab3_HobbyTracker
$env:Path = 'C:\Users\Acer\AppData\Local\npm-cache\_npx\52027bd8fc0022aa\node_modules\node\bin;' + $env:Path
node --version
# Node phải là v22. Nếu chưa có dependencies:
npm.cmd --prefix functions ci
# CHỈ copy lần đầu; không ghi đè file đã cấu hình:
Copy-Item functions\moments-server.env.example functions\.env.local
```

Mở `functions/.env.local` bằng editor trên máy. Điền cloud name/key/secret và đường dẫn service-account file; đường dẫn Windows trong env dùng dấu `/`. Không đặt secret vào dart-define/source. Sau khi cấu hình:

```powershell
.\scripts\start-moments-api.ps1
```

Phải thấy `Moments API listening on 127.0.0.1:8787`. [Health local](http://127.0.0.1:8787/health) chỉ chứng minh process HTTP chạy, không chứng minh Cloudinary/Firebase đã kết nối. Backend từ chối biến emulator; dừng emulator cũ không tự xóa biến môi trường đã đặt trong shell. Backend bind loopback mặc định; không mở cổng ra mạng. Repo chỉ có template, chưa tạo secret thật hay tự chạy backend live.

## PowerShell B — điện thoại USB, Firebase thật

```powershell
cd D:\Ki-8\PRM393\project\Lab3\Lab3_HobbyTracker
$adb = 'D:\Ki-8\PRM393\androidsdk\platform-tools\adb.exe'
$momentDevice = 'R5CY81PSMAJ'
& $adb devices -l
& $adb -s $momentDevice reverse tcp:8787 tcp:8787
& 'D:\Ki-8\PRM393\flutter\bin\flutter.bat' run -d $momentDevice --dart-define=MOMENTS_API_URL=http://127.0.0.1:8787
```

Không thêm USE_FIREBASE_EMULATORS. Dừng lượt flutter run cũ và khởi chạy lại; hot reload không đổi dart-define. Dùng tài khoản Google/email-password thật. Thiếu MOMENTS_API_URL thì Khoảnh khắc báo chưa cấu hình thay vì gọi Functions chưa deploy; các flow khác vẫn dùng Firebase như trước.

Một máy thử đăng/xem/countdown/thu hồi, logout A→B để thử quyền xem. Popup đồng thời cần hai phiên app: reverse 8787 cho từng điện thoại và build cùng dart-define. Background thumbnail cũng dùng API mới. Giữ PC/backend/cáp hoạt động.

FCM mặc định tắt trong template; outbox vẫn tạo inbox/popup foreground khi Rules/indexes đã triển khai. Muốn thử push thật, đặt MOMENTS_ENABLE_FCM=true trong server env rồi khởi động lại backend. B opt-in trước khi A đăng **bài mới**; bật cờ không gửi lại bài cũ. Chưa có nghiệm thu push/lockscreen trên hai máy.

## Hợp đồng và vận hành

- GET /health: trạng thái process, không có thông tin bí mật.
- POST /v1/beginGroupMomentUpload, publishGroupMoment, listGroupMoments, getGroupMoment, getGroupMomentImage, retractGroupMoment: JSON theo hợp đồng cũ; response `{data: ...}` hoặc `{error: {code,message}}`.
- POST /v1/stage?momentId=...: application/octet-stream ≤5 MiB. Chỉ session của UID token, membership/hobby hợp lệ, chưa hết hạn; không thay ảnh đã nhận. Upload tiến trình hiện tại hiển thị hoàn thành khi backend nhận xong, không đo từng byte truyền mạng.
- Mọi POST cần Bearer Firebase ID token. UID/quyền/expiry không lấy từ body. Token bị thu hồi/sai dự án bị từ chối. Response private/no-store, không redirect token. HTTPS bắt buộc khi release; HTTP loopback chỉ debug USB.
- Chưa chọn/deploy hosting. Hosting cần HTTPS, secret manager, worker liên tục hoặc cron bảo mật riêng, giới hạn tài nguyên và giám sát quota. PC tắt/USB rút thì API/job local dừng; không hứa xóa đúng giờ lúc process ngừng. Poll Firestore phát sinh reads; ảnh qua API tiêu thụ bandwidth/RAM.
- Cần thử authenticated upload/download/delete trên gói Cloudinary thật; không đổi sang public để né giới hạn gói. Legacy emulator Storage/Functions vẫn giữ cho test cũ, không phải bằng chứng Cloudinary thật.

Xem [báo cáo](moments-cloudinary-report.md). Nguồn: [Cloudinary upload](https://cloudinary.com/documentation/node_image_and_video_upload), [authenticated assets](https://cloudinary.com/documentation/upload_parameters), [Admin API](https://cloudinary.com/documentation/admin_api), [Firebase ID tokens](https://firebase.google.com/docs/auth/admin/verify-id-tokens), [FCM server](https://firebase.google.com/docs/cloud-messaging/server-environment).
