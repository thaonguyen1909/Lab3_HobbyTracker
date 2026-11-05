# Bước 4 — Cleanup, hồi quy và chuẩn bị demo Khoảnh khắc

Ngày 04/11/2026. Phạm vi người dùng giao là **bước 4 của Khoảnh khắc**, không phải phase 04 Calendar/Hyper. Đã viết cleanup backend/local, sửa lỗi phát hiện khi kiểm thử và chuẩn bị checklist demo. **Source/local QA đạt; nghiệm thu cloud/thiết bị vẫn PARTIAL.** Không deploy, bật billing, commit, push hoặc tag.

## Chính sách dọn dữ liệu đã triển khai

| Dữ liệu | Xử lý |
|---|---|
| Ảnh đủ ba giờ hoặc đã thu hồi | API chặn đọc độc lập với cleanup; job xử lý tối đa 10 moment/lượt, mỗi trang tối đa 50 object |
| Upload bỏ dở/processing lỗi | Sau deadline 10 phút cộng grace 5 phút; chờ thêm nếu lease xử lý còn hiệu lực; giữ ảnh published còn hạn |
| Staging/output mồ côi | Quét riêng hai namespace, tối đa 50 object/namespace/lượt; chỉ xét file cũ ít nhất 24 giờ và kiểm tra metadata liên quan |
| Metadata moment/session | Xóa caption/name snapshots/đường dẫn ảnh không còn cần; giữ tombstone tối thiểu và ID để request cũ không tạo lại bài |
| Inbox tham chiếu | Xóa tối đa 50 mục hết hạn/lượt, qua collection-group query riêng |
| Outbox/receipt | Giữ tới 24 giờ sau expiresAt; xóa receipt có/thiếu parent bằng batch giới hạn rồi mới xóa outbox; không lấy token của users/devices |
| Marker/index local | Marker dedupe giữ tối đa một ngày từ lúc ghi theo giờ máy; dọn index notification hết hạn và thử lại nếu hủy native lỗi; legacy được gắn hạn bảo thủ một ngày |

Source `cleanupExpiredMoments` được cấu hình lịch 5 phút, timeout 120 giây, một instance. Global lease 150 giây ngăn hai lượt cleanup cùng chạy. Mỗi mục lỗi được lùi cleanupAfter 5 phút để thử lại; Storage sweep giữ cursor khi lỗi. Có bounded backfill cho metadata bước cũ chưa có cleanupPending/cleanupAfter; không bật lại các mục đã dọn xong.

Tombstone giữ lâu dài nhằm tránh tái sử dụng ID sau khi xóa file; chưa có chính sách xóa tombstone/account toàn hệ thống. Đây là lựa chọn kỹ thuật cần owner review về retention khi mở rộng. Job có giới hạn và backlog nên **không hứa xóa file vật lý đúng từng giây thứ ba giờ**.

Chỉ xóa leaf được backend tạo: `momentStaging/{uid}/{mid}/source` và `groupMoments/{gid}/{mid}/{lease}/photo.jpg|thumb.jpg`. Không lấy mediaPath tùy ý làm đích xóa. File PDF, ảnh thư viện gốc, hobby/lịch/history/chat không thuộc cleanup này. Android/plugin có thể giữ cache riêng, OS có thể giữ notification/screenshot; chưa có bằng chứng native để cam kết thu hồi tất cả bản sao.

Cloud Storage soft delete/versioning/retention có thể giữ bản sao sau lệnh xóa. Chưa đọc hoặc đổi chính sách bucket thật; việc không còn truy cập qua app không đồng nghĩa đã xóa vĩnh viễn mọi bản sao trong cloud. Tham khảo [Cloud Storage soft delete](https://docs.cloud.google.com/storage/docs/soft-delete).

## Files của bước 4

- functions/src/moment_cleanup.ts, moment_cleanup_media.ts; moments.ts thêm queue/tombstone, retract chỉ xóa đúng namespace; moment_delivery.ts ghi parent trước receipt; index.ts thêm scheduled cleanup.
- functions/scripts/cleanup-local.mjs; test/cleanup.test.mjs, cleanup-cli.test.mjs; package.json; firebase/firestore.indexes.json.
- lib/services/moment_local_retention.dart; moment_alert_providers.dart, moment_local_notifications.dart; firebase/moment_background.dart, firebase_device_services.dart.
- test/moment_retention_test.dart và test double trong moment_alerts_ui_test.dart; không thêm dependency.
- Tài liệu step 4, [review findings](moments-step4-review.md), [demo/acceptance](moments-demo-acceptance.md), chỉ mục, kiến trúc/data-model/traceability/decisions và hướng dẫn local.

## Kết quả đã chạy

| Kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| TypeScript strict build | PASS | Build đầu [emulator-tests-final.log](evidence/05/moments-final/emulator-tests-final.log) |
| Backend unit/image | PASS, 8/8 | [backend-unit-tests.log](evidence/05/moments-final/backend-unit-tests.log) |
| Rules hồi quy | PASS, 35/35 | emulator-tests-final.log |
| Backend integration | PASS, 42/42 | Cùng log: 17 moment + 13 delivery + 12 cleanup |
| Cleanup sau bổ sung kiểm tra token thiết bị | PASS, 12/12 | [cleanup-tests-final.log](evidence/05/moments-final/cleanup-tests-final.log); chạy lại đúng nhóm ca bị ảnh hưởng, không cộng trùng vào tổng 87 |
| Công cụ cleanup local | PASS, 2/2 | [cleanup-cli-tests.log](evidence/05/moments-final/cleanup-cli-tests.log): chặn host cloud, preview không sửa dữ liệu, --run xóa fixture hết hạn |
| Tổng backend/Rules/CLI | **PASS, 87/87** | 8 + 35 + 42 + 2; hai lượt emulator độc lập, không phải bằng chứng cloud |
| Toàn bộ Flutter | **PASS, 145/145** | [flutter-tests.log](evidence/05/moments-final/flutter-tests.log): ba flow cũ, UI Khoảnh khắc và retention |
| Retention sau sửa test-double lint | PASS, 8/8 | [retention-tests-final.log](evidence/05/moments-final/retention-tests-final.log) |
| Analyze | PASS | [analyze-final.log](evidence/05/moments-final/analyze-final.log): No issues found |
| Format | PASS | [format.log](evidence/05/moments-final/format.log): 90 files, 0 changed |
| APK Android debug local | PASS | [android-build.log](evidence/05/moments-final/android-build.log); build/app/outputs/flutter-apk/app-debug.apk; [SHA256](evidence/05/moments-final/apk-sha256.log) |
| Điện thoại USB | NOT RUN | [adb-devices.log](evidence/05/moments-final/adb-devices.log): không có device |
| ARTEMIS | NOT RUN | Không có thiết bị; lệnh Python trên PATH trỏ tới WindowsApps stub không chạy được, không có venv e2e sẵn |
| Cloud Scheduler/FCM/đủ ba giờ thật | NOT RUN | Chưa deploy/billing; emulator không thực thi scheduled functions; test gọi cleanup/retry trực tiếp |

Emulator lượt đầu có 40/42 integration đạt. Hai lỗi thực tế được giữ trong [log ban đầu](evidence/05/moments-final/emulator-tests-initial.log): receipt thiếu parent bị bỏ sót và emulator không thực thi DELETE generation precondition. Đã sửa bằng scan giới hạn theo outbox và kiểm tra generation trước lệnh xóa; lượt sau 42/42 đạt. Check trước khi xóa + precondition GCS vẫn chưa phải bằng chứng đã thử race atomically trên cloud.

Cảnh báo KGP từ Workmanager của bước 3 vẫn hiện khi build; APK thành công với workaround module hiện có. Không nâng Flutter/Kotlin hay đổi native architecture trong bước 4. Sáu npm moderate/audit endpoint ghi ở bước 1 vẫn mở; không tuyên bố audit sạch.

## Cách sử dụng và nghiệm thu

Theo [hướng dẫn local](moments-local-run.md), chạy preview trước rồi chạy một pass cleanup bằng `--run`. Tool chỉ nhận project/bucket demo cố định và emulator loopback; không có tùy chọn trỏ cloud. Lịch 5 phút là source chờ deploy, không phải một service đã chạy trên Firebase thật.

[Kịch bản demo và checklist](moments-demo-acceptance.md) tách rõ kiểm chứng local với các ca cần hai điện thoại/cloud. Không rút lifetime production xuống vài phút để giả làm đủ ba giờ; test tự động dùng clock inject và ghi đúng loại bằng chứng.

## Báo cáo theo repository

```text
PHASE: 05 | Moments step 4 — cleanup, regression and demo readiness
STATUS: PARTIAL
SCOPE: Bounded cleanup source, local retention, regression fixes and demo/checklist; no cloud deployment or full Lab 3 acceptance
CHANGED FILES: Listed above
DESIGN TRACEABILITY: docs/design-traceability.md — Moments step 4; existing UI layout preserved
ACCEPTANCE GATES:
  [PASS] 145 Flutter tests, 87 backend/Rules/CLI tests, TypeScript build, clean analyze/format and Android debug build
  [PASS] Live media/processing leases and unrelated PDF/history survive cleanup; stale IDs cannot republish
  [NOT RUN] Cloud scheduler/atomic Storage preconditions, real FCM, two devices, three-hour real-time session and ARTEMIS
COMMANDS ACTUALLY RUN:
  - npm --prefix functions test -> 0, 8/8
  - scripts/test-moments-emulators.ps1 -> 0, 35/35 + 42/42 (before appending the new CLI suite)
  - firebase emulators:exec --project demo-hobbytracker-moments --only firestore,storage "npm --prefix functions run test:cleanup-cli" -> 0, 2/2
  - firebase emulators:exec --project demo-hobbytracker-moments --only firestore,storage "node --test functions/test/cleanup.test.mjs" -> 0, 12/12 after device-token preservation assertion
  - flutter test --no-pub --concurrency=1 --reporter expanded -> 0, 145/145
  - flutter test --no-pub test/moment_retention_test.dart --reporter expanded -> 0, 8/8 after test-double-only fix
  - flutter analyze -> 0
  - dart format --output=none --set-exit-if-changed lib test -> 0
  - flutter build apk --debug --no-pub --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1 -> 0
  - adb devices -l -> 0, no devices
  - python -m pytest e2e_test --collect-only -q -> did not launch usable Python; not an E2E run
SECURITY & DATA CHECK: Expiry gates independent of deletion; deletion namespace/generation checks; UID-scoped local cleanup; minimal tombstones retain idempotency
OPEN DECISIONS / RISKS: Cloud/device acceptance, soft-delete/retention settings, tombstone policy, existing dependency audit/App Check and formal Lab 3 submission evidence
COMMIT/PR/DEPLOY: NOT CREATED
READY FOR HUMAN REVIEW: YES
NEXT PHASE: NOT STARTED
```
