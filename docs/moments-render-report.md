# Render Free — nhật ký triển khai demo

PHASE: 07B | Hosting Khoảnh khắc (mở rộng được người dùng yêu cầu)

STATUS: PARTIAL — cấu hình/local checks đã đạt; phải cập nhật trạng thái deploy thật bên dưới trước khi nghiệm thu.

SCOPE: Một Node Web Service Free trên Render, Firebase Auth/Firestore và Cloudinary hiện tại. Không đổi gói Firebase, tạo database/disk/worker/cron trả phí hoặc thay UI. Người dùng xác nhận Spotify đã phát thành công trong chat; đây là phản hồi người dùng, không phải bằng chứng QA độc lập.

CHANGED FILES: `render.yaml`, `functions/src/server.ts` (fallback PORT), `docs/moments-render-free.md`, README, architecture, decisions, traceability và báo cáo này. Những thay đổi Spotify đang có từ trước được giữ nguyên.

DESIGN TRACEABILITY: Không thêm màn hình hoặc đổi hành vi quyền/expiry; chỉ đổi nơi chạy API và MOMENTS_API_URL ở bản build hosted sau khi có domain thật.

ACCEPTANCE GATES:

- PASS: `npm --prefix functions run build` exit 0 bằng Node 22.23.4.
- PASS: `npm --prefix functions test` — 8 unit/media tests.
- PASS: `npm --prefix functions run test:http` — 10 HTTP/Cloudinary adapter tests bằng fixtures; không phải upload thật trên Render.
- PASS: `render.yaml` qua schema Render JSON Schema 2020-12 và guard một Web Service Free/no database/no disk/auto-deploy off. Script kiểm tra tạm ở deployment-artifacts, không thêm dependency vào package.
- PASS: `git ls-remote` xác nhận branch `feat/moments-cloudinary-quick-schedule` tại `ef708a7b09713769bf8933809fb49a09d0eef946`; source server/lockfile có trong local tracking ref tương ứng. Connector GitHub hiện trả 404/URL error; fallback Git đọc được branch.
- PASS: Render Dashboard đã đăng nhập, GitHub connected, chọn đúng repo private. Form đã chọn Free $0, Node/Singapore, branch backend/root functions/build/start/health và auto-deploy Off.
- PARTIAL: Nhập secrets trực tiếp trong Dashboard. File env tạm ignored được tạo từ cấu hình local, không in nội dung; browser upload tool từ chối workspace path nên người dùng nhập qua UI. Agent chỉ kiểm tra tên biến/có giá trị; không snapshot giá trị secret. Secret File đã có nội dung; env cần xác nhận đã Add variables.
- NOT RUN: Render Live/HTTPS health/401/authenticated photo flow/rút USB/cold start/background/ba giờ. Chưa tạo bản APK hosted khi chưa có URL thật.

COMMANDS ACTUALLY RUN: npm build/test/test:http (0), Render schema validation (0 sau khi chọn Ajv draft 2020), `git ls-remote` (0), `git diff --check` (0), git-ignore checks (env/admin/staging ignored). Không chạy lại Flutter/Android/emulator vì code app/Rules chưa đổi trong phần chuẩn bị hosting.

SECURITY & DATA CHECK: Không key trong source, YAML, Git hoặc chat; API xác thực và membership không nới lỏng. Render Secret File dùng `/etc/secrets/firebase-admin.json`; cloud env không chứa đường dẫn Windows/emulator. Không đụng các service Render khác. FCM giữ false trong lượt đầu, không claim push hoạt động.

OPEN DECISIONS / RISKS: User chấp nhận Free sleep/cold-start; worker tạm dừng khi ngủ, physical cleanup có thể muộn. Chuẩn bị không chứng minh cloud thành công. Cần domain thật và native test qua Wi-Fi/4G; file env tạm được xóa sau khi nhập thành công.

COMMIT/PR/DEPLOY: Chưa commit/push thay đổi local mới. Form deploy source GitHub tại commit ef708a7; vì source này chưa có PORT fallback, cấu hình MOMENTS_PORT=10000 để deploy không cần push Spotify. Chưa coi form là service đã tạo.

READY FOR HUMAN REVIEW: YES (cấu hình); live acceptance còn pending.

NEXT PHASE: NOT STARTED.

## Trạng thái cloud thực tế

**Live đã xác nhận.** Service `srv-dbmb8i1srm7s73fkdrk0`, deploy `dep-dbmb8ihsrm7s73fkdt60`, source commit `ef708a7b09713769bf8933809fb49a09d0eef946`. [Dashboard](https://dashboard.render.com/web/srv-dbmb8i1srm7s73fkdrk0), URL gốc `https://hobbytracker-moments-demo.onrender.com`. UI xác nhận Free $0/Node/Singapore/Auto Deploy Off. Đã sửa public env từ đường dẫn Windows/loopback sang `/etc/secrets/firebase-admin.json`, `0.0.0.0`, `10000`, thêm NODE_VERSION/NODE_ENV; các trường public đều khớp, Cloudinary keys có giá trị và Secret File có nội dung, không xuất giá trị secret. Xóa file env staging ignored sau khi service được tạo.

- PASS: public HTTPS GET `/health` trả 200, `{"status":"ok"}`.
- PASS: POST `/v1/beginGroupMomentUpload` không có token trả 401, `unauthenticated`; Cache-Control `no-store, max-age=0, private`. Không tạo ảnh/group/user test vào production.
- PASS: APK debug build với `--dart-define=MOMENTS_API_URL=https://hobbytracker-moments-demo.onrender.com`, exit 0, Gradle 57.3s. Log: `evidence/07b/render-free/apk-build.log`. SHA-256 `ad12b89f6ae1354931b06b8312ced7d00eba4e0c6dd533ccdf4d7f1ac557c048`.
- Đang cập nhật APK lên R5CY81PSMAJ. Test rút USB/ảnh thật/sleep-wake/FCM/three-hour acceptance chưa mặc định PASS; cần ghi kết quả thực tiếp theo.

Phần “chưa Live/env trống/chưa APK” ở nhật ký chuẩn bị phía trên mô tả trạng thái trước deploy; đoạn cập nhật này ưu tiên hơn cho trạng thái cloud hiện hành. Tổng nghiệm thu feature vẫn PARTIAL cho tới khi đóng các gate native/live còn lại. Chưa commit/push code local mới; deployment thật dùng source remote đã có, không tự đẩy Spotify.

## Bàn giao sau kiểm tra điện thoại

- PASS: `adb -s R5CY81PSMAJ install -r build/app/outputs/flutter-apk/app-debug.apk` → Success; mở `vn.prm393.hobbytracker/.MainActivity` bằng adb. Giữ dữ liệu app, không uninstall/reset.
- PASS: dừng đúng session backend PC do agent khởi động trước đó; kiểm tra không còn listener local 8787. Render HTTPS vẫn trả health 200 sau khi backend PC đã dừng.
- PASS (USER-REPORTED): người dùng xác nhận **“Đăng và xem ảnh thành công khi đã rút USB”** trên bản vừa cài. Đây là xác nhận thực tế của người dùng, chưa có recording/screenshot hoặc kiểm thử tự động chứng minh thao tác này.
- NOT RUN: cold start sau idle 15 phút, background FCM/hai tài khoản và chờ đủ ba giờ để nghiệm thu toàn bộ retention. FCM vẫn false trong deploy đầu; không suy từ upload thành công thành thông báo nền đã đạt.

Mục tiêu hosting demo không phụ thuộc PC/USB đã được triển khai và người dùng xác nhận luồng đăng/xem. Phase07B/toàn bộ Khoảnh khắc vẫn PARTIAL ở các gate native/retention nói trên. Service duy nhất được tạo: Web Service Free; không có nâng billing/Firebase hoặc tạo tài nguyên Render trả phí. File staging `.env.render` đã được xóa; file secret gốc và `.env.local` giữ nguyên, vẫn ignored. Không commit/push thay đổi Spotify/hosting local trong lượt này.
