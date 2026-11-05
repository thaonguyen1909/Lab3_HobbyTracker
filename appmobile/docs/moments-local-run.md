# Chạy thử Khoảnh khắc — bước 2

> **Lưu ý 04/11/2026:** đây là hướng chạy emulator của kiến trúc cũ. Người dùng đã chốt Node.js riêng + Cloudinary để thử Firebase thật qua USB; dùng [hướng dẫn mới](moments-cloudinary-run.md). Bản local emulator dưới đây vẫn phục vụ test hồi quy, không chứng minh Cloudinary thật.

Đây là chế độ phát triển Android **debug**, dùng Auth/Firestore/Storage/Functions Emulator trong project `demo-hobbytracker-moments`. Bản app mặc định vẫn dùng Firebase thật. Backend khoảnh khắc chưa được deploy lên cloud; chỉ chạy `flutter run` mặc định chưa đủ để thử tính năng này.

## 1. Chuẩn bị trên Windows

Cần Flutter của dự án, Android SDK, Node **22**, Java **21**, Firebase CLI và điện thoại bật USB debugging. Giữ cấu hình Android Firebase hiện có của dự án (`android/app/google-services.json`, không commit lên Git); named app demo dùng options riêng nhưng phần khởi tạo native/default device SDK vẫn cần cấu hình Android hợp lệ. Không cần bật billing để chạy emulator. Mở PowerShell tại repository:

```powershell
cd D:\Ki-8\PRM393\project\Lab3\Lab3_HobbyTracker
$env:Path = 'D:\Ki-8\PRM393\flutter\bin;D:\Ki-8\PRM393\androidsdk\platform-tools;' + $env:Path
$env:ANDROID_HOME = 'D:\Ki-8\PRM393\androidsdk'
node --version
java -version
firebase --version
flutter pub get
npm.cmd --prefix functions ci
```

`node --version` phải bắt đầu bằng `v22`. Nếu máy đang chọn Node 24, chọn lại bản Node 22 trong PATH hoặc trình quản lý Node trước khi chạy script. Không đổi runtime Functions thành Node 24 chỉ để bỏ qua kiểm tra. Dependencies được khóa trong lockfile; không chạy `npm update` cho bước này.

## 2. Mở backend local — cửa sổ PowerShell A

```powershell
.\scripts\start-moments-emulators.ps1
```

Giữ cửa sổ này chạy. Script build TypeScript rồi khởi động bốn emulator, không deploy. Chờ dòng `All emulators ready`. Giao diện quản lý local: [Emulator UI](http://127.0.0.1:4000). Cổng: Auth 9099, Firestore 8080, Storage 9199, Functions 5001. Nếu cổng đang bận bởi bộ test, dừng bộ test hoặc emulator trước; không chạy hai bộ trên cùng cổng.

Dữ liệu local mặc định mất khi dừng emulator. Tài khoản email/password trong emulator tách biệt tài khoản Firebase thật. Google Sign-In, FCM/push, Analytics, Crashlytics và Remote Config cloud được ngăn sử dụng trong chế độ local; app hiện nhãn **LOCAL EMULATORS**. Không dùng tài khoản/mật khẩu thật cho dữ liệu thử.

## 3. Kết nối và chạy app — cửa sổ PowerShell B

Áp dụng phần PATH/ANDROID_HOME ở bước 1 cho cửa sổ B, sau đó:

```powershell
adb devices -l
# Thay DEVICE_ID bằng ID có trạng thái device, ví dụ R5CY81PSMAJ.
$momentDevice = 'DEVICE_ID'
adb -s $momentDevice reverse tcp:9099 tcp:9099
adb -s $momentDevice reverse tcp:8080 tcp:8080
adb -s $momentDevice reverse tcp:9199 tcp:9199
adb -s $momentDevice reverse tcp:5001 tcp:5001
flutter run -d $momentDevice --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

Chấp nhận hộp thoại USB debugging trên điện thoại. Nếu danh sách trống, kiểm tra cáp/chế độ USB trước. `adb reverse` cần chạy lại sau khi rút cáp hoặc khởi động lại máy. Nếu dùng Android Emulator thay điện thoại, dùng `FIREBASE_EMULATOR_HOST=10.0.2.2`; không cần `adb reverse`. Chế độ emulator bị từ chối trong release build và không nhận hostname cloud.

Khi trở lại Firebase thật, thoát lượt `flutter run` hiện tại rồi chạy `flutter run -d $momentDevice` **không có hai dart-define**. Cần khởi chạy lại toàn bộ, không chỉ hot reload. Việc quay lại project thật không deploy backend khoảnh khắc.

## 4. Kịch bản thử A/B/C

1. Register A bằng email/password thử. Tạo hobby Cầu lông, Active hoặc Interested đều được. Tạo nhóm Cầu lông và tham gia nhóm.
2. Community → **Moments / Khoảnh khắc** → chọn nhóm → **Share a moment / Chia sẻ khoảnh khắc**. Chụp ảnh hoặc chọn ảnh, chọn hobby, nhập caption tùy chọn, tối đa 160 Unicode code points; ảnh JPEG/PNG/WebP sau xử lý picker tối đa 5 MB.
3. Đăng. Quan sát progress/xử lý, quay lại danh sách, mở ảnh và đếm ngược. Thời hạn do backend đặt là đúng 10.800 giây từ publish, không tính từ lúc chọn ảnh.
4. Dùng máy thứ hai hoặc logout rồi Register B trong cùng bộ emulator. B tham gia cùng nhóm và refresh Khoảnh khắc, mở ảnh A. B không có nút thu hồi ảnh của A.
5. C chưa tham gia nhóm không được truy cập. Có thể dùng Emulator UI để xem ID phục vụ kiểm tra, nhưng không sửa quyền trực tiếp để giả lập một luồng UI thành công.
6. A mở lại ảnh → **Remove moment / Thu hồi khoảnh khắc** → xác nhận. B mở lại/refresh phải thấy không còn khả dụng. Ảnh đã hiện không có subscription thu hồi tức thời ở bước 2; quyền được kiểm tra lại mỗi lần tải và khi app trở lại foreground.
7. Hủy picker giữ ảnh cũ; tắt mạng lúc upload rồi Retry; caption/hobby giữ nguyên. Không nhận được kết quả publish thì Retry cùng bản nháp để tránh đăng hai lần. Không đóng màn hình hoặc đổi nội dung khi kết quả còn chưa rõ.
8. Chờ đủ ba giờ để xác nhận thực tế. Các test tự động chỉ tiến đồng hồ test tới ranh giới; không phải bằng chứng đã chờ đủ ba giờ trên điện thoại. Không sửa đồng hồ điện thoại để giả lập backend hết hạn.

Camera/gallery, hai tài khoản trên thiết bị, offline và một phiên đủ ba giờ còn cần thực hiện bằng máy thật. Lượt `adb devices -l` lúc triển khai bước 2 không có thiết bị kết nối.

## Bản nháp và giới hạn hiện tại

- Caption/hobby/request ID lưu theo UID và nhóm trên máy. Ảnh chọn và ảnh xem được giữ trong bộ nhớ, không lưu bytes vào SharedPreferences hay cấp URL download dài hạn. Image Picker/Android có thể tạo file tạm riêng; app không cam kết xóa mọi bản sao của hệ điều hành.
- Khi đóng hẳn app/màn đăng, cần chọn ảnh lại. Có xử lý `retrieveLostData` nếu Android hủy activity trong lúc picker; chỉ khôi phục cho đúng UID. Ticket upload/trạng thái publish chưa được lưu bền vững qua process restart: retry chống trùng được kiểm thử trong màn đăng đang mở, không hứa phục hồi giao dịch sau mọi lần kill app.
- Ảnh xem bị ẩn khi hết hạn; đồng hồ dựa thời gian server + Stopwatch, không dựa giờ thiết bị. Khi background, state ảnh được bỏ và khi resume tải lại quyền. Không có khả năng thu hồi screenshot/bản sao đã tải hay bảo đảm xóa OS snapshot.
- Danh sách tải 6 mục/lần; bấm refresh/load more để nhận bài mới. Bước 3 bổ sung popup qua reference inbox và source push/Android worker. Bước 4 đã thêm source cleanup định kỳ và công cụ local bên dưới; scheduler cloud chưa deploy. Quan hệ kết bạn chưa có.
- Session upload có hạn 10 phút. Khi backend xác nhận session hết hạn, app giữ ảnh/text và lần Retry tiếp theo tạo session mới. Timeout chưa rõ kết quả publish tiếp tục dùng cùng request, không được tự đổi nội dung. Quota backend có thể yêu cầu đợi trước khi thử lại.

## Đọc log

### Cleanup bước 4 trên emulator

Giữ cửa sổ A chạy emulator. Ở một cửa sổ PowerShell khác tại root repo, chọn Node 22 trong PATH như phần chuẩn bị rồi chạy:

```powershell
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
$env:FIREBASE_STORAGE_EMULATOR_HOST = '127.0.0.1:9199'
npm.cmd --prefix functions run build
# Preview: chỉ đọc một mẫu tối đa 10 metadata hết hạn, không sửa/xóa dữ liệu.
npm.cmd --prefix functions run cleanup:local
# Thực hiện một lượt cleanup có giới hạn trên demo-hobbytracker-moments.
npm.cmd --prefix functions run cleanup:local -- --run
```

Tool cố định project/bucket demo và từ chối host không phải loopback; không nhận project/path tùy ý. JSON mode=run trả số mục đã xử lý/errors/busy. Nếu busy=true, đang có lease; đợi lượt sau. errors>0 giữ pending/cursor để thử lại. Khi có backlog, có thể cần nhiều lượt; mỗi mục lỗi được lùi khoảng năm phút.

`cleanupExpiredMoments` có source lịch năm phút nhưng scheduled functions không tự chạy trong bộ emulator hiện dùng. Dùng CLI trên để diễn tập; chưa có job chạy trên Firebase cloud. Giữ tombstone chống tái sử dụng ID; không dùng việc dọn thành công để suy ra đã xóa vĩnh viễn mọi bản sao/ảnh trong máy người nhận.

[Báo cáo cleanup và bằng chứng](moments-cleanup-step4-report.md) · [kịch bản demo/kiểm tra thật](moments-demo-acceptance.md).

### Thử popup/inbox của bước 3 trước khi dùng FCM thật

1. Khởi động emulator bằng script mới (đã tăng Functions discovery timeout lên 60 giây). Cần thấy `deliverGroupMoment` được nạp như Firestore trigger. `retryMomentDeliveries` là scheduled function, không tự chạy trong bộ emulator hiện dùng.
2. B đăng nhập, tham gia nhóm → Community → Khoảnh khắc → **Thông báo khoảnh khắc** → bật **Nhận thông báo khoảnh khắc**. Bật trước khi A đăng bài mới; ảnh đã đăng trước đó không được phát thông báo lại do chỉ đổi setting.
3. A đăng ảnh mới vào đúng nhóm. Khi B đang mở app, inbox được backend emulator ghi thật và app kiểm tra quyền/tải thumbnail rồi hiện popup. Dùng hai thiết bị hoặc hai phiên app đăng nhập riêng để thử cùng lúc; logout A→B trên một máy chỉ kiểm tra inbox khi đăng nhập lại.
4. B đang chạy Hyper: app giữ mục chờ, không tự chuyển trang hoặc mở popup. Pause/Finish rồi mới xem; thử mute nhóm/tắt Groups chung và đăng ảnh mới để kiểm tra không nhận alert.
5. Local không gửi FCM thật, không tạo background worker cloud và nút xin FCM báo dịch vụ không khả dụng. Việc popup local hoạt động không chứng minh push nền/cold-start/lockscreen hoạt động. Các ca này cần backend cloud đã được duyệt/deploy và hai điện thoại thật.

[Báo cáo bước 3](moments-alerts-step3-report.md) ghi rõ bằng chứng, hạn chế và phần nghiệm thu còn lại.

### Thu thập log thiết bị

Terminal `flutter run` hiển thị lỗi Flutter/plugin; cửa sổ A hiển thị Functions/Rules/emulator. Để lưu log thiết bị ở cửa sổ khác:

```powershell
flutter logs -d $momentDevice | Tee-Object -FilePath moment-device.log
```

Chỉ chia sẻ phần lỗi liên quan, che email/UID/token và không đăng log thô có thông tin cá nhân lên repository. Nếu app báo dịch vụ chưa khả dụng, kiểm tra nhãn LOCAL, bốn emulator, ADB reverse và port trước; không tự bật billing hoặc deploy để chữa lỗi local.
