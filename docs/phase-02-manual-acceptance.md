> Historical Phase02 handoff. Superseded by docs/full-implementation-report.md and docs/full-manual-checklist.md for the integrated 00–08 source.

# Phase 02 — Việc chủ dự án cần thực hiện (03/11/2026)

Phase 02 chưa PASS. Các bước bên dưới cần môi trường và tài khoản của chủ dự án. Không cần gửi mật khẩu, service-account JSON, khóa ký hoặc khóa API mô hình vào chat.

## 1. Android và Firebase

1. Cài Android SDK/Android Studio; chạy `flutter doctor -v`. Dùng Flutter stable; phiên bản đã kiểm tra tại Work được ghi trong báo cáo và `docs/evidence/02/work-review-2026-11-03/flutter-version.log`.
2. Chốt application ID Android lâu dài; ZIP chưa chứa `android/` vì chưa có ID được chủ dự án xác nhận. Chạy `scripts/setup_phase02_windows.ps1 -Org "com.yourcompany"` với namespace thực của bạn. Không dùng nguyên placeholder này.
3. Chọn/tạo Firebase project của bạn; đăng ký Android app có application ID khớp Gradle. Bật Google và Email/Password trong Authentication, chọn support email.
4. Chạy `.\gradlew signingReport` trong `android/`; thêm SHA-1 và SHA-256 của bản debug vào Firebase. Bản release dùng dấu vân tay của khóa ký tương ứng.
5. Chạy `flutterfire configure --platforms=android`, kiểm tra `android/app/google-services.json` và plugin Google Services trong Gradle. Mã hiện dùng `Firebase.initializeApp()` native Android; không tự đặt ID/credentials giả. Nếu chuyển sang generated options, dùng file `firebase_options.dart` do CLI sinh và cấu hình `DefaultFirebaseOptions.currentPlatform`.
6. Tạo Cloud Firestore, chọn vùng dữ liệu; review `firebase/firestore.rules`. Chỉ deploy sau khi kiểm tra đúng project và chủ dự án duyệt. Test emulator không deploy rules lên cloud. Rules hiện chỉ cho hồ sơ chủ tài khoản; hobbies/chat vẫn bị chặn cho tới phase tương ứng.
7. Kiểm tra INTERNET permission trong `android/app/src/main/AndroidManifest.xml` nếu build bản release; template Flutter có thể chỉ cấp quyền trong debug/profile.
8. Chạy `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, rồi `flutter run` trên máy ảo có Google Play hoặc thiết bị Android phù hợp.

## 2. Bằng chứng chức năng thật để đóng Phase 02

Dùng ít nhất hai tài khoản test riêng (A/B). Ghi phiên bản app, thiết bị, thời điểm và kết quả từng ca; không gửi thông tin xác thực.

| Ca | Thao tác | Kết quả cần chứng minh |
|---|---|---|
| AUTH-01 | Signed out; mở link `/hobbies` và back | Chỉ Login, không lộ màn/dữ liệu riêng |
| AUTH-02 | Google picker → hủy; sau đó chọn account A | Hủy có thông báo; đăng nhập vào Home; Console Users có UID A |
| AUTH-03 | Đăng ký email; đăng xuất; đăng nhập lại | Tài khoản thật, lỗi nhập liệu giữ draft; không lưu password vào Firestore |
| AUTH-04 | Forgot Password | Request thật; nhận email và hoàn tất đổi mật khẩu bằng hộp thư test |
| AUTH-05 | Settings → Sign Out → Hủy / Xác nhận; mở lại app | Hủy giữ phiên; xác nhận về Login và không phục hồi dữ liệu A |
| AUTH-06 | Mất mạng hoặc rules deny khi bootstrap profile; thử lại | Error/retry hoặc timeout có phục hồi; không vào Home khi hồ sơ chưa hợp lệ |
| AUTH-07 | Đăng xuất/đổi tài khoản khi hồ sơ A đang chậm; đăng nhập B | Kết quả muộn của A không mở app hoặc ghi lỗi lên phiên B |
| AUTH-08 | Google/password cùng email; liên kết có xác nhận | Không tự gộp UID; provider đúng; khác email bị chặn; account conflict có hướng dẫn |
| AUTH-09 | Hồ sơ `users/{uid}` trên Console, thử A/B | A đọc/sửa tên của A; B không đọc/ghi A; không list profiles, nâng role hoặc lưu password |
| AUTH-10 | Cold start với phiên đã đăng nhập và phiên signed out | Route đúng, hồ sơ không tạo lặp và không ghi đè role hiện có |

Ảnh trước/sau đăng nhập, Console Authentication Users và hồ sơ Firestore cần khớp cùng UID (có thể che email). Lưu log/ảnh thực, không dùng ảnh Phase01 cũ làm bằng chứng Phase02.

## 3. Figma / nguồn Lab 2

- Đường dẫn: https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=0-1
- Lần đọc qua kết nối Figma tại Work ngày 03/11/2026 bị trả lỗi không có quyền Editor. Chủ file cần cấp quyền cho tài khoản Figma đang kết nối, hoặc cung cấp exports được duyệt (Login 7:8, Register 7:52, Forgot 7:101, Settings 9:1114 và các error/loading states).
- Review giao diện Android ở 360dp và 412dp với bản Figma chính thức; các widget tests chỉ chứng minh render/behavior trong harness, không chứng minh pixel parity trên thiết bị.
- Source đã bổ sung Tên hiển thị ở Register theo handoff, với validation 2–80 ký tự và ghi tên vào Firebase Auth/Firestore. Vẫn cần đối chiếu form trên Android với Figma chính thức.
- D01: nối/duyệt các flow và recovery trong Figma; xác nhận với giảng viên nếu dùng HTML thay bằng chứng formal Lab 2.
- D05: đối chiếu lại 3 HTML với nguồn gốc. Không thay hash lịch sử để biến sai lệch thành PASS.

## 4. Khi nào tiếp tục Phase 03

Chỉ sau khi kiểm tra trên Android/Firebase thật, review form Register và UI đủ bằng chứng. Yêu cầu hiện tại đã cho phép tiếp tục Phase03 sau khi Phase02 hoàn thành; không cần hỏi lại chỉ để xin bắt đầu. Hiện chưa đạt điều kiện nên Phase03 NOT STARTED. Khi mở Phase03: đọc `docs/requirements/prompts/03-flow1-hobbies.md`, giữ UID isolation, validate tên/priority/trùng tên, transaction uniqueness, form draft/retry và kiểm thử hai tài khoản.
