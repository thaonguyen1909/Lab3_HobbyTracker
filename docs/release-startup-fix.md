# Sửa APK release 0.3.0 — 06/11/2026

Phạm vi: sửa đóng gói Android release cho APK test nhóm; giữ nguyên giao diện,
Firebase project, backend Render và dữ liệu người dùng. Không thay IAM, billing,
Rules hoặc bật FCM. Đây là kiểm tra phát hành thuộc phase 08, không nghiệm thu
toàn bộ Lab 3.

## Nguyên nhân và thay đổi

APK 0.3.0 (3) build thành công nhưng hiển thị “Firebase is not connected”.
Đã cài lại APK đó trên SM S721B (R5CY81PSMAJ) để lấy log thực tế. ComponentDiscovery
báo `NoSuchMethodException: <init> []` cho các Firebase registrars, trong đó có
CrashlyticsRegistrar. R8 usage output liệt kê constructor bị loại bỏ. Native
FirebaseInitProvider vẫn báo khởi tạo FirebaseApp thành công: thông báo chung
trên UI không xác định đúng lỗi thành phần và không chứng minh thiếu JSON/IAM.

- `android/app/proguard-rules.pro`: giữ class và public no-arg constructor của
  các lớp implements ComponentRegistrar để Firebase discovery gọi qua reflection.
  Giữ ba dontwarn cụ thể cho optional Jackson bases/annotation trong Spotify SDK
  đã được missing_rules.txt của R8 chỉ ra. Không dùng ignorewarnings toàn cục.
- `android/app/src/main/res/raw/vn_prm393_hobbytracker_keep.xml`: giữ
  `default_web_client_id`. Debug APK có resource này nhưng release cũ không có;
  GoogleSignInPlugin 6.2.1 tra resource bằng getIdentifier theo tên.
  Cách giữ resource theo [Android Developers](https://developer.android.com/topic/performance/app-optimization/customize-which-resources-to-keep).
- Code/resource shrinking vẫn bật. Flutter Gradle plugin tự nạp file
  app/proguard-rules.pro khi file tồn tại; không thêm Gradle classpath trùng lặp.

## Evidence

- Log trước sửa: `evidence/08/release-startup-fix/before-registrars.log`.
- Ảnh lỗi người dùng cung cấp: `evidence/08/release-startup-fix/user-startup-error.png`.
- Bản thử giữ registrars đã build và cài được, versionName 0.3.1/versionCode 4;
  log báo FirebaseApp và Firebase Crashlytics khởi tạo thành công, không còn
  cảnh báo thiếu constructor trong log PID mới. Chưa dùng log này để kết luận
  toàn bộ giao diện/đăng nhập đã đạt.

APK 0.3.0 ban đầu được rút khỏi phân phối và đổi đuôi `.apk.rejected`.
Sau đó, theo yêu cầu người dùng, đã xóa thư mục artifact 0.3.0 cùng các APK
debug/release build trùng trong build/app/outputs. Chỉ giữ một APK để gửi nhóm
ở deployment-artifacts/team-test-20261106-fixed, kèm checksum và hướng dẫn.
Các file source, cấu hình private và evidence log trước/sau sửa vẫn được giữ.

## Kiểm tra cuối

Đã build lại **0.3.1 (4)** có cả hai quy tắc giữ code/resource. Kết quả thực tế:

| Kiểm tra | Kết quả / bằng chứng |
|---|---|
| Release build | PASS — exit 0, Gradle 171.4s; log trong thư mục artifact bên dưới |
| APK signature / manifest | PASS — v2 verified, debuggable=false, package vn.prm393.hobbytracker, versionCode 4, versionName 0.3.1 |
| Resource Google OAuth | PASS — aapt tìm được 2 entries default_web_client_id trong APK cuối |
| Private-file entries | PASS — không có firebase-admin, .env, signing keystore theo kiểm tra tên entry của ZIP |
| Cài thiết bị | PASS — adb install -r Success trên SM S721B, giữ dữ liệu |
| Khởi động lại | PASS — lần mở lại COLD, Activity OK; ảnh quan sát được Trang chủ có phiên đăng nhập, không còn màn lỗi Firebase |
| Native startup | PASS — PID 14946 khởi tạo FirebaseApp/Crashlytics; 0 dòng lỗi registrar, NoSuchMethodException, FATAL EXCEPTION, Unhandled Exception trong log PID lúc kiểm tra |
| XML / whitespace | PASS — parse XML thành công; git diff --check exit 0 |
| Các flow còn lại trên APK cuối | NOT RUN — upload/xem/expiry Khoảnh khắc, Spotify playback, FCM hai máy |

Artifact local (ignored):
`deployment-artifacts/team-test-20261106-fixed/HobbyTracker-0.3.1-team-release.apk`.
Kích thước 69,460,921 bytes; universal arm64-v8a/armeabi-v7a/x86_64;
min SDK 24/target 36. SHA-256:
`4a9c63d2b33cbb0b1d0cf31a39de5d8d1c351cc3ffb76e74a8be2541bb49f19f`.
Signer SHA-1 giữ nguyên:
`0B:9E:88:D4:14:C1:D5:31:45:8F:1C:7D:19:8F:32:87:93:C4:FD:E3`.
Đây vẫn là khóa debug dùng cho nhóm test, chưa phải signing cửa hàng.

Log lọc sau sửa: `evidence/08/release-startup-fix/after-registrars.log`.
Ảnh Trang chủ được giữ **local ignored** tại thư mục artifact (`device-home.png`)
vì có tên hiển thị tài khoản; không đưa ảnh này vào Git. Không tự chọn tài khoản
hoặc nhập thông tin đăng nhập của người dùng.

Lệnh build:

```powershell
flutter build apk --release --build-name=0.3.1 --build-number=4 --dart-define=MOMENTS_API_URL=https://hobbytracker-moments-demo.onrender.com --dart-define=USE_FIREBASE_EMULATORS=false
```

Không sửa Dart/business logic; unit/widget tests không phát hiện được việc R8
loại constructor trong APK. Kiểm tra trọng tâm là release build và thiết bị thật.
FCM nền, hai thiết bị, Spotify OAuth/playback và retention đủ ba giờ cần được
kiểm tra riêng; không suy ra PASS từ việc app mở được.

Lượt build không tạo commit/push/PR/deploy. Người dùng sau đó yêu cầu commit,
push lên feat/moments-cloudinary-quick-schedule và merge main nếu không conflict.
Nội dung gửi Git chỉ gồm quy tắc giữ code/resource, báo cáo và evidence đã lọc;
APK/secret vẫn ignored. Không triển khai cloud trong lượt đồng bộ Git này.

## Báo cáo phạm vi nghiệm thu

```text
PHASE: 08 | Release APK startup regression fix
STATUS: PASS (scoped startup/packaging fix only; not whole Lab 3 acceptance)
SCOPE: R8 Firebase registrar constructors and Google OAuth resource retention.
CHANGED FILES: android/app/proguard-rules.pro; android/app/src/main/res/raw/vn_prm393_hobbytracker_keep.xml; this report; filtered logs and original error screenshot under docs/evidence/08/release-startup-fix/.
DESIGN TRACEABILITY: no UI/design change; Login and Home startup restored; docs/design-traceability.md remains applicable.
ACCEPTANCE GATES:
  [PASS] Final release build, signature/resources and actual device Home startup.
  [NOT RUN] Full feature acceptance on final release APK.
COMMANDS ACTUALLY RUN:
  - flutter build apk --release (full command above) -> 0
  - apksigner verify --verbose --print-certs -> 0, v2 verified
  - aapt dump badging / dump resources -> 0
  - apkanalyzer manifest debuggable -> 0, false
  - adb install -r -> 0, Success
  - adb shell am force-stop / am start -W -> 0, COLD/OK
  - adb logcat -d --pid=14946 -> 0, filtered startup evidence saved
  - git diff --check -> 0
SECURITY & DATA CHECK: no credentials/cloud/Rules change; no private-file archive entries by filename scan; existing app data preserved. Rules emulator tests not applicable to packaging-only change.
OPEN DECISIONS / RISKS: release functional tests still needed for Moments/Spotify/FCM; Render Free limitations unchanged.
COMMIT/PR/DEPLOY: build task did not create any; subsequent user-authorized Git synchronization is tracked in branch history. No cloud deploy.
READY FOR HUMAN REVIEW: YES
NEXT PHASE: NOT STARTED
```
