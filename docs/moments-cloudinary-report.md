# Chuyển Khoảnh khắc sang Cloudinary + Node.js riêng

> Kết quả mới nhất: [retest 04/11/2026 sau IAM](moments-retest-report.md) — deploy Firestore đã thành công, Rules khớp local/indexes READY, backend 8787 chạy, APK mới đã cài/mở và quan sát ảnh thật trên danh sách điện thoại. Không còn bị chặn serviceusage.services.use; tổng trạng thái PARTIAL vì nghiệm thu push nền/hai máy/ba giờ thực tế còn lại. Các ghi chú BLOCKED phía dưới là lịch sử.

Ngày 04/11/2026. **STATUS: PARTIAL — source/local checks đạt; chưa upload provider thật hoặc nghiệm thu điện thoại.** Người dùng chốt kiến trúc và thử backend PC qua USB; có tài khoản Cloudinary, sẽ cung cấp cloud name. Người dùng xác nhận có Firebase Admin file và sẽ lưu trong secrets/firebase-admin.json. Không yêu cầu gửi key/file trong chat.

## Thay đổi

- functions/src/server.ts và moments_http.ts: API riêng, Firebase ID token xác minh/revocation check, fixed project hobbytracker-6ace6, JSON/binary giới hạn kích thước, tối đa bốn request đồng thời, private/no-store, không lộ SDK payload/token trong log. Node 22; localhost:8787 cho USB. Không cần Express/dependency HTTP mới.
- cloudinary_media.ts: SDK Cloudinary 2.11.0 ghim lockfile (cần cho upload_stream/private_download_url/delete theo asset ID). Authenticated uploads, overwrite=false, normalize JPEG/EXIF stripping trước lưu, không URL công khai. Server tải private URL hạn 30 giây nội bộ rồi recheck membership/expiry trước trả bytes.
- moments.ts thêm stage: session theo UID token, kiểm tra membership/hobby/hạn, lease ngăn stage/publish đồng thời, tối đa 30 stage attempts/giờ/UID. Source đã nhận được giữ nguyên khi retry; publish idempotency và ba giờ server giữ nguyên.
- Manifest server-only momentCloudAssets lưu hash/path/provider asset ID và reservation trước upload; cleanup xóa đúng immutable asset ID, giữ tombstone. Không thay client Rules thành mở. Quét manifest có giới hạn, dùng lại grace/lease/outbox/cleanup logic cũ.
- Worker standalone poll outbox mỗi lượt +15 giây; cleanup mỗi lượt +5 phút. Không cần Firestore trigger/Cloud Scheduler trên Firebase. Worker không hoạt động khi PC/process dừng. FCM bật qua biến môi trường, mặc định tắt trong template; không gửi lại bài cũ khi bật cờ.
- Flutter production Khoảnh khắc dùng MOMENTS_API_URL, Firebase Auth thật; foreground/background dùng chung factory. Không fallback về Functions chưa deploy khi thiếu URL. Debug cho HTTP loopback; release bắt buộc HTTPS, không redirect token. Legacy emulator adapter vẫn phục vụ hồi quy.
- functions/moments-server.env.example và scripts/start-moments-api.ps1 cho cấu hình local. .env.local và secrets/ bị Git ignore. README/architecture/data-model/open-decisions/design-traceability/index cập nhật. Không đổi thiết kế bốn tab hoặc thêm tính năng Final.

## Kiểm tra thực tế

Evidence tại [thư mục local checks](evidence/07b/cloudinary/):

| Kiểm tra | Kết quả / evidence |
|---|---|
| TypeScript build | PASS — backend-build.log |
| Backend unit cũ | 8/8 — backend-unit.log |
| HTTP + Cloudinary adapter (mock provider) | 10/10 — http-tests.log |
| Firestore Emulator riêng cổng 8580, demo-hobbytracker-cloudinary-tests | 5/5 — standalone-integration.log |
| Flutter toàn bộ | 151/151 — flutter-test.log |
| Sau sửa error mapping/copy cuối: targeted Flutter | 22/22 — flutter-targeted.log |
| Flutter analyze sau sửa cuối | Không issue — analyze.log |
| Android debug APK với API local 8787 | PASS — android-build.log |
| git diff --check, JSON và document links, ignored secrets | PASS kiểm tra local |
| Cloudinary thật / Firebase Admin credentials / điện thoại / FCM thật | NOT RUN |

APK SHA256: ceeb9f6d5e3e2d2cc440f84d0a2025a0e04be7bbf7fde3bd5bb8091042103770. Build vẫn có cảnh báo KGP từ workmanager_android hiện hữu, không phải lỗi build.

HTTP tests ban đầu bị sandbox chặn loopback; chạy ngoài sandbox đã đạt. Analyze ban đầu có lint dấu ngoặc khối, đã sửa và chạy lại sạch. Firestore integration dùng media giả trong bộ nhớ để kiểm thử domain; không phải test upload Cloudinary thật hoặc Firebase ID token thật. Các test HTTP dùng token verifier giả để kiểm tra ranh giới UID; verifyIdToken trên server thật chưa chạy. Firebase Rules/FCM/Scheduler/87 tests cũ không được cộng vào số test chạy trong lượt này. Không reset emulator/dữ liệu thử đang mở của người dùng.

Npm install báo 6 moderate vulnerabilities trong dependency tree; chưa có xác nhận audit sạch hoặc tự nâng dependency để bỏ cảnh báo. Cần review trước hosting thật.

## Điều kiện còn lại

Owner điền cloud name/key/secret vào functions/.env.local và đặt Firebase Admin file vào secrets/; chỉ gửi cloud name trong chat. Cần kiểm tra cấu hình authenticated assets và quota của gói Cloudinary thật. Sau đó khởi động backend, đối chiếu/deploy Rules và indexes đúng dự án, chạy app với API URL để nghiệm thu upload/read/retract và A/B/C. Đừng suy ra cloud PASS từ build/test local. Chưa deploy Rules/indexes/hosting hoặc sửa gói cước trong lượt này.

Kiến trúc mới bỏ blocker Blaze cho backend Khoảnh khắc; không thay đổi preflight lịch sử của Storage/Functions cũ. Hướng upload PDF Lab 3 chưa được chuyển sang Cloudinary trong lượt này và chưa được đánh dấu hoàn thành. Hướng dẫn chi tiết: [moments-cloudinary-run.md](moments-cloudinary-run.md).

```text
PHASE: 07B | Moments standalone Cloudinary migration
STATUS: PARTIAL
SCOPE: API/media/worker/Flutter transport + docs and local validation; live configuration/deployment/device acceptance pending
CHANGED FILES: functions/src/{server,moments_http,cloudinary_media,moments}.ts, package/lock, env template, HTTP factory/transport/repository/background/providers, l10n, tests, script, gitignore and docs
DESIGN TRACEABILITY: Existing Moments screens/flows; docs/design-traceability.md
ACCEPTANCE GATES:
  [PASS] Backend build, 8 unit + 10 HTTP/provider-mock + 5 Firestore emulator tests
  [PASS] 151 Flutter tests; final targeted rerun 22; analyze; debug APK
  [BLOCKED] Live provider/Admin credentials configured and real upload evidence
  [NOT RUN] Rules/index deployment, real FCM/two-phone/three-hour acceptance
COMMANDS ACTUALLY RUN:
  - npm view/install cloudinary@2.11.0; package install succeeded with six moderate advisories
  - npm --prefix functions run build/test/test:http -> 0 after fixes
  - firebase emulators:exec isolated Firestore + standalone-integration.test.mjs -> 0
  - flutter analyze/test/build apk --debug --dart-define=MOMENTS_API_URL=http://127.0.0.1:8787 -> 0 after fixes
SECURITY & DATA CHECK: No secret values read/printed; placeholders only, ignored secret paths; no live resource writes or billing changes
OPEN DECISIONS / RISKS: Cloudinary account capability/quota, Firebase Admin configuration and Rules/index rollout, hosting always-on workers and native push acceptance
COMMIT/PR/DEPLOY: NOT CREATED
READY FOR HUMAN REVIEW: YES (source/local checks)
NEXT PHASE: NOT STARTED
```

## Kiểm tra credentials thật tiếp theo — 04/11/2026

Đã tìm thấy file service account người dùng tải trong secrets/, xác nhận đúng project/type rồi copy sang tên firebase-admin.json, giữ file gốc. Không in private key. functions/.env.local đã có giá trị người dùng điền. Probe chỉ đọc scripts/check-api-config.mjs: Firestore đọc được và Firebase Auth lookup được phép; Cloudinary ping trả HTTP 401. Vì thế Admin credential gate đã đạt riêng, nhưng live Cloudinary upload/FCM vẫn NOT RUN và tổng trạng thái PARTIAL. Không chạy backend live hoặc ghi/xóa dữ liệu cloud trong probe. Bằng chứng đã lọc: evidence/07b/cloudinary/live-readiness.json. Owner cần đối chiếu cloud name/API key/API secret cùng product environment và key còn hoạt động; không gửi key qua chat.

## Cloudinary đã đạt; rollout Firestore chờ owner IAM — 04/11/2026

Cập nhật ưu tiên hơn kết quả 401 phía trên: readiness hiện Cloudinary/Firestore/Auth lookup đều true. Probe live Cloudinary tạo ảnh riêng 32x32, upload authenticated, private download HTTP 200 và xóa đúng asset ID đều đạt; evidence cloudinary-live-smoke.json, không dùng user data. 31 Firestore Rules regression tests chạy trên emulator riêng đều đạt. File config tạm cũ đã mất nên lần test đầu không khởi động; tạo lại config local rồi chạy đạt, không dùng emulator/user data hiện có.

Rules cloud đã backup và so sánh: chỉ khác các nhánh Moments/settings được bổ sung. Remote indexes trước deploy: 0 composites/0 overrides. Thêm firebase.moments-cloudinary.json chỉ nhắm Firestore. Lệnh deploy thực tế đã chạy nhưng dừng ở Service Usage GET 403, thiếu serviceusage.services.use, exit 1; chưa deploy Rules/indexes hoặc bật API/đổi billing. Người dùng xác nhận không có IAM admin, cần nhờ owner. Backend live chưa tự khởi chạy và chưa cài/chạy lại app trên điện thoại trong lượt này. Tổng trạng thái rollout BLOCKED bởi IAM; source/local checks vẫn PARTIAL theo nghiệm thu toàn tính năng.

Handoff cụ thể tại moments-owner-deploy-handoff.md. FCM/two-phone/three-hour full acceptance vẫn NOT RUN. Kết quả này không phải feature cloud PASS.
