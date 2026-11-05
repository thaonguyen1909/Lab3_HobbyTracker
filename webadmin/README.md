# Hobby Tracker Admin

Máy hiện tại đã cấu hình Firebase thật và màn hình đăng nhập quản trị. Xem [chạy local Firebase](docs/CHAY_LOCAL_FIREBASE.md) để chạy frontend cùng Admin API. Không cần nhập service account vào trình duyệt.

Web quản trị tiếng Việt cho app Flutter Hobby Tracker PRM393. Màu và Inter được lấy trực tiếp từ app, kèm 7 theme. Có bản xem trước tách biệt và Firebase Admin API chạy riêng qua Cloud Functions. Không có khóa quản trị Firebase trong trình duyệt.

Bắt đầu bằng [hướng dẫn kết nối Firebase và app](docs/KET_NOI_FIREBASE_VA_APP.md), sau đó xem [phạm vi triển khai](docs/PHAM_VI_VA_NGHIEM_THU.md). Đây là bản có thể chạy và tích hợp; chưa phải nghiệm thu 100% mọi yêu cầu trong prompt hoặc Firebase thật.

## Chạy frontend

Yêu cầu Node >=22.13.0; dùng Node 22 để khớp backend.

```bash
corepack enable
pnpm install
pnpm dev --host 0.0.0.0
```

Nếu chạy trong môi trường Sites đã cấu hình, dùng `npm run install:ci` rồi `npm run dev`. Gói source giữ các script Sites để build/publish đúng cấu hình. Không chạy `npm install` ở root vì frontend dùng `pnpm-lock.yaml`; `functions/` có lockfile npm riêng.

## Chạy kiểm thử API / Rules

```bash
npm --prefix functions ci
npx --prefix functions firebase emulators:exec --project demo-hobby-admin --only auth,firestore "node --test --test-concurrency=1 functions/test/*.test.mjs"
```

Không dùng project Firebase thật để chạy các bài test này. Kiểm thử xóa dữ liệu của project demo trong Emulator và dùng FCM mock; không gửi push thật.

```bash
node node_modules/typescript/bin/tsc --noEmit
npm run build
```

## Cấu trúc

- `app/admin/`: giao diện, bảng, form, drawer, cấu hình và theme.
- `lib/admin/`: metadata module, quyền, gateway demo/Firebase và fixtures.
- `functions/src/`: API kiểm tra token/quyền, CRUD, audit, FCM và mobile support API.
- `functions/test/`: kiểm thử nghiệp vụ, API, rules mới và hồi quy nghiệp vụ app cũ.
- `integration/firebase/`: rules/indexes tích hợp app hiện có.
- `integration/mobile/`: bridge Flutter tùy chọn, áp dụng bằng script kiểm tra SHA.
- `docs/`: hướng dẫn và tình trạng nghiệm thu thực tế.

Không thay đổi Design System hoặc kiến trúc MVVM/Riverpod của project Flutter gốc. Bridge được giao riêng để áp dụng sau khi đối chiếu và chạy Flutter checks.

## Bản mã nguồn gọn 06/11/2026

Đã gỡ bộ UI mẫu, D1/Drizzle, ví dụ và các thư viện không được dùng. Xem [danh sách dọn mã nguồn và công dụng các thư mục còn lại](docs/DON_DEP_MA_NGUON.md).
