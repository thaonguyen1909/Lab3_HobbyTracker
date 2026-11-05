# Báo cáo bước 1 — backend Khoảnh khắc

> Đây là kết quả lịch sử của bước 1. Flutter đăng/xem đã được bổ sung sau đó ở [báo cáo bước 2](moments-ui-step2-report.md); các kết quả test bên dưới giữ nguyên theo thời điểm chạy.

Ngày 04/11/2026. Người dùng yêu cầu triển khai upload ảnh, quyền đăng/xem trong nhóm và hết hạn ba giờ. **Backend local đã chạy đạt; tính năng trên app/cloud chưa triển khai.**

## Đã thực hiện

- Sáu callable TypeScript: beginGroupMomentUpload, publishGroupMoment, listGroupMoments, getGroupMoment, getGroupMomentImage, retractGroupMoment.
- Upload session thuộc UID, hạn 10 phút, quota và requestId ổn định; chỉ member với hobby của mình chưa archive được publish. Interested/Active đều được phép.
- Kiểm tra bytes/kích thước/pixel, bỏ EXIF, tạo JPEG/thumbnail; backend đặt hạn 10.800 giây. Lease và path theo attempt tránh ghi đè output/retry tạo nhiều bài.
- Backend và Firestore metadata Rules kiểm tra membership/status/expiry. Published media đóng toàn bộ direct Storage reads; image callable kiểm tra quyền trước/sau IO và trả bytes, không cấp URL download token.
- Thu hồi đổi status trước xóa ảnh; trả cleanupPending và có thể retry khi xóa lỗi.
- Chưa làm Dart/UI, FCM, popup, bạn bè hoặc cleanup định kỳ. Không sửa Firebase cloud/billing/Git history hoặc deploy. Các thay đổi Android/pubspec có trước task được giữ nguyên.

## Kết quả đã chạy

| Kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| TypeScript strict build | PASS | Lệnh build đầu [log emulator cuối](evidence/05/moments-backend/emulator-tests.log) |
| Validation và xử lý ảnh | PASS, 8/8 | [unit-tests.log](evidence/05/moments-backend/unit-tests.log) |
| Rules cũ | PASS, 35/35 | Nhóm đầu [emulator-tests.log](evidence/05/moments-backend/emulator-tests.log) |
| Backend và Rules mới | PASS, 17/17 | Nhóm integration thứ hai trong cùng log |
| Callable HTTP thật trong emulator | PASS | Auth emulator cấp token; Functions xử lý toàn bộ API; thiếu auth 401, giả field 400, moment thu hồi 404 |
| git diff --check | PASS | Đã chạy sau sửa source |
| UI/hai điện thoại/Firebase cloud | NOT RUN | Chưa deploy hoặc nối Flutter vào backend mới |
| Chờ đủ ba giờ ngoài đời | NOT RUN | Ranh giới ba giờ đã kiểm tra bằng clock backend inject trong test và mốc expiry quá hạn trong Rules emulator |
| Flutter analyze/test/build trong lượt này | NOT RUN | Không thay Dart; không dùng kết quả Flutter lịch sử để thay acceptance tính năng mới |

Tổng **60 test đạt** = 8 unit/image + 35 Rules hồi quy + 17 integration. Dùng demo-hobbytracker-moments; Rules cũ còn dùng các namespace demo lịch sử. Tất cả là local emulators, không phải bằng chứng Firebase cloud.

Lần chạy cuối dùng Node **22.23.4**, Firebase CLI **15.30.2**, Firestore emulator **1.22.0**, Storage Rules runtime **1.1.3**, Java 21. Node 22 từ cache npm được đặt vào PATH của process; không đổi Node 24 toàn hệ thống. Runner kiểm tra Node major 22 để tránh emulator tự chọn runtime khác.

## Các lỗi tìm thấy và đã sửa

1. **Download token có thể sống quá hạn:** test đầu cho thấy direct Firebase Storage GET có thể sinh token. Đổi sang authenticated image callable, đóng direct reads; member đọc qua API được, SDK/getDownloadURL bị chặn. Source token không được copy sang output.
2. **Upload đè được emulator coi là create:** thêm `resource == null` để write-once; test upload lần hai bị từ chối.
3. **Hết hạn/mất quyền giữa IO:** kiểm tra lại sau khi tải bytes; hai test race đều từ chối trả ảnh.
4. **gRPC cũ của SDK test:** override backend package sang @grpc/grpc-js 1.14.7 cùng major, khóa trong lockfile; integration chạy với bản này.

Giữ [log thất bại đầu](evidence/05/moments-backend/emulator-tests-initial-failed.log) và [log thất bại thứ hai](evidence/05/moments-backend/emulator-tests-second-failed.log) để truy vết. Kết quả hiện tại là log cuối.

## Dependency và giới hạn

Pin firebase-admin 14.5.0, firebase-functions 7.4.0, sharp 0.35.5, TypeScript 7.0.2. SDK test dùng firebase 12.19.0/rules-unit-testing 5.0.2 để hỗ trợ Node 22; rules-unit-testing 6 yêu cầu Node 24. Có package-lock và [cây dependency](evidence/05/moments-backend/dependency-tree.log).

Sau override gRPC, npm install vẫn báo **6 cảnh báo moderate**, còn nhánh google-gax 5 → rimraf 5 → glob 10/minimatch 9. Các lần npm audit riêng và audit fix dry-run gặp ECONNRESET ở advisory endpoint. Không áp dụng audit fix --force/major override để che cảnh báo, không tuyên bố audit sạch. Package test cũ firebase/ giữ dependency/lock ban đầu.

Trước cloud cần review dependency còn lại, bucket/region/Blaze/cross-service Rules và App Check. Thêm cleanup ảnh hết hạn/staging bỏ dở trước vận hành dài hạn. Backend chặn đọc mới đúng hạn, không hứa xóa vật lý/screenshot/cache Android đúng từng giây. Base64 có overhead; cân nhắc authenticated streaming khi lưu lượng tăng.

## Bàn giao

[Backend contract và cách chạy](../functions/README.md). Source functions/src; tests functions/test; Rules/index firebase; config firebase.json; runner scripts/test-moments-emulators.ps1. Chưa commit/push/deploy.

```text
PHASE: 05 | Community extension — moments backend step 1
STATUS: PARTIAL (backend local PASS; whole feature/cloud not accepted)
SCOPE: upload/process/publish/list/get/image/retract, membership/expiry, local tests
CHANGED FILES: functions/, firebase.json, firebase rules/index, .gitignore, scripts/test-moments-emulators.ps1, relevant docs/evidence
DESIGN TRACEABILITY: docs/design-traceability.md; no new Flutter screen
ACCEPTANCE GATES:
  [PASS] strict build; 8 unit/image + 35 existing Rules + 17 backend integration
  [PASS] A/B permitted, C/anonymous denied; spoofing/retry/expiry/IO race/retraction tests
  [NOT RUN] UI/push/cloud/two-device acceptance and real three-hour wait
  [BLOCKED] clean dependency audit — advisory endpoint ECONNRESET; install reports 6 moderate
COMMANDS ACTUALLY RUN:
  - npm.cmd --prefix functions install; npm.cmd --prefix firebase ci -> packages installed
  - npm.cmd --prefix functions run build -> exit 0
  - npm.cmd --prefix functions test -> exit 0, 8/8
  - scripts/test-moments-emulators.ps1 with Node 22 -> final exit 0, 35/35 + 17/17
  - npm audit / audit --omit=dev / audit fix --dry-run -> ECONNRESET
  - git diff --check -> exit 0
SECURITY & DATA CHECK: deny-by-default; server expiry; authenticated image API; emulator A/B/C and negative tests
OPEN DECISIONS / RISKS: dependency audit, owner cloud config/billing, cleanup next step, base64 overhead
COMMIT/PR/DEPLOY: NOT CREATED
READY FOR HUMAN REVIEW: YES (local backend)
NEXT PHASE: NOT STARTED
```
