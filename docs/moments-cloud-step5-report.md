# Đợt 5 — Đưa Khoảnh khắc lên Firebase hiện tại

Ngày 04/11/2026. Người dùng xác nhận: **“Triển khai lên Firebase hiện tại, không đổi gói cước”**. Đích duy nhất là `hobbytracker-6ace6`, bucket cấu hình `hobbytracker-6ace6.firebasestorage.app`, Functions region `asia-southeast1`, codebase `moments`.

**STATUS: BLOCKED trước deploy.** Đã giải quyết tài khoản CLI; dự án đích truy cập được. Billing chưa bật và bucket cấu hình chưa tồn tại nên chưa đủ điều kiện triển khai backend hiện tại. Không chạy firebase deploy, không bật API/billing, không tạo bucket hoặc thay Rules trên cloud.

## Kiểm tra cloud đã thực hiện

Bằng chứng đã lọc, không chứa token/email/mã đăng nhập: [preflight.json](evidence/07b/moments-cloud/preflight.json). Thời điểm kiểm tra nằm trong checkedAt của file.

| Kiểm tra | Kết quả thực tế | Trạng thái |
|---|---|---|
| Quyền truy cập dự án đúng | Firebase Management GET trả 200, projectId đúng, ACTIVE | PASS |
| Billing hiện tại | Cloud Billing GET trả 200, billingEnabled=false | BLOCKED |
| Bucket trong Android config | Storage GET trả 404 | BLOCKED |
| Firestore Rules đang dùng | GET 200, đã sao lưu riêng; khác bản local mở rộng Moments | PASS cho backup, chưa deploy |
| Storage Rules release của bucket | GET 404 | Chưa có snapshot release đích |
| Cloud Functions/FCM/Scheduler sau triển khai | Chưa triển khai | NOT RUN |
| Audit production | npm advisory endpoint tiếp tục ECONNRESET | Chưa có kết quả audit sạch |

Cloud Functions yêu cầu dự án ở gói Blaze khi deploy. Việc đăng nhập đúng tài khoản không tự đáp ứng điều kiện này. Tôi giữ nguyên ràng buộc không đổi gói cước; không thử deploy để ép CLI bật dịch vụ. Nguồn: [Firebase — quản lý và triển khai Functions](https://firebase.google.com/docs/functions/manage-functions).

Lỗi Smart Ledger trước đó do CLI dùng tài khoản khác, không phải app đã được chuyển dự án. Đã chọn tài khoản có quyền cho đúng thư mục repository; không deploy hay sửa tài nguyên Smart Ledger. CMD dùng `%name%`, PowerShell dùng `$name`; tên thư mục không tự chọn Google account. Không cần đăng xuất/xóa các tài khoản CLI khác.

## Phần đã chuẩn bị

- `scripts/check-moments-cloud.cjs`: preflight chỉ GET, cố định project/bucket, kiểm tra native config/Node 22, dùng tài khoản của Firebase CLI. Từ chối token override/emulator env để tránh đọc nhầm môi trường. Không có lệnh nâng billing, bật API hay deploy.
- `--snapshot-rules` sao lưu Rules hiện tại vào `deployment-artifacts/`, đã được `.gitignore` loại khỏi Git. Báo cáo công khai chỉ lưu SHA256 và trạng thái, không in toàn bộ Rules/token.
- Manifest SHA256 của cấu hình, package lock và mọi TypeScript source backend nằm trong evidence. Preflight đạt hạ tầng cũng chỉ là INFRASTRUCTURE_CHECKED, không phải đã deploy/nghiệm thu.
- `firebase.json` thêm ignore cho test/scripts của package Functions; giữ src/tsconfig/lib cần cho build. Không đưa công cụ emulator/fixtures vào bundle runtime.
- Các bước 1–4 giữ kết quả local riêng: 145 Flutter tests, 87 backend/Rules/CLI tests. Không chạy lại chúng để giả lập bằng chứng deploy trong đợt này; app logic và Rules source không đổi ở đợt 5.

## Điều kiện tiếp tục

Nếu giữ nguyên điều kiện billing hiện tại, vẫn có thể thử bản local theo [hướng dẫn emulator](moments-local-run.md). Không có đường deploy Cloud Functions hiện tại đáp ứng cả billingEnabled=false và yêu cầu giữ nguyên gói.

Muốn tiếp tục cloud, owner cần thay đổi ràng buộc billing theo quyết định riêng và chuẩn bị bucket đúng dự án. Khi các điều kiện được đáp ứng, kiểm tra lại bằng Node 22:

```powershell
cd D:\Ki-8\PRM393\project\Lab3\Lab3_HobbyTracker
node .\scripts\check-moments-cloud.cjs --snapshot-rules
```

Exit 2 là preflight bị chặn có nguyên nhân trong blockers; không phải deploy thất bại. Exit 0 chỉ xác nhận các điều kiện hạ tầng đã kiểm tra. Trước deploy thật còn cần đối chiếu indexes hiện tại để giữ indexes đang dùng, IAM/cross-service Storage–Firestore, runtime service account, bucket location/soft delete, dependency audit và các function đã có. Không tự xóa function/index cũ hoặc dùng --force.

Gói thay đổi dự kiến gồm Firestore Rules/indexes, Storage Rules và 9 function source: beginGroupMomentUpload, publishGroupMoment, listGroupMoments, getGroupMoment, getGroupMomentImage, retractGroupMoment, deliverGroupMoment, retryMomentDeliveries, cleanupExpiredMoments. Chưa có function URL/Console evidence/FCM delivered hoặc smoke test cloud để báo PASS. Nghiệm thu theo [checklist](moments-demo-acceptance.md) sau khi deploy thành công.

## Báo cáo theo repository

```text
PHASE: 07B | Moments cloud rollout — step 5
STATUS: BLOCKED
SCOPE: Correct target/account, read-only cloud preflight, Rules snapshot, deployment packaging; no billing change or cloud deployment
CHANGED FILES: scripts/check-moments-cloud.cjs, firebase.json, .gitignore, docs/evidence/07b/moments-cloud/preflight.json and related docs
DESIGN TRACEABILITY: No UI change; docs/design-traceability.md step 5 note
ACCEPTANCE GATES:
  [PASS] Target project access and Firestore Rules snapshot
  [PASS] Preflight syntax/JSON, source hashes and local diff/link checks
  [BLOCKED] Billing not enabled and configured Storage bucket absent
  [NOT RUN] Deploy, cloud smoke tests, FCM/device/Scheduler acceptance
COMMANDS ACTUALLY RUN:
  - firebase projects:list/apps:list -> wrong account 403 first, selected authorized account, target GET 200
  - firebase login:use authorized-account -> success for repository directory
  - node scripts/check-moments-cloud.cjs --snapshot-rules -> 2, intentional BLOCKED
  - node --check scripts/check-moments-cloud.cjs -> 0
  - npm --prefix functions audit --omit=dev --json -> advisory endpoint ECONNRESET
SECURITY & DATA CHECK: No credentials in evidence; raw Rules backups ignored by Git; no project resource writes or plan changes
OPEN DECISIONS / RISKS: Billing/bucket conflict with the user's no-plan-change constraint; remaining cloud/device acceptance
COMMIT/PR/DEPLOY: NOT CREATED
READY FOR HUMAN REVIEW: YES (preflight/source preparation only)
NEXT PHASE: NOT STARTED
```
