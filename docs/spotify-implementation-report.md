# Cấu hình Spotify — 05/11/2026

PHASE: 04 | Spotify extension theo yêu cầu người dùng

STATUS: PARTIAL — code/setup và local verification đã làm; chưa nghiệm thu OAuth/âm thanh trên thiết bị thật.

SCOPE: Kết nối Spotify Android qua App Remote chính thức, OAuth PKCE/Web API đọc playlist cá nhân/followed, pagination, dán link/URI, metadata, previous/pause/resume/next, reconnect theo lifecycle và ngắt kết nối. Giữ timer/notes/history và external shortcuts; không thêm backend/billing/Firebase Rules. Không tuyên bố Spotify streaming engine được nhúng trong Flutter.

CHANGED FILES:

- `lib/models/spotify_music.dart`: typed config/model, token memory-only, strict playlist parser.
- `lib/services/spotify_music.dart`, `spotify_session.dart`, `spotify_adapters.dart`: interface/session/PKCE/HTTP/native/preferences.
- `lib/viewmodels/spotify_controller.dart`: Riverpod owner-scoped state, loading/errors, commands and stale result guards.
- `lib/features/practice/screens/spotify_panel.dart`, `practice_screens.dart`, `lib/l10n/messages.dart`: panel/picker/link dialog/en-vi.
- `android/app/build.gradle.kts`, `AndroidManifest.xml`, `MainActivity.kt`, `SpotifyRemoteBridge.kt`, `android/app/libs/`: SDK, callback, lifecycle and bridge.
- `pubspec.yaml`/lock: AppAuth dependency pin. `test/spotify_test.dart`, `spotify_api_test.dart`, `spotify_ui_test.dart`: 30 feature tests.
- `docs/spotify-setup.md`, this report, traceability/architecture/decisions/README/AGENTS: approved user extension and manual gates.

DESIGN TRACEABILITY: Hyper Mode/Flow 2 thêm panel và hai selection overlays, dùng shared theme/copy; không đổi bốn tab. User approval trong chat, chưa có Figma frame mới hoặc lecturer visual acceptance. Xem `design-traceability.md` và `open-decisions.md`.

ACCEPTANCE GATES:

- PASS: Full Flutter regression 196/196, sau sửa khởi tạo preferences trên host unsupported; `evidence/04/spotify/regression.log`. Lần đầu 183 PASS/13 FAIL do host test thiếu SharedPreferences platform; đã sửa trong provider, không bỏ test cũ.
- PASS: 30/30 Spotify feature tests sau hoàn thiện cuối; `evidence/04/spotify/feature-tests.log`. Bao gồm URI/host validation, missing app/cancel/retry, owner switch, stale OAuth/refresh, rotation/single-flight, retry 401 một lần, preference isolation, safe HTTP errors/pagination origin và UI.
- PASS: Render/click 360/412dp × en/vi tại 200% text, có font thật; `ui-render.log`, `vi-360-text200.png`, `en-412-text200.png` trong cùng evidence folder. Đây là fixture render, không phải screenshot phát nhạc thật. Đã xem ảnh Việt 360dp.
- PASS: `flutter analyze` không issue (`analyze.log`); sau sửa cuối, `dart analyze` các file Spotify/test cũng không issue. `dart format --output=none --set-exit-if-changed .` đạt 106 file; `git diff --check` đạt.
- PASS: Initial `flutter build apk --debug` exit 0, ~1083s; native MainActivity/SpotifyRemoteBridge compiled. Merged manifest có exact scheme/host callback, Spotify package visibility và không còn empty taskAffinity trên MainActivity.
- NOT RUN: Spotify consent/callback/playback bằng tài khoản thật; Android foreground/background, two-account isolation thật và nghe âm thanh. `adb devices -l` hiện không có thiết bị, không cài APK lên máy người dùng trong lượt này.
- NOT RUN: Truy cập Dashboard độc lập. Người dùng xác nhận đã thêm URI/package; cần đối chiếu SHA-1 và allowlist/account khi thử thật.

COMMANDS ACTUALLY RUN:

- `flutter pub get`: đạt, khóa AppAuth 12.1.0/interface 12.1.0.
- `flutter analyze`: đạt; lints curly braces ở lượt đầu đã sửa, không suppress lint.
- `flutter test --reporter expanded`: final full regression 196 PASS.
- `flutter test test/spotify_test.dart test/spotify_api_test.dart test/spotify_ui_test.dart --reporter expanded`: 30 PASS sau polish cuối.
- `flutter test test/spotify_ui_test.dart --dart-define=SPOTIFY_SCREENSHOTS=true --update-goldens --reporter expanded`: 4 PASS, font-loaded fixture renders. Thử xuất PNG thủ công đầu tiên bị chờ raster trong fake async và đã dừng; thay bằng golden mechanism chuẩn.
- `dart analyze` chín file Spotify/new tests: no issues.
- `dart format --output=none --set-exit-if-changed .`: 106 files, zero changes.
- `flutter build apk --debug`: exit 0. Build package cuối giữ `MOMENTS_API_URL` được ghi bổ sung bên dưới sau khi hoàn tất.
- `adb devices -l`: danh sách trống. `git check-ignore`: service-account/env/google-services/build logs đều ignored.

SECURITY & DATA CHECK: Không Client Secret, không token trong source/preferences/cloud/logs do app tạo. Native bridge chỉ chuyển owner/commands/metadata; HTTP chỉ fixed Spotify HTTPS origin, redirects off, giới hạn body/timeouts, safe errors. Tokens memory-only theo owner, stale result checks sau await; last playlist theo Firebase UID + Spotify ID và active-owner gate. Không đổi Rules nên không chạy lại Firebase emulator; unit checks không chứng minh hai tài khoản thật. Không chỉnh secret/IAM/billing.

OPEN DECISIONS / RISKS: Người dùng/team cần kiểm tra SHA-1 đúng máy build, allowlist và cùng tài khoản browser/Spotify; hoàn thành device checklist trong `spotify-setup.md`. Ngắt kết nối remote/timer không tự dừng nhạc Spotify. Không có bằng chứng app-wide OAuth/live playback acceptance.

COMMIT/PR/DEPLOY: NOT CREATED cho thay đổi Spotify; giữ working branch hiện tại `feat/moments-cloudinary-quick-schedule`.

READY FOR HUMAN REVIEW: YES — source/local evidence; chưa xác nhận live playback.

NEXT PHASE: NOT STARTED.

## APK bàn giao cuối

PASS: `flutter build apk --debug --dart-define=MOMENTS_API_URL=http://127.0.0.1:8787` exit 0, Gradle 35.7s. Log thật: `evidence/04/spotify/build.log`. APK: `build/app/outputs/flutter-apk/app-debug.apk`, 194,794,289 bytes, SHA-256 `a5dd1e361aa8495bb17b391e23e67909abedce3a41d872a36239ab50b86adfd6`. Bản cuối chứa các polish/generation guard đã qua 30 feature tests; giữ URL backend USB Khoảnh khắc. Không cài lên điện thoại vì ADB chưa có thiết bị. `dart format --output=none --set-exit-if-changed .` cuối đạt 106 files/zero changes; `git diff --check` exit 0.
