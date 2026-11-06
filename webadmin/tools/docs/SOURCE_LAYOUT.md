# Gom source và giảm dung lượng — 06/11/2026

Đã chuyển app sang src/app, component sang src/components/admin, mã dùng chung sang src/lib và package backend sang src/server. Tools chứa scripts/docs/integration/worker. Các unit tests chung nằm ở tests; API/emulator tests còn trong src/server/test để dùng dependencies backend. Hosting manifest .openai/hosting.json và project ID giữ nguyên.

Đã sửa imports, alias @, đường dẫn worker, scripts, Firebase source/rules, public config generator, test imports, gitignore và env loader. Env cùng secrets đi theo backend, không chuyển vào public. Vite chặn env/secrets; Firebase source ignore cũng loại secrets/env khỏi gói deploy. Không đổi dữ liệu cloud hoặc source Flutter.

Một lệnh npm run dev chạy cả frontend (5173) và API (8788). npm run dev:web / npm run api để chạy riêng. Các lệnh cũ dùng functions phải đổi thành src/server; README hiện tại là hướng dẫn chính thức.

## Dung lượng

| Thành phần | Trước | Sau |
|---|---:|---:|
| Cache .sites-runtime | 1.611,2 MB | 731,5 MB |
| Package backend gồm thư viện | 360,4 MB | 176,7 MB |
| Font trình duyệt | 876.576 byte TTF | 350.572 byte WOFF2 |

Kích thước là tổng file logic, không phải đo block ổ đĩa. Cache và pnpm hard link có thể khiến số đo logic khác dung lượng vật lý. Không hứa cache sẽ không tăng lại khi cài/build.

- Dọn cache bằng pnpm store prune; không xóa node_modules đang cần để chạy.
- Bỏ firebase-tools khỏi backend devDependencies; gỡ 529 packages, giữ firebase-admin/Firebase SDK/Express/Zod và bộ unit test. Khi cần emulator hoặc deploy, gọi npx firebase-tools@14.22.0 từ root; không tự deploy.
- Font WOFF2 giảm khoảng 60%; đã so sánh toàn bộ character map với TTF gốc. TTF gốc được giữ ở tools/assets, ngoài public/build client, kèm bản quyền gốc trong public/fonts.
- Giữ bộ công cụ Vinext/Vite/Sites hiện có; đổi stack không nằm trong lần gom source này.

## Kiểm tra

43 tests, TypeScript noEmit và build đạt sau chuyển. npm run dev khởi động được cả hai dịch vụ. Web và API health HTTP 200; font WOFF2 HTTP 200; src/server/.env.local và src/server/secrets/firebase-admin.json trả 403 qua frontend. Firebase CLI emulator tests không chạy trong lần tái cấu trúc này. Chưa publish/deploy.
