# Hobby Tracker Admin

React + TypeScript, App Router (Vinext/Vite), Firebase Auth và Admin API.

## Cấu trúc

```text
webadmin/
├── src/
│   ├── app/                 # Trang, layout và CSS
│   ├── components/admin/    # Giao diện quản trị, menu nổi
│   ├── lib/                 # Dữ liệu, quyền và định dạng
│   └── server/              # Backend Firebase và package riêng
├── public/                  # Font WOFF2, hình, config Web công khai cục bộ
├── tests/                   # Unit tests, trạng thái, định dạng, thống kê
├── tools/                   # Build scripts, docs, bridge/rules và worker Sites
└── Các file cấu hình package, TypeScript, Vite, Firebase
```

`.openai/` giữ cấu hình hosting. `node_modules`, `.sites-runtime`, `.next`, `.vinext`, `.wrangler`, `dist` là thư viện/cache/build; không đưa lên GitHub. File cấu hình ngoài cùng là cần thiết. Di chuyển code vào src giúp dễ quản lý; nén font và bỏ dependency công cụ không cần cho runtime mới giúp giảm dung lượng.

## Chạy

Dùng Node 22 để khớp backend. Lần đầu cài:

```powershell
pnpm install --frozen-lockfile
npm --prefix src/server ci
```

Máy hiện tại đã có cấu hình riêng. Một lệnh chạy cả web và API:

```powershell
npm run dev
```

Mở **http://localhost:5173**. Giữ terminal chạy; Ctrl+C dừng cả hai. API ở cổng 8788.

Nếu muốn chạy riêng, mở hai terminal:

```powershell
npm run dev:web
```

```powershell
npm run api
```

Lệnh cũ `npm --prefix functions ...` được thay bằng `npm --prefix src/server ...`.

## Cấu hình riêng

- API env: `src/server/.env.local`; credential: `src/server/secrets/firebase-admin.json`.
- Frontend: `public/firebase-connection.local.json`, chỉ có Firebase Web config công khai và API URL.
- Không upload env, secrets, service account hoặc cache lên GitHub.
- Tạo lại public config khi cần: `npm run configure:local`.

## Kiểm tra

```powershell
npm test
npm run typecheck
npm run build
```

43 unit/API tests không ghi cloud. Emulator tests nằm trong `src/server/test`; Firebase CLI được dùng khi cần qua `npx firebase-tools@14.22.0`, không cài thường trực vào backend. Chạy CLI từ root để dùng `firebase.json`. Không deploy đè bộ Rules cũ khi chưa hợp nhất Khoảnh khắc theo [báo cáo đối chiếu](tools/docs/DOI_CHIEU_APP_WEB.md).

Dọn cache không sử dụng bằng `npm run clean:cache`. Font Inter dùng WOFF2, giữ đầy đủ ký tự gốc; bản TTF nguồn được cất tại tools/assets. Các tài liệu cũ trong tools/docs là lịch sử và có thể dùng đường dẫn trước khi chuyển.

Mã worker/build Sites vẫn được giữ để bảo toàn khả năng đóng gói. Chưa publish thay đổi local.
