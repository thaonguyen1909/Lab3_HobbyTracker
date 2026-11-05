# Spotify trong Hyper Mode

[Báo cáo triển khai và bằng chứng kiểm thử](spotify-implementation-report.md). APK debug mới đã build; OAuth/phát nhạc thật cần thử khi kết nối lại điện thoại.

Người dùng yêu cầu tích hợp Spotify, cung cấp Client ID và xác nhận Premium. Đây là mở rộng Flow 2 được người dùng chấp thuận trong chat 05/11/2026; Lab 2 gốc chỉ quy định shortcut. Chưa có bằng chứng giảng viên nghiệm thu tính năng này.

## Cấu hình trong source

- Client ID công khai: `914fd3f140f04cdeb3271698c4d1cb93`, có thể ghi đè bằng `--dart-define=SPOTIFY_CLIENT_ID=...`. Không dùng Client Secret.
- Android application ID: `vn.prm393.hobbytracker`.
- Redirect URI chính xác: `vn.prm393.hobbytracker://spotify-callback`.
- Authorization Code + PKCE qua trình duyệt hệ thống bằng `flutter_appauth: 12.1.0`. Callback do AppAuth nhận, không đưa authorization code qua GoRouter.
- Scopes: `playlist-read-private`, `playlist-read-collaborative`, `user-read-private`, `app-remote-control`; không xin sửa playlist.
- App Remote điều khiển ứng dụng Spotify đã cài; Spotify phát âm thanh. Hỗ trợ playlist sở hữu/đang theo dõi, tải thêm, dán link/URI, bài trước/sau, tạm dừng/tiếp tục và phát lại lựa chọn gần nhất.
- Không tự kết nối/phát khi mở Hyper Mode. Nhạc và timer có nút riêng; Finish/pause timer không tự tắt Spotify.
- Token chỉ trong bộ nhớ phiên theo Firebase UID. Thoát Hyper Mode, đổi UID, ngắt kết nối hoặc khởi động lại cần kết nối lại. Playlist gần nhất lưu theo cả Firebase UID và Spotify user ID; không lưu token vào SharedPreferences/Firestore/Git.
- Remote ngắt khi Activity dừng, nối lại im lặng khi quay lại nếu phiên còn tồn tại. Ngắt remote không đăng xuất hoặc bảo đảm dừng nhạc trong Spotify. Muốn dừng nhạc, bấm Pause trước.

## Developer Dashboard

Người dùng đã xác nhận thêm Redirect URI và Android package; agent chưa truy cập Dashboard để kiểm chứng.

1. Trong app tương ứng Client ID, lưu URI khớp hoàn toàn; chọn Web API và Android SDK nếu Dashboard hỏi API/SDK sử dụng.
2. Thêm package và SHA-1 của **máy build APK**. Debug SHA-1 máy hiện tại: `0B:9E:88:D4:14:C1:D5:31:45:8F:1C:7D:19:8F:32:87:93:C4:FD:E3`. Máy teammate/release keystore thường khác. Lấy debug SHA-1 bằng PowerShell:

   ```powershell
   & 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
   ```

3. Development Mode: thêm email Spotify người test vào User Management nếu cần. Theo tài liệu hiện hành, app Development Mode mới giới hạn 5 người được cho phép và chủ app cần Premium; kiểm tra quota của chính app trước khi mời nhiều người. Dùng Premium khi thử phát chủ động.
4. Cài Spotify và đăng nhập trên điện thoại. Dùng cùng tài khoản Spotify trong trình duyệt OAuth và ứng dụng Spotify vì Web API và App Remote cấp quyền riêng; App Remote không cung cấp Spotify user ID để app đối chiếu hai tài khoản.

## Chạy trên điện thoại

Phải build lại vì có plugin và Android native code mới; hot reload không đủ. Dùng Flutter/Java/Android SDK đã cấu hình trước đây:

```powershell
cd D:\Ki-8\PRM393\project\Lab3\Lab3_HobbyTracker
flutter pub get
flutter devices
flutter run -d R5CY81PSMAJ --dart-define=MOMENTS_API_URL=http://127.0.0.1:8787
```

Giữ `MOMENTS_API_URL` nếu test Khoảnh khắc qua backend USB cũ; chạy backend và `adb reverse tcp:8787 tcp:8787` theo [hướng dẫn Khoảnh khắc](moments-cloudinary-run.md). Spotify dùng HTTPS Internet trực tiếp, không cần Firebase Admin key, Cloudinary secret, backend mới hoặc reverse riêng. Nếu chỉ thử Spotify có thể bỏ define này, nhưng Khoảnh khắc sẽ báo chưa cấu hình.

Vào một sở thích → Hyper Mode → Spotify → Kết nối Spotify → tự đăng nhập/cấp quyền trong trình duyệt và Spotify → chọn playlist hoặc Dán link playlist. Định dạng `https://open.spotify.com/playlist/<id>` hoặc `spotify:playlist:<id>`. Không cần gửi playlist cố định cho developer. Link rút gọn `spotify.link`, track/album và host khác bị từ chối; mở link rút gọn rồi sao chép link playlist đầy đủ từ Spotify.

## Nghiệm thu thật còn cần

- Cấp quyền/callback quay lại app, hủy rồi thử lại; playlist private/collaborative/followed, tải thêm/trống/mất mạng.
- Phát âm thanh thật, metadata, pause/resume/next/previous, reconnect sau background.
- Chưa cài Spotify, người dùng không allowlist, sai SHA-1/redirect, playlist không truy cập được: lỗi dễ hiểu, không giả thành công.
- Đổi Firebase UID khi đang cấp quyền/tải danh sách không lộ dữ liệu cũ; ngắt/kết nối để đổi Spotify account.
- Timer/notes/save history hoạt động độc lập, không duplicate activity.

Unit/widget tests không thay bằng chứng phát âm thanh, kiểm tra Dashboard hoặc test hai tài khoản thật.

## Dependency và bảo mật

App Remote AAR `0.8.0`, release `v0.8.0-appremote_v2.1.0-auth`, vendored trong `android/app/libs/`; SHA-256 `b5a6dd880eaf01f63a871cba9ef7af77c341f8a94ffc8fdf2e9021f9a9d4c198`. License repo kèm `SPOTIFY-SDK-LICENSE.txt`; sử dụng vẫn chịu điều khoản Spotify Developer. Gson `2.13.2` cho SDK; AppAuth `12.1.0` tránh tự viết OAuth/nhúng secret.

Manifest thêm visibility `com.spotify.music`, callback đúng scheme/host và bỏ `taskAffinity=""` theo hướng dẫn plugin. Không đổi route/tab/Firebase Rules. API chỉ gọi `https://api.spotify.com`, không follow redirect/pagination URL với bearer token; 401 retry một lần sau refresh, timeout/giới hạn response và lỗi không hiển thị body/token.

Nguồn chính thức: [Android SDK](https://developer.spotify.com/documentation/android/tutorials/getting-started), [SDK release](https://github.com/spotify/android-sdk/releases/tag/v0.8.0-appremote_v2.1.0-auth), [PKCE](https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow), [playlist API](https://developer.spotify.com/documentation/web-api/reference/get-a-list-of-current-users-playlists), [scopes](https://developer.spotify.com/documentation/web-api/concepts/scopes), [quota modes](https://developer.spotify.com/documentation/web-api/concepts/quota-modes), [AppAuth](https://pub.dev/packages/flutter_appauth/versions/12.1.0).
