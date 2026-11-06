> Cấu trúc đã đổi: dùng hướng dẫn chạy hiện tại trong [README](../../README.md). Backend là src/server; scripts/docs/integration nằm dưới tools.

# Chạy web và Android với Firebase thật — 06/11/2026

Project chung: `hobbytracker-6ace6`. Web app `Hobby Tracker Admin Web` đã được đăng ký trong project. Super Admin đầu tiên đã được cấp cho email người dùng chỉ định trong chat; không lưu mật khẩu trong source.

## File cấu hình

- Android: `../Lab3_HobbyTracker-main/android/app/google-services.json`.
- Backend Khoảnh khắc: `../Lab3_HobbyTracker-main/functions/.env.local`, credential tại `../Lab3_HobbyTracker-main/secrets/firebase-admin.json`. Đường dẫn credential trong env được sửa tương đối với thư mục functions.
- Admin API: `functions/.env.local`, credential tại `functions/secrets/firebase-admin.json`.
- Frontend: `public/firebase-connection.local.json` chỉ chứa Firebase Web config công khai và URL API loopback. Không có service account/private key. Tất cả file cấu hình riêng được ignore; Vite chặn truy cập thư mục secrets.

Hai file service account được cung cấp có cùng SHA-256; chúng là hai bản của cùng một khóa, không phải hai project.

## Chạy lại

Từ thư mục webadmin, dùng hai terminal:

```powershell
npm --prefix functions run start:live
```

```powershell
pnpm dev
```

Mở `http://localhost:5173`. Firebase Auth đã cho phép cả localhost và 127.0.0.1 cho Google Sign-In (cập nhật 06/11/2026). Web hiện màn hình đăng nhập quản trị, phục hồi phiên Firebase hợp lệ khi tải lại, và quay lại đăng nhập khi đăng xuất. Có thể dùng Google hoặc email/password tương ứng provider của tài khoản. Máy chủ vẫn kiểm tra custom claim và `adminStaff` trước mọi truy cập dữ liệu. API tại `http://127.0.0.1:8788` kết nối Firebase thật, chỉ bind loopback; không chạy scheduler hoặc gửi FCM ở chế độ này.

Từ thư mục app:

```powershell
flutter run -d emulator-5554 --dart-define=MOMENTS_API_URL=https://hobbytracker-moments-demo.onrender.com
```

Khoảnh khắc trong app giữ URL Render đang dùng. Backend Khoảnh khắc local đã được đặt cấu hình và build/test, chưa cần chạy song song với Render. Nếu chủ động chạy local, thực hiện `npm run start:api` từ functions của app và dùng URL phù hợp thiết bị; không chạy thêm worker cùng production nếu chưa định kiểm tra việc đó.

## Kết quả kiểm tra thực tế

- Android build/install thành công; Pixel 9 hiển thị Home của tài khoản đang đăng nhập, không còn màn hình thiếu Firebase.
- Admin API `/health`: HTTP 200; `/me` không token: 401; origin frontend được phép: 200.
- Firebase Management API đọc được bằng credential; config Web đã tạo từ API chính thức. Firestore đọc được collection adminStaff; bootstrap admin thành công.
- Khóa máy chủ và env qua frontend trả HTTP 403; trang và public config trả 200. Active Super Admin count sau bootstrap: 1.
- Frontend TypeScript và build thành công. Backend Khoảnh khắc build, 8 unit tests và 10 HTTP/media tests thành công.
- Chưa nghiệm thu đăng nhập web bằng người dùng và đối chiếu CRUD giữa hai giao diện; người dùng cần tự đăng nhập bằng tài khoản đã cấp quyền.
- Bridge `integration/mobile/` chưa áp dụng: script phát hiện source khác baseline và dừng trước khi ghi. Dữ liệu nghiệp vụ dùng chung Firestore qua Admin API; các tính năng cấu hình quản trị `appConfig/current`, reports/tickets/CMS vẫn còn bước tích hợp mobile và rules riêng. Không deploy rules/Functions trong lượt này.

Node trên máy là 24.14.1; scripts hiện chạy được nhưng package khai báo Node 22. Dùng Node 22 khi deploy theo cấu hình dự án.
