# Kết nối web admin với Hobby Tracker

> Audit 06/11/2026: bộ Rules tích hợp trong web cũ hơn app và thiếu các đường dẫn Khoảnh khắc. Không deploy đè nguyên bản này trước khi hợp nhất và kiểm thử. Xem [đối chiếu app/web](DOI_CHIEU_APP_WEB.md).

Web đã có luồng dữ liệu thật, nhưng chưa đăng nhập hoặc triển khai vào Firebase của bạn. Bản web mở mặc định ở dữ liệu mẫu và chỉ chuyển sang dữ liệu thật sau khi `/me` xác thực ID token cùng vai trò trên máy chủ.

## 1. Chuẩn bị đúng project

Dùng chính Firebase project đang chứa app Android `vn.prm393.hobbytracker`, không tạo project dữ liệu khác. Trong Firebase Console → Project settings → General → Your apps, thêm Web app và sao chép **Firebase Web config** gồm `apiKey`, `authDomain`, `projectId`, `appId`, `storageBucket` nếu có. Đây là cấu hình công khai; tuyệt đối không dán service account/private key lên web.

Authentication → Sign-in method: bật Email/Password và Google nếu dùng. Authentication → Settings → Authorized domains: thêm hostname của web admin đã triển khai. Dùng tài khoản email đã tồn tại trong Authentication để khởi tạo quản trị viên đầu tiên. Tài khoản người dùng app không tự có quyền quản trị.

## 2. Cài và triển khai API

Cần Node 22, Java 21+ để chạy Emulator, Firebase CLI và quyền triển khai trên project. Các lệnh chạy từ thư mục mã nguồn web admin.

```bash
npm --prefix functions ci
npx --prefix functions firebase login
```

Tạo file `functions/.env.PROJECT_ID` (đã được bỏ khỏi Git):

```dotenv
ADMIN_ALLOWED_ORIGINS=https://HOSTNAME_WEB_ADMIN,http://localhost:4173,http://localhost:3000
ADMIN_STORAGE_BUCKET=TEN_BUCKET_DUNG_TRONG_FIREBASE_STORAGE
REQUIRE_ADMIN_MFA=false
```

Thay PROJECT_ID/HOSTNAME/bucket bằng giá trị thật. Không đặt API key riêng hay khóa JSON trong biến frontend. Khóa ứng dụng đang dùng và quyền Cloud IAM là hai lớp khác nhau.

Kiểm tra khác biệt giữa rules hiện có và `integration/firebase/`; gói rules này giữ nguyên nghiệp vụ của app nguồn và bổ sung chặn tài khoản/phiên, hạn chế đăng bài/gửi tin và khóa nhóm. Không ghi đè những rules bạn đã sửa sau bản nguồn mà chưa đối chiếu.

```bash
npx --prefix functions firebase deploy --project PROJECT_ID --only firestore:rules,firestore:indexes
npx --prefix functions firebase deploy --project PROJECT_ID --only functions:hobby-admin:adminApi,functions:hobby-admin:mobileApi
```

Đây là hai HTTP API có Firebase ID token: `adminApi` cho nhân viên, `mobileApi` cho người dùng app gửi báo cáo và yêu cầu hỗ trợ. Không cần triển khai `adminCampaignScheduler` ở bước này. Giữ lại các Functions cũ của app, không xóa codebase khác.

Nếu Console yêu cầu hoàn tất billing/API/quyền triển khai, chủ project thực hiện trên tài khoản của mình. Không có thay đổi billing nào được thực hiện trong quá trình tạo bản web này.

## 3. Cấp Super Admin đầu tiên

Dùng Application Default Credentials trên máy cá nhân có quyền quản trị project:

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project PROJECT_ID
node functions/scripts/bootstrap-admin.mjs PROJECT_ID EMAIL_DA_CO_TRONG_FIREBASE_AUTH
```

Script một lần tạo `adminStaff/{uid}` và custom claim `adminRole=superadmin`, ghi nhật ký, thu hồi token cũ. Đăng xuất và đăng nhập lại. Nếu script lỗi giữa chừng, hồ sơ giữ `pending`; kiểm tra `adminSystem/bootstrap` và claims trong Auth bằng tài khoản có quyền trước khi sửa. Không sửa `users/{uid}.role` để cấp quyền admin.

Nhân viên tiếp theo: Super Admin → Quản trị viên → Cấp quyền → email đã có trong Authentication → vai trò. Phiên của nhân viên phải đăng nhập lại sau khi đổi quyền. Giao diện hiện chưa gửi email mời tự động.

## 4. Kết nối trên web

Mở web → **Kết nối Firebase** → nhập URL `adminApi` mà Firebase CLI trả về và Firebase Web config dạng JSON → đăng nhập bằng tài khoản vừa cấp quyền. Chỉ khi API trả về quyền hợp lệ, banner đổi sang Firebase đã xác thực. Đăng nhập Firebase thành công nhưng thiếu `adminStaff` hoặc custom claim vẫn bị từ chối.

CORS chỉ cho những origin trong `ADMIN_ALLOWED_ORIGINS`. Sau khi thay biến, triển khai lại API. Kiểm tra `/health` chỉ chứng minh HTTP API còn phục vụ, không chứng minh toàn bộ Firebase đã cấu hình đúng.

## 5. Những thao tác liên kết được ngay với app cũ

- Web và app đọc cùng `users`, `posts`, `groups`, `events`, các subcollection sở thích/lịch/lịch sử và metadata Storage.
- Ẩn bài viết/bình luận: chuyển bản gốc sang kho lưu riêng, xóa khỏi collection công khai. Stream Flutter nhận thay đổi. Khôi phục trả bản gốc về đúng đường dẫn.
- Nháp/hủy/lưu trữ sự kiện nằm ở `adminEventDrafts`; chỉ sự kiện xuất bản nằm trong `events`. Không tự tạo RSVP hoặc lịch cá nhân khi quản trị viên thao tác.
- Khóa tài khoản/thu hồi phiên/hạn chế đăng bài và gửi tin/khóa nhóm: cần deploy rules mới để áp dụng ngay trên Firestore của app. Firebase Auth cũng bị khóa/thu hồi khi chọn thao tác tương ứng.
- Ghim bài viết hiện lưu cờ quản trị; app cũ chưa ưu tiên bài ghim trong truy vấn feed.
- Tải PDF cần đúng bucket và quyền ký URL của service account chạy API. URL hết hạn sau 120 giây; không lưu URL công khai trong danh sách.

## 6. Bổ sung cấu hình từ web vào Flutter

`integration/mobile/` chứa các file thay thế được tạo từ bản app nguồn, vẫn giữ Riverpod và kiến trúc hiện có. Áp dụng có kiểm tra SHA để tránh ghi đè sửa đổi mới:

```bash
python integration/apply_mobile_bridge.py /DUONG_DAN/HobbyTracker
cd /DUONG_DAN/HobbyTracker
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=APP_VERSION=0.3.0
```

Script tạo bản `.pre-admin` của từng file. Nếu phát hiện file đã thay đổi, dừng toàn bộ trước khi ghi; hãy merge thủ công. Bridge đọc `appConfig/current` sau khi đăng nhập, ưu tiên cấu hình này so với Remote Config; làm mới mỗi phút khi app đang mở và khi quay lại app. Có gate bảo trì/phiên bản tối thiểu, banner thông báo và đóng tab Community. Gate này là điều khiển UX, không thay thế rules bảo mật. Khi mất mạng, hiển thị fallback; không tuyên bố đã đồng bộ cấu hình mới.

Bridge Flutter chưa được chạy analyzer/test/Android build trong môi trường hiện tại vì không có Flutter/Android SDK. Phải chạy các lệnh trên trên máy Android Studio trước khi phát hành APK. Các bài test Emulator chỉ chứng minh API/rules, không thay thế kiểm thử Flutter.

`mobileApi` đã có endpoint dùng Firebase ID token:

- POST `/reports`: `{title,targetType,targetPath,description}`.
- POST `/tickets`: `{subject,body}`.
- GET `/tickets/ID`: chỉ chủ ticket được đọc; loại ghi chú nội bộ.

Đường dẫn đối tượng: `posts/ID`, `posts/ID/comments/ID`, `groups/ID`, `events/ID`, `users/UID`, `directChats/ID/messages/ID` hoặc `groupChats/ID/messages/ID`. Mỗi tài khoản tối đa 10 báo cáo/ticket mỗi giờ. Cần thêm nút/bộ form tương ứng vào app để người dùng tự gửi; bridge kèm theo mới tích hợp phần cấu hình, chưa bổ sung các màn hình này. Nội dung CMS cũng cần màn hình tiêu thụ trên mobile.

## 7. Thông báo FCM

App cần đăng ký token vào `users/{uid}/devices` và lưu lựa chọn nhận tại `users/{uid}/settings/preferences`, đúng schema app hiện có. Web soạn nháp, chọn đối tượng, nhập deep link trong whitelist và lý do trước khi gửi. Máy chủ kiểm tra từng lựa chọn nhận, token, tài khoản và ghi delivery để chống gửi lại. “Đã gửi” nghĩa là FCM chấp nhận yêu cầu, không phải thiết bị nhận/đọc.

Giới hạn hiện tại: 1.000 tài khoản đối tượng, 10 thiết bị mỗi tài khoản, 10 chiến dịch theo lịch mỗi lần chạy. Quét RSVP có giới hạn 1.000 tài liệu; nếu vượt, máy chủ dừng và yêu cầu chia nhỏ. Khi lỗi sau khi đã gửi một phần, không tự thử lại để tránh thông báo trùng; đối chiếu `adminDeliveries` trước khi xử lý thủ công. Chưa có nút gửi thử riêng.

Sau khi kiểm thử thông báo trên thiết bị thật, có thể triển khai lịch:

```bash
npx --prefix functions firebase deploy --project PROJECT_ID --only functions:hobby-admin:adminCampaignScheduler
```

Lịch chạy mỗi 5 phút, cần composite index `status + scheduledAt` trong gói indexes. Không triển khai lịch thì nhãn Scheduled chỉ lưu lịch chờ, không có worker tự gửi; giao diện phải được đối chiếu với Functions đã deploy.

## 8. Điều kiện nghiệm thu trên project thật

Chưa đánh dấu PASS kết nối cloud. Chủ project cần xác nhận: tài khoản đúng quyền, người thường bị từ chối API, bài/bình luận ẩn biến mất trên điện thoại rồi khôi phục được, bản nháp sự kiện không xuất hiện, RSVP độc lập với Add to Home, rules hạn chế có hiệu lực, thay cấu hình hiện trên app sau refresh, PDF chỉ tải theo quyền, và thông báo thật tôn trọng opt-in. MFA yêu cầu cấu hình Identity Platform và luồng đăng nhập/enrollment bổ sung; không bật `REQUIRE_ADMIN_MFA=true` trước khi có luồng MFA phù hợp.
