# Bước 3 — Popup và thông báo Khoảnh khắc

Ngày 04/11/2026. Người dùng yêu cầu triển khai bước 3 sau UI bước 2. **Source đã triển khai; kiểm thử local đạt, chưa nghiệm thu FCM trên thiết bị/cloud.** Không deploy, bật billing, commit hoặc push trong bước này. Đây là mở rộng Community/FCM của Lab 3, không bổ sung yêu cầu Final.

## Hành vi đã viết

- Publish transaction tạo `momentOutbox/{momentId}` cùng metadata ảnh. Firestore trigger fan-out từng trang 20 thành viên; loại tác giả, kiểm tra membership, opt-in, mute và tùy chọn Groups chung. Inbox chỉ lưu ID tham chiếu/hạn dùng/read; không chứa ảnh, caption hay tên người đăng.
- Data-only FCM chứa ownerId/eventId/groupId/momentId/expiresAt, TTL bằng thời gian còn lại. Delivery và thiết bị gửi xong được ghi nhận; scheduler chạy lại công việc còn hạn, xử lý token không còn hợp lệ. ID ổn định và client dedupe giảm trùng; không cam kết exactly-once sau mọi lỗi mạng.
- App nghe inbox và FCM, xác minh quyền rồi mới tải thumbnail qua callable riêng tư. Popup có ảnh hoặc text fallback đã kiểm tra metadata/quyền; tự đóng sau tối đa 6 giây hoặc khi ảnh hết hạn. Đổi UID/background bỏ popup và bytes; response cũ không được hiện dưới tài khoản mới.
- Hyper đang chạy: không mở popup hay tự điều hướng khỏi luyện tập, chỉ giữ mục để xem sau và hiện nhãn chờ. Pause/Finish mới cho popup; inbox vẫn là lối truy cập thủ công. Notification tap vào moment cũng được chặn điều hướng nếu Hyper đang chạy.
- Community → Khoảnh khắc → **Thông báo khoảnh khắc**: opt-in mặc định tắt, preview màn hình khóa mặc định tắt, tắt theo nhóm, nút xin quyền Android và inbox tham chiếu. Tắt thông báo không chặn việc tự xem danh sách ảnh nhóm.
- Android background handler chỉ enqueue WorkManager. Worker kiểm tra UID, tùy chọn, quyền và hạn trên server; tải thumbnail private vào bộ nhớ, recheck rồi hiện Big Picture/text fallback có timeout. Tap notification local mở đúng viewer, kể cả khởi động lạnh. Mỗi lần mở ảnh vẫn kiểm tra backend.
- Notification IDs tách riêng với reminders. Đồng bộ lịch chỉ hủy reminder có payload đúng, không dùng cancelAll. Logout chủ động hủy notification/work của UID cũ; đổi setting/mute dọn thông báo liên quan theo khả năng xử lý của thiết bị.

## Files thay đổi ở bước 3

| Nhóm | Files |
|---|---|
| Backend | functions/src/moment_delivery.ts; moments.ts; index.ts; test/delivery.test.mjs; package.json |
| Rules/index | firebase/firestore.rules, firestore.indexes.json |
| Model/state/contracts | lib/models/moment_alert.dart; viewmodels/moment_alert_controller.dart; services/moment_alert_repository.dart, moment_alert_providers.dart |
| Adapters/Android | lib/firebase/firebase_moment_alert_repository.dart, moment_background.dart, notification_background.dart, firebase_device_services.dart; services/moment_local_notifications.dart, local_reminders.dart |
| UI/runtime | moment_alert_overlay.dart, moment_alerts_screen.dart, moments_screen.dart; app.dart, main.dart, app/router/*, runtime_controller.dart, l10n/messages.dart |
| Dependency/build | pubspec.yaml/lock, android/build.gradle.kts |
| Tests/tooling/docs | test/moment_alert_controller_test.dart, moment_alerts_ui_test.dart, support/moment_alert_fakes.dart; hai script emulator; tài liệu liên quan và evidence |

Thêm **workmanager 0.9.0+3**, phù hợp minimum Flutter 3.35 hiện có. Lock chọn workmanager_android 0.9.3. Module này bỏ Kotlin plugin khi thấy AGP 9 nhưng dự án đang `android.builtInKotlin=false`: lần build đầu thiếu WorkmanagerPlugin. Đã bổ sung workaround chỉ cho module workmanager_android, dùng Kotlin plugin hiện có và JVM target 1.8; không sửa Pub cache. Cảnh báo Flutter về việc dùng KGP ở phiên bản tương lai vẫn còn; không nâng toàn bộ toolchain trong bước này.

WorkManager bản đang dùng không có getForegroundInfoAsync cho expedited trên Android trước API 31. Chỉ yêu cầu expedited khi OS version báo rõ API ≥31; bản cũ/không xác định dùng regular work. Hết quota được hạ xuống regular. Chưa đo latency nền và hành vi OEM trên máy thật.

## Bằng chứng thực tế

| Kiểm tra | Kết quả | Evidence |
|---|---|---|
| Resolve dependency | PASS | flutter pub get, exit 0, 4 package Workmanager được khóa |
| Backend strict TypeScript | PASS | Lệnh build trong [emulator-tests-final.log](evidence/05/moments-alerts/emulator-tests-final.log) |
| Backend unit/image | PASS, 8/8 | [backend-unit-tests.log](evidence/05/moments-alerts/backend-unit-tests.log) |
| Rules hồi quy | PASS, 35/35 | [emulator-tests-final.log](evidence/05/moments-alerts/emulator-tests-final.log) |
| Moment + delivery integration | PASS, 30/30 | Cùng log; 17 ca cũ + 13 ca delivery mới, gồm quyền inbox/settings, opt-out/mute, pagination, TTL, retry, token hỏng và real callable HTTP |
| Flutter unit/widget | PASS, 137/137 | [flutter-tests.log](evidence/05/moments-alerts/flutter-tests.log), exit 0; thêm 12 controller/namespace và 6 UI tests |
| UI | PASS ở mức widget | 360/412dp × Anh/Việt, popup→viewer, mark read, mute, Hyper giữ running/route, wrong-owner và 200% text |
| Analyze cuối | PASS | [analyze-final.log](evidence/05/moments-alerts/analyze-final.log): No issues found, exit 0 |
| Format | PASS | dart format lib test: 88 files, 0 changed; kiểm tra không đổi source ở lượt cuối |
| Android debug APK | PASS | [android-build-final.log](evidence/05/moments-alerts/android-build-final.log); build/app/outputs/flutter-apk/app-debug.apk |
| ADB | Không có thiết bị | [adb-devices.log](evidence/05/moments-alerts/adb-devices.log); exit 0, danh sách trống |
| Hai điện thoại/FCM/background/lockscreen thực | NOT RUN | Chưa có hai thiết bị và backend chưa deploy |
| Scheduler cloud/phiên đủ ba giờ | NOT RUN | Scheduler không tự chạy trong bộ emulator hiện dùng; retryDue được gọi trực tiếp trong integration tests |

Tổng backend **73/73 = 8 + 35 + 30**. Emulator không có FCM: sender cloud bị vô hiệu hóa rõ ràng; inbox được ghi thật trong demo Firestore. Payload/send assertions dùng sender inject chỉ trong test, không phải bằng chứng Google FCM đã giao đến máy.

Giữ log lỗi ban đầu: Functions discovery vượt 10 giây làm HTTP test cuối lỗi dù 29/30 integration đã đạt; tăng discovery timeout lên 60 giây trong script và chạy lại đạt 30/30, có trigger thực được nạp. UI đầu lỗi Tooltip ở ngoài Navigator Overlay; sửa nút đóng có semantic label và kiểm tra lại. Ca Hyper còn timer lúc kết thúc test được sửa cleanup; app controller vẫn hủy timer khi dispose.

## Cách thử

Theo [hướng dẫn local](moments-local-run.md), mở emulator bằng script cập nhật và chạy debug local. B phải tham gia nhóm và **bật Moment alerts trước khi A đăng bài mới**; bài cũ không được fan-out lại chỉ vì đổi setting. Local nhận popup qua inbox Firestore thật, không dùng FCM giả. Tài khoản local dùng email/password; nút xin FCM trên local báo dịch vụ không khả dụng.

Trước nghiệm thu cloud, owner review Functions/Rules/index và điều kiện hạ tầng rồi mới cho phép deploy riêng. Sau đó cần hai điện thoại A/B và tài khoản C ngoài nhóm: foreground, background, app đóng bình thường, khóa màn hình, từ chối quyền, mute/tắt Groups, logout A→B, ảnh hết hạn/thu hồi, Hyper đang chạy và chỉnh đồng hồ máy. Không dùng một test pass local để thay các ca này.

## Hạn chế và việc còn lại

- Chưa deploy/billing/push thật; chưa xác nhận worker, cold-start tap và private preview trên Android thật. Force stop/OS giới hạn nền có thể trì hoãn hoặc ngăn giao message; không hứa push tức thời.
- Khi resume, app chỉ hiển thị lại popup sau kiểm tra quyền; inbox giữ tối đa 50 tham chiếu gần nhất, kể cả mục hết hạn để mở trạng thái không còn khả dụng. Tham chiếu không chứa nội dung ảnh. Nhãn unread là số tham chiếu chưa đọc, không phải số ảnh chắc chắn còn xem được.
- Preview false dùng Android PRIVATE, true dùng PUBLIC theo opt-in. Android/thiết lập màn hình khóa của người dùng quyết định redaction cuối; không tuyên bố đã kiểm chứng trên thiết bị. Ảnh trong notification thuộc OS và có timeout, không thể thu hồi mọi screenshot/bản sao.
- Dedupe foreground/background dùng UID/event và ID notification ổn định; SharedPreferences không phải distributed lock giữa hai isolate, nên có thể còn race tạo banner/notification khi đổi trạng thái app. onlyAlertOnce/unique work giảm lặp, không phải exactly-once.
- Fan-out giới hạn 20 thành viên/trang, 10 token/UID; scheduler xử lý tối đa 10 job/lượt. Phải đo tải/latency và review quota trước mở rộng. Backend/worker kiểm tra lại membership/setting trước gửi/tải nhưng không thu hồi ảnh đã được OS render ở máy khác tức thời.
- Cleanup ảnh/staging/outbox/inbox và local seen/index định kỳ chưa có; vẫn thuộc bước sau. Friendship chưa có. Sáu cảnh báo npm moderate và audit endpoint ECONNRESET ghi ở bước 1 vẫn chưa đóng; App Check chưa enforce.

## Báo cáo theo repository

```text
PHASE: 05 | Moments step 3 — popup and notification source
STATUS: PARTIAL
SCOPE: Outbox/fan-out, private reference inbox, opt-in/mute, foreground popup/Hyper defer, Android worker/local notification source; no cloud deployment
CHANGED FILES: See file table above
DESIGN TRACEABILITY: docs/design-traceability.md — Moments alerts step 3
ACCEPTANCE GATES:
  [PASS] 137 Flutter tests
  [PASS] 73 backend/Rules/emulator tests, including real callable and Firestore trigger loading
  [PASS] Android emulator-mode debug APK
  [PASS] Analyze clean, format, Markdown local links, PowerShell syntax and git diff --check
  [NOT RUN] Real FCM, two devices, worker/lockscreen/cold-start notification acceptance, three-hour real-time session
COMMANDS ACTUALLY RUN:
  - flutter pub get -> 0
  - dart format --output=none --set-exit-if-changed lib test -> 0
  - flutter analyze -> 0, No issues found
  - npm --prefix functions test -> 0, 8/8
  - scripts/test-moments-emulators.ps1 (Node 22, discovery timeout 60s) -> 0, 35/35 + 30/30
  - flutter test --no-pub --concurrency=1 --reporter expanded -> 0, 137/137
  - flutter build apk --debug --no-pub --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1 -> final 0
  - adb devices -l -> 0, no devices
SECURITY & DATA CHECK: Wrong owner/member/expiry denied; no image URLs/PII in FCM; inbox reference-only; media authorization unchanged
OPEN DECISIONS / RISKS: Cloud/device acceptance, OS delivery limits, cleanup/retention and existing dependency audit
COMMIT/PR/DEPLOY: NOT CREATED
READY FOR HUMAN REVIEW: YES
NEXT PHASE: NOT STARTED
```

Tham khảo API chính thức: [FCM Flutter receive](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages), [Android message priority](https://firebase.google.com/docs/cloud-messaging/android-message-priority), [Workmanager 0.9.0+3](https://pub.dev/packages/workmanager/versions/0.9.0+3), [flutter_local_notifications 19.0.0](https://pub.dev/packages/flutter_local_notifications/versions/19.0.0). Khác biệt expedited được xác minh thêm từ source package Android đã resolve, không suy từ API latest có tham số khác.
