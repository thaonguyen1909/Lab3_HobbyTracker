# Kiểm tra lại luồng Khoảnh khắc — 04/11/2026

> **Cập nhật mới nhất sau owner sửa IAM:** serviceusage.services.use đã true; deploy Firestore thành công; Rules khớp local và cả 5 composite indexes + inbox expiry index đều READY. API 8787 đã chạy/health 200, query outbox đạt. Đã cài/mở APK API mới trên R5CY81PSMAJ và quan sát danh sách có ảnh thật/countdown. Tổng trạng thái hiện **PARTIAL**, không còn BLOCKED bởi IAM; FCM nền, viewer/post/retract do agent thao tác trên máy và ca đủ ba giờ thật chưa nghiệm thu. Phần BLOCKED bên dưới ghi lại lần retest trước khi owner sửa; không phải trạng thái hiện tại.

Evidence mới: [IAM đủ quyền](evidence/07b/cloudinary-retest/deploy-permissions.json), [deploy thành công](evidence/07b/cloudinary-retest/firestore-deploy-after-iam.log), [Rules/indexes READY](evidence/07b/cloudinary-retest/firestore-post-deploy.json), [readiness và outbox query](evidence/07b/cloudinary-retest/readiness-after-iam.json), [build](evidence/07b/cloudinary-retest/android-build-after-iam.log), [device facts](evidence/07b/cloudinary-retest/device-after-iam.json).

Backend local được mở bởi Codex, FCM=false theo env đang có; cần giữ PC/backend/USB hoạt động. Worker từng báo lỗi khi indexes còn CREATING; sau READY query outbox đã xác nhận thực hiện được. Không tự nâng billing/deploy Functions/Storage/cấp IAM. Ảnh app quan sát trên máy là bài có sẵn do người dùng/team thao tác, không phải agent tạo post giả. Không tiếp tục thao tác tài khoản khi màn hình đã chuyển sang Google chooser; không coi lượt đó là viewer PASS. Ảnh chụp có màn hình tài khoản đã được loại khỏi artifacts local; không commit screenshots cá nhân.

**Kết luận: domain/API và UI tests đạt; nghiệm thu production BLOCKED bởi một quyền IAM đã xác nhận thiếu.** Không đánh dấu luồng trên điện thoại/cloud hoàn tất.

## Lỗi deploy đã chạy lại

Đúng lệnh deploy chỉ Firestore với firebase.moments-cloudinary.json, đúng hobbytracker-6ace6, non-interactive, không force/Functions/Storage/billing: vẫn exit 1 tại Service Usage GET HTTP 403. Rules/indexes chưa thay đổi. Log: [firestore-deploy.log](evidence/07b/cloudinary-retest/firestore-deploy.log).

Probe testIamPermissions chỉ đọc xác nhận tài khoản CLI thaontse184164@fpt.edu.vn, HTTP 200:

| Quyền đã kiểm tra | Có quyền |
|---|---|
| serviceusage.services.use | **Không** |
| serviceusage.services.get | Có |
| firebaserules.rulesets.create | Có |
| firebaserules.releases.create / update | Có |
| datastore.indexes.create / list | Có |

Bằng chứng: [deploy-permissions.json](evidence/07b/cloudinary-retest/deploy-permissions.json). Chỉ nhờ owner bổ sung **Service Usage Consumer** (roles/serviceusage.serviceUsageConsumer) cho tài khoản trên; không cần đề nghị cấp thêm các role Rules/indexes đã được quyền tương ứng. Đây là nhóm quyền đã test, không phải kiểm kê toàn bộ IAM. Không tự cấp quyền hoặc dùng danh tính khác để bỏ qua gate.

## Các kiểm tra thực tế đã đạt trong lượt này

- Readiness Cloudinary/Firestore/Auth lookup: đều true, [readiness.json](evidence/07b/cloudinary-retest/readiness.json).
- TypeScript build: exit 0, [backend-build.log](evidence/07b/cloudinary-retest/backend-build.log).
- Backend unit: 8/8, [backend-unit.log](evidence/07b/cloudinary-retest/backend-unit.log).
- HTTP + provider mock tests: 10/10, [http-tests.log](evidence/07b/cloudinary-retest/http-tests.log).
- Flutter HTTP/ViewModel/UI/alert controller: 41/41, [flutter-moments.log](evidence/07b/cloudinary-retest/flutter-moments.log). Bao gồm form/list/viewer và 360/412dp, English/Tiếng Việt, expiry và retry; đây không phải thao tác điện thoại thật.
- API flow với **Cloudinary thật**, Auth/Firestore emulator riêng: exit 0, chín check đều true, [cloudinary-http-flow.log](evidence/07b/cloudinary-retest/cloudinary-http-flow.log).

Flow sau gọi API HTTP thật, token được Firebase Admin xác minh bằng Auth emulator, dùng service/media adapter thật, với ảnh tự sinh 64x48:

1. Begin → binary stage → retry stage an toàn.
2. Publish → retry không tạo bài trùng hoặc kéo dài hạn; expiresAt-publishedAt đúng 10.800 giây.
3. Thành viên B list/get và tải ảnh private qua API; không có URL trong response ảnh.
4. Người ngoài nhóm không xem ảnh; người không phải tác giả không thu hồi.
5. Thành viên bị xóa khỏi nhóm mất quyền xem mới.
6. Backend clock được inject tới đúng hạn ba giờ: tải ảnh bị 404. Không giả là đã chờ đủ ba giờ thật.
7. Tác giả thu hồi; Cloudinary xóa ảnh thành công, mở lại không khả dụng.
8. Outbox bền vững được tạo.
9. Tất cả ảnh thử còn lại được dọn, không dùng dữ liệu Firebase production.

Script mới functions/scripts/test-cloudinary-flow.mjs chỉ cho phép Auth/Firestore emulator loopback, project demo-hobbytracker-cloudinary-flow cố định. Các user/group thử chỉ ở emulator. Không gửi FCM thật; không nghiệm thu indexes production hoặc Firestore client Rules trong flow Admin này. Emulator flow không cấu hình client Rules (Admin service checks vẫn hoạt động); các Rules regression tests 31/31 thuộc lượt trước, không cộng vào số test chạy lại này. Tất cả assets thử Cloudinary được xóa bằng manifest/immutable asset ID trong finally.

Probe IAM đầu tiên gọi sai chữ ký SDK post nên thất bại; đã sửa script và chạy lại HTTP 200 có bằng chứng phía trên. Không có thay đổi logic app để né permission. Node syntax và git diff checks đạt.

## Gate để chốt production

1. Owner bổ sung quyền Service Usage Consumer hoặc tự deploy config đã review.
2. Chạy lại deploy; đối chiếu Rules release và indexes READY.
3. Chạy backend Node local, reverse cổng 8787, build/run app với MOMENTS_API_URL.
4. Thử đăng/xem/thu hồi trên điện thoại, hai tài khoản cùng nhóm và push/background; thử đủ ba giờ thật riêng nếu cần chứng minh native expiry. Hiện các ca này chưa đạt nghiệm thu.

Điện thoại R5CY81PSMAJ có kết nối ADB nhưng không có reverse 8787; backend không lắng nghe 8787 tại lúc kiểm tra. Không cài lại hoặc cho chạy backend live chỉ để tạo cảm giác feature đã sẵn sàng trong khi deploy vẫn lỗi.

```text
PHASE: 07B | Moments retest and acceptance
STATUS: BLOCKED
SCOPE: Retest failed deploy, verify exact IAM gap, backend/Flutter/real-provider API flow validation
CHANGED FILES: scripts/check-moments-deploy-permissions.cjs, functions/scripts/test-cloudinary-flow.mjs, docs/evidence/07b/cloudinary-retest and reports/handoff
DESIGN TRACEABILITY: Existing Moments flows unchanged; docs/design-traceability.md
ACCEPTANCE GATES:
  [PASS] Readiness, build, 8 backend + 10 HTTP + 41 Flutter tests
  [PASS] Real Cloudinary + isolated Auth/Firestore HTTP flow (9 checks)
  [BLOCKED] Production deploy: serviceusage.services.use missing
  [NOT RUN] Full phone/cloud/FCM and real three-hour acceptance
COMMANDS ACTUALLY RUN:
  - firebase deploy only firestore rules/indexes -> 1, 403
  - check-api-config.mjs -> 0; testIamPermissions -> HTTP 200, probe exit 2 for missing permission
  - npm build/test/test:http -> 0; flutter selected tests -> 0
  - emulator Auth/Firestore + test-cloudinary-flow.mjs -> 0, assets cleaned
SECURITY & DATA CHECK: No secret output, no billing/IAM changes, no production fake users/groups/posts; own provider test assets deleted
OPEN DECISIONS / RISKS: Owner action for one confirmed permission; production/native gates remain
COMMIT/PR/DEPLOY: No commit/PR; deployment attempted but no successful deployment
READY FOR HUMAN REVIEW: YES (source/tests and handoff)
NEXT PHASE: NOT STARTED
```
