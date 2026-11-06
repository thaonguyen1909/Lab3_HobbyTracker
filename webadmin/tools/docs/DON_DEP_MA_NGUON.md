# Dọn mã nguồn Hobby Tracker Admin — 06/11/2026

Đã kiểm tra các import từ `app/page.tsx`, giao diện admin, cấu hình Vite, Worker và script build. Có nhiều file được tạo sẵn theo bộ khung dự án nhưng giao diện admin hiện tại không dùng đến.

## Đã loại bỏ

- 77 file mã nguồn/cấu hình mẫu không được sử dụng.
- `components/`: bộ UI dựng sẵn và connector error component; admin sử dụng các component trực tiếp trong `app/admin/`.
- `hooks/`: hook kích thước mobile của bộ UI mẫu.
- `db/`, `drizzle/`, `examples/`, `drizzle.config.ts`: database D1/Drizzle và ví dụ notes; backend của admin sử dụng Firebase Firestore.
- `vendor/`, `postcss.config.mjs`: CSS Shadcn/Tailwind và cấu hình xử lý Tailwind; giao diện hiện tại dùng CSS trong `app/globals.css`.
- `components.json`, `lib/utils.ts`, `lib/connectors.ts`, `lib/connector-errors.mts`, `app/chatgpt-auth.ts`: helper/cấu hình mẫu không có đường import từ ứng dụng đang chạy.
- 23 khai báo thư viện trực tiếp không dùng, cùng script `db:generate`.
- Bỏ quy tắc ESLint dành riêng cho các component mẫu đã xóa và bỏ `examples` khỏi danh sách loại trừ TypeScript.
- Cập nhật lại lockfile pnpm tương ứng.

## Các thư mục vẫn cần

| Thư mục / file | Công dụng |
|---|---|
| `app/` | Trang web, component admin và CSS giao diện |
| `lib/admin/` | Gateway demo/Firebase, metadata màn hình, bảng màu và quyền |
| `lib/connector-context.ts`, `lib/connector-contract.mts`, `lib/connector-preview.d.ts` | Thành phần được Worker và cấu hình môi trường hiện tại import |
| `public/` | Font, icon và tài nguyên tĩnh |
| `functions/` | API Firebase, thông báo, phân quyền, bootstrap admin và kiểm thử |
| `integration/` | Rules/indexes và bridge để kết nối Flutter với cấu hình admin |
| `docs/` | Hướng dẫn kết nối, kết quả kiểm tra và giới hạn triển khai |
| `scripts/` | Cài dependency, chạy dev, build và hỗ trợ môi trường hosting |
| `worker/` | Điểm vào phục vụ web trên hosting hiện tại |
| `.openai/hosting.json` | Nhận diện và cấu hình triển khai website hiện tại |
| `vite.config.ts`, `next.config.ts`, `tsconfig.json` | Cấu hình framework và TypeScript |
| `package.json`, `pnpm-lock.yaml`, `pnpm-workspace.yaml` | Dependency và phiên bản frontend |

`node_modules/`, `dist/`, `.next/`, `.vinext/`, `.wrangler/`, `tsconfig.tsbuildinfo` và các file log là dữ liệu cài đặt/build/cache có thể tạo lại. Chúng được loại khỏi Git và ZIP giao mã nguồn. Trên máy của bạn, khi cần giải phóng dung lượng có thể xóa chúng rồi cài/build lại; đóng server dev trước khi xóa thư mục đang được sử dụng.

## Cách dùng bản gọn

Giải nén ZIP mới vào thư mục mới. Giữ lại file cấu hình Firebase và biến môi trường riêng của bạn nếu đã thiết lập. Làm theo README và `KET_NOI_FIREBASE_VA_APP.md` để chạy và kết nối project.

Bản trước vẫn có trong lịch sử Git và ZIP trước đó. Phạm vi tính năng, tình trạng Firebase thật và các mục chưa nghiệm thu vẫn theo `PHAM_VI_VA_NGHIEM_THU.md`.

## Kết quả kiểm tra sau khi dọn

- Cài dependency từ lockfile ở chế độ frozen: PASS.
- TypeScript `tsc --noEmit`: PASS.
- Build production Vinext/Workers: PASS.
- Không còn import vào các thư mục UI/D1/Drizzle/helper đã xóa từ các entrypoint đang dùng.
- Bộ backend Firebase, rules và bridge Flutter được giữ nguyên; 59 bài test trước đó là bằng chứng của phiên bản backend trước, không phải lượt chạy mới trong đợt dọn frontend này.

Đợt dọn này không bổ sung nghiệm thu Firebase cloud hay Android; các giới hạn đã báo trước vẫn còn hiệu lực.
