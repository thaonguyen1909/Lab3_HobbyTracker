# Checklist duy nhất để đóng toàn bộ Phase00–08

Không xin chuyển từng phase. Các mục này là đầu vào/bằng chứng còn thiếu cho bản tích hợp.

## Android + Firebase

- Cài Android Studio/SDK/Google Play emulator. Chạy flutter doctor -v. Native folder đã có; không chạy bootstrap cũ để ghi đè.
- Android application ID/namespace: vn.prm393.hobbytracker. Đăng ký chính xác ID này trong Firebase hoặc sửa có chủ đích trước khi đăng ký.
- Bật Google, Email/Password, support email. Lấy SHA bằng android/gradlew signingReport, thêm SHA-1/SHA-256 vào Firebase.
- Chạy FlutterFire configure, kiểm tra android/app/google-services.json. main dùng Firebase.initializeApp() native. Nếu dùng generated Dart options, import file CLI sinh và truyền DefaultFirebaseOptions.currentPlatform.
- Review đúng project, vùng Firestore và điều kiện Storage. Owner tự duyệt trước deploy rules. Không tự mở if true hoặc bật billing. Có thể dùng Emulator Suite trước.
- flutter pub get; flutter analyze; flutter test; flutter build apk --debug; flutter run. Nếu có lỗi Gradle/plugin, lưu nguyên log để sửa; APK chưa được build ở Work.

## Chạy xuyên suốt với hai test accounts

A tạo hobby, thử thiếu tên/priority/trùng tên, sửa icon/màu/priority, relaunch. Lên lịch cho cả Active/Interested, đổi priority và kiểm tra lịch còn. Hyper start/pause/wait/resume/reset/notes/Finish/double tap, offline retry, background, kill/relaunch và đổi UID. History chỉ có một record/session. Xóa hobby giữ history và gỡ lịch khỏi UI.

A/B opt-in công khai và DM trong Privacy. Publish/like/comment, create/join group, group chat, direct chat A→B. Account không thuộc chat phải bị deny. Tạo event/RSVP: trước Add to Home không có lịch; Add đúng một lịch; cancel RSVP gỡ lịch liên kết.

Settings profile/apps/notification/hyper/privacy/7 themes phải lưu qua relaunch. Kiểm tra ở 360dp/412dp, bàn phím và font scale. So sánh với Figma có quyền hoặc export được duyệt. Kiểm tra contrast/hit target trên device; widget renders không chứng nhận WCAG.

## Sáu dịch vụ và evidence

- Auth: Google picker/cancel/email/register/reset nhận mail/logout/restart, Console Users/Firestore profile khớp UID.
- Storage: tạo PDF đúng số record/phút/notes, share sheet cancel, upload progress/URL, Console file đúng reports/{uid}, account B bị deny.
- FCM: xin quyền Android13+, Console/test sender gửi ownerId và path trong custom data. Test foreground/background/terminated và inbox/deep link. Gửi generic content, không PII. Với opt-out category cần sender respect prefs, đặc biệt notification payload do OS tự hiển thị; data-only behavior cần test riêng.
- Reminders: bật quyền trước, tạo plan, kiểm tra thông báo inexact có thể bị OS trì hoãn, boot/restart/timezone/pause/sound. Weekly summary là lần kế tiếp được lập lại khi app đồng bộ, chưa có server scheduler.
- Analytics: DebugView từng event ở analytics-plan.md; user ID đúng sau login, không name/email/notes/content/URL.
- Crashlytics: gây lỗi có thật (offline/denied) và xác nhận nonfatal; intentional crash chỉ debug define + nhập CRASH + confirm, chụp dashboard khi relaunch.
- Remote Config: community_enabled false và feed_limit 5; reload trong Profile demo, mở Community thấy thay đổi; bật lại, mất mạng dùng defaults có notice.

## Phase08 / hồ sơ nộp

Cài ARTEMIS host theo e2e_test/README.md, Python3.12+, ADB và model key môi trường. Chạy 17 ca ×3, so sánh field quan sát với expected, lưu/redact traces. Pro exploration 15–30 phút, lập issues/flaky report. Thêm PR review tool/5 findings/ít nhất3 fix commits trong repo thật, StudentID và quyền giảng viên. PDF kỹ thuật/outline hiện tại cần cập nhật evidence rồi mới dựng slide final 12–15 trang và video live 5–10 phút. Không dùng ảnh test fixtures làm video hoặc proof cloud.

D01/D05: cấp Figma permission và xử lý provenance 3 HTML; không sửa hash lịch sử để che sai lệch. Lab3 cloud upload vẫn bắt buộc dù Final có scope khác.
