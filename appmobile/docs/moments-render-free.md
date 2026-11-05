# Khoảnh khắc qua Wi-Fi/4G — Render Free

**Service đã Live:** [hobbytracker-moments-demo.onrender.com](https://hobbytracker-moments-demo.onrender.com/health). [Dashboard](https://dashboard.render.com/web/srv-dbmb8i1srm7s73fkdrk0), deploy `dep-dbmb8ihsrm7s73fkdt60`, source `ef708a7b09713769bf8933809fb49a09d0eef946`. HTTPS health đã trả 200 và endpoint thiếu token trả 401. Xem trạng thái kiểm tra điện thoại tại [báo cáo](moments-render-report.md).

APK dùng URL hosted đã được cài lên R5CY81PSMAJ. Backend PC đã dừng, người dùng xác nhận đăng/xem ảnh thành công khi rút USB. Không cần chạy lại script local cho bản app này. Các lần build sau vẫn cần truyền đúng MOMENTS_API_URL theo lệnh bên dưới.

Ngày 05/11/2026, người dùng chọn **Render Free để demo trước, chưa trả phí**. Giữ Firebase Auth/Firestore và Cloudinary; chỉ chuyển Node API từ PC lên Render. Chưa coi file cấu hình là bằng chứng đã deploy.

## Giới hạn đã chấp nhận

Free web service ngủ sau 15 phút không nhận traffic; lần gọi tiếp theo có thể mất khoảng một phút để khởi động. App hiện có connection timeout ngắn hơn thời gian cold start: trước buổi demo, mở URL `/health` trên trình duyệt và chờ `{"status":"ok"}`, rồi đăng ảnh. Nếu lượt đầu timeout, chờ backend thức và dùng Thử đăng lại. Không tự retry thao tác publish khi chưa biết kết quả.

Trong lúc service ngủ, process timer/outbox/cleanup ngừng. API vẫn kiểm tra expiry từ server khi xử lý yêu cầu; ảnh hết hạn không được tải mới dù file vật lý chưa dọn. Xóa ảnh Cloudinary vật lý là job riêng, chạy theo chu kỳ 5 phút/có retry khi backend hoạt động. Free demo không bảo đảm push nền/xóa file liên tục hoặc xóa vật lý đúng giây thứ 10.800. Không dùng ping tự động để né giới hạn ngủ của gói Free.

Không tạo Render database, disk, paid worker/cron hoặc nâng Firebase. Dữ liệu vẫn ở Firestore/Cloudinary, không lưu ảnh bền vững trên filesystem Render. Theo dõi quota của cả ba dịch vụ; không giả định miễn phí vô hạn.

## Tạo Web Service

Service hiện tại được tạo bằng form New → Web Service. `render.yaml` là cấu hình để review/tái lập, chưa được áp dụng làm Blueprint quản lý service này; không tạo thêm bản demo trùng chỉ để dùng YAML. Khi tạo service mới từ Blueprint, file phải có trên branch GitHub đã chọn. Với form thủ công, có thể deploy source backend đã push trước đây mà không cần đẩy cả thay đổi Spotify còn local; đặt `MOMENTS_PORT=10000` cho phiên bản chưa đọc `PORT`.

| Trường | Giá trị |
| --- | --- |
| Repository | `thaonguyen1909/Lab3_HobbyTracker` |
| Branch | `feat/moments-cloudinary-quick-schedule` — phải kiểm tra remote có `functions/src/server.ts` và lockfile |
| Name | `hobbytracker-moments-demo` hoặc tên còn trống |
| Region | Singapore |
| Runtime | Node |
| Root Directory | `functions` |
| Build Command | `npm ci --include=dev && npm run build` |
| Start Command | `node lib/server.js` |
| Compute plan | **Free** |
| Health Check Path | `/health` |
| Auto Deploy | Off, deploy thủ công sau khi review |

Start command không dùng `npm run start:api` vì script local đó cần `.env.local`. Render nhận biến môi trường từ Dashboard. Pin Node 22; không dùng default Node 24. Build cần devDependencies để có TypeScript compiler; `--include=dev` giữ compiler dù NODE_ENV=production.

## Environment và Secret File

Đặt các giá trị sau trong Render Environment; không copy nguyên `.env.local` chứa đường dẫn Windows.

| Biến | Giá trị |
| --- | --- |
| `NODE_VERSION` | `22.23.4` |
| `NODE_ENV` | `production` |
| `GOOGLE_CLOUD_PROJECT` | `hobbytracker-6ace6` |
| `GOOGLE_APPLICATION_CREDENTIALS` | `/etc/secrets/firebase-admin.json` |
| `MOMENTS_BIND` | `0.0.0.0` |
| `PORT` | Render cấp tự động; code mới đọc khi không có MOMENTS_PORT |
| `MOMENTS_PORT` | `10000` cho source cũ; với source mới có thể bỏ để dùng PORT |
| `MOMENTS_ENABLE_FCM` | `false` trong lần deploy đầu; chỉ bật khi thực hiện test push riêng |
| `CLOUDINARY_CLOUD_NAME` | Cloud name hiện tại |
| `CLOUDINARY_API_KEY` | Nhập riêng từ cấu hình local |
| `CLOUDINARY_API_SECRET` | Nhập riêng từ cấu hình local |

Advanced/Environment → Secret Files → thêm file tên **`firebase-admin.json`**, nội dung từ file local `secrets/firebase-admin.json`. Người dùng nhập trực tiếp trong Dashboard; không gửi nội dung vào chat/Git/screenshot. File được mount tại `/etc/secrets/firebase-admin.json`. Không đưa JSON này vào Android assets hoặc dart-define. Nếu dùng Blueprint, thêm Secret File thủ công; lần deploy trước khi có file sẽ thất bại và cần deploy lại sau khi lưu.

Không cấu hình `USE_FIREBASE_EMULATORS`, `FIRESTORE_EMULATOR_HOST`, `FIREBASE_AUTH_EMULATOR_HOST`, `FUNCTIONS_EMULATOR` hoặc `FIREBASE_STORAGE_EMULATOR_HOST` trên Render. Giữ service account đã được cấp quyền tối thiểu phù hợp, không mở Rules hoặc cấp Owner để chữa lỗi.

## URL HTTPS và app

Sau deploy **Live**, lấy URL thật hiển thị trong Render Dashboard; tên service chỉ là đề xuất, chưa bảo đảm domain còn trống. Kiểm tra:

1. `GET https://<domain-thật>/health` → 200, `{"status":"ok"}`. Health chỉ chứng minh process HTTP, chưa chứng minh Firebase/Cloudinary.
2. POST endpoint Khoảnh khắc không token → 401; không được mở endpoint để vượt xác thực.
3. Dùng URL gốc, không thêm `/v1` hoặc `/health` vào MOMENTS_API_URL. Cài lại app vì dart-define không đổi qua hot reload.

```powershell
$momentsHostedUrl = 'https://hobbytracker-moments-demo.onrender.com'
flutter run -d R5CY81PSMAJ --dart-define="MOMENTS_API_URL=$momentsHostedUrl"
```

Lần cài APK qua USB vẫn cần cáp; sau đó rút cáp, mở lại app bằng biểu tượng, dùng Wi-Fi/4G. Không cần backend PC/adb reverse cho bản hosted. Không dùng URL placeholder để build APK bàn giao; chưa có domain thì chưa tạo bản hosted.

Nếu cần quay lại test local, chạy backend cũ, reverse 8787 và build với `MOMENTS_API_URL=http://127.0.0.1:8787`. Không đổi URL mặc định của mọi teammate một cách âm thầm.

## Nghiệm thu demo

- Upload/chọn nhóm/hobby hợp lệ, ảnh hiển thị trên hai thiết bị qua Internet, rút cáp và tắt backend PC.
- Quyền thành viên, logout A → B, mất mạng, upload retry/thu hồi và hết hạn vẫn đúng.
- Bật push là bước test riêng: FCM mặc định false, thông báo background chưa được chứng minh chỉ bằng upload thành công.
- Chờ sleep/wake và thử lại; không báo Free demo thành always-on production.
- Trong lần deploy hosted thành công, dừng backend PC trước khi thử push/cleanup cloud để tránh hai process cùng poll outbox/cleanup không cần thiết.

Nguồn đã kiểm tra: [Render Free](https://render.com/docs/free), [Web Service/PORT/HTTPS](https://render.com/docs/web-services), [Secret Files](https://render.com/docs/configure-environment-variables), [Node version](https://render.com/docs/node-version), [Blueprint](https://render.com/docs/blueprint-spec).
