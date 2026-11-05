# Spotify release regression — 06/11/2026

Phạm vi: sửa kết nối App Remote trong APK release; giữ nguyên Client ID,
redirect URI, package, signing certificate, Firebase và backend Render. Không
thay thiết kế Hyper Mode, token storage, playlist API hoặc timer.

## Bằng chứng nguyên nhân

Người dùng báo APK 0.3.1 hiện lỗi kết nối chung, trong khi debug trước đó phát
Spotify được. Log PID hiện tại không có lỗi App Remote chi tiết; không suy ra
SHA-1 sai chỉ từ thông báo UI.

Kiểm tra SDK AAR 0.8.0 và output R8 của bản 0.3.1:

- `SpotifyLocator.instantiatePackageProvider` dùng Class.forName, getConstructor
  không tham số và newInstance để tạo ReleaseSpotifyLocator. Nó bắt
  NoSuchMethodException và trả null; không tự in lỗi này ra log.
- Consumer ProGuard của AAR giữ tên class ReleaseSpotifyLocator nhưng không khai
  báo giữ constructor trong R8 full mode.
- R8 usage.txt liệt kê `ReleaseSpotifyLocator: public void <init>()` đã bị loại;
  mapping.txt không còn constructor. Đây là lỗi đóng gói có thể xác định độc lập
  với Dashboard. Cần kiểm tra bản sửa trên thiết bị để xác nhận kết nối thật.

Evidence: `evidence/08/spotify-release-fix/before-r8-usage.txt` và
`evidence/08/spotify-release-fix/sdk-locator-bytecode.txt` (javap từ AAR đang dùng).

## Sửa đổi

- `android/app/proguard-rules.pro`: giữ đúng public constructor không tham số
  của ReleaseSpotifyLocator. R8 vẫn bật; không keep toàn bộ SDK.
- `SpotifyRemoteBridge.kt`: dùng `is UserNotAuthorizedException` thay so sánh
  simpleName (tên có thể bị obfuscate). Log HobbySpotify chỉ ghi trạng thái kết
  nối/mã lỗi/tên lớp lỗi; không ghi exception message, stack trace hay token.

## Kiểm tra

Đã build release **0.3.2 (5)** dùng URL Render hiện tại và Firebase thật.

| Kiểm tra | Kết quả thực tế |
|---|---|
| Release build | PASS, exit 0, Gradle 263.1s |
| Constructor trong DEX | PASS, apkanalyzer: 0.3.1 không có, 0.3.2 có đúng một public no-arg constructor |
| Signature / manifest | PASS, v2 verified; signer SHA-1 giữ nguyên; version 0.3.2/code 5; debuggable=false |
| Google OAuth resource | PASS, default_web_client_id vẫn có 2 aapt entries |
| Credential archive entries | PASS, không có firebase-admin, .env, signing keystore theo kiểm tra tên entry |
| Cài/mở app | PASS, adb install -r Success; COLD start OK; giữ dữ liệu người dùng |
| Spotify native connection | PASS, log PID 28691: App Remote connected |
| Phát nhạc thật | PASS theo xác nhận người dùng: “Đã kết nối và phát nhạc được” trên APK vừa cài |
| Spotify unit/widget/API | PASS, 30 tests, exit 0 |
| flutter analyze --no-pub | PASS, No issues found, exit 0, 108.4s |
| git diff --check | PASS, exit 0 |
| Toàn bộ Khoảnh khắc/FCM/retention | NOT RUN trên APK này; không suy ra từ kiểm tra Spotify |

Lệnh build:

```powershell
flutter build apk --release --build-name=0.3.2 --build-number=5 --dart-define=MOMENTS_API_URL=https://hobbytracker-moments-demo.onrender.com --dart-define=USE_FIREBASE_EMULATORS=false
```

Evidence bổ sung: dex-comparison.txt, after-dex-constructor.txt,
device-connection.log, user-confirmation.txt, spotify-tests.log và
flutter-analyze.log trong `evidence/08/spotify-release-fix/`.
Xác nhận phát nhạc là kết quả người dùng báo; không thay bằng giả lập nghe âm thanh.

APK local (ignored):
`deployment-artifacts/team-test-20261106-spotify-fixed/HobbyTracker-0.3.2-team-release.apk`.
Kích thước 69,460,921 bytes; SHA-256:
`545a1954558c45e1254500d4609fa7ca376723940cae8b9f39b70e2b7ad46669`.
Đã xóa artifact 0.3.1 và APK build trùng sau khi người dùng xác nhận bản mới hoạt
động, theo yêu cầu trước đó chỉ giữ APK mới để tránh gửi nhầm. Log/bytecode trước
và sau sửa vẫn được giữ. Không giữ screenshot có thông tin tài khoản vào Git.

Không đổi cấu hình Spotify Dashboard, cấp thêm quyền hoặc deploy backend.
Chưa commit/push bản sửa này trong lượt chẩn đoán.

```text
PHASE: 08 | Spotify release regression fix
STATUS: PASS (scoped fix; not whole Lab 3 acceptance)
SCOPE: retain Spotify locator constructor and make native auth error classification safe under obfuscation.
CHANGED FILES: Android ProGuard rules, SpotifyRemoteBridge.kt, Spotify documentation and docs/evidence/08/spotify-release-fix/.
DESIGN TRACEABILITY: no UI or timer behavior change; existing Hyper Mode Spotify panel restored.
ACCEPTANCE GATES:
  [PASS] Final DEX constructor, release build/signature, device connect log and user-confirmed music playback.
  [PASS] 30 existing Spotify tests and Flutter analyzer.
  [NOT RUN] Full other-feature/device-matrix regression.
COMMANDS ACTUALLY RUN:
  - flutter build apk --release (flags above) -> 0
  - apkanalyzer dex code / manifest debuggable -> 0
  - apksigner verify --verbose --print-certs -> 0
  - aapt dump badging / resources -> 0
  - adb install -r / am start -W / logcat -> 0
  - flutter test --no-pub test/spotify_test.dart test/spotify_api_test.dart test/spotify_ui_test.dart --reporter expanded -> 0, 30 passed
  - flutter analyze --no-pub -> 0, no issues
  - git diff --check -> 0
SECURITY & DATA CHECK: no OAuth token logging/persistence added; no private-file APK entries by filename scan; no cloud/Rules/IAM change. Existing data preserved.
OPEN DECISIONS / RISKS: existing Render Free and FCM limitations unchanged; other features need independent release acceptance.
COMMIT/PR/DEPLOY: NOT CREATED
READY FOR HUMAN REVIEW: YES
NEXT PHASE: NOT STARTED
```
