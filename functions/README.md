# Backend Khoảnh khắc — hợp đồng hiện tại

> **Ưu tiên 04/11/2026:** backend standalone tại src/server.ts + Cloudinary đã thay hướng deploy Functions/Storage cho Khoảnh khắc. Xem [cấu hình và chạy USB](../docs/moments-cloudinary-run.md). index.ts và hướng dẫn Functions bên dưới giữ cho test/lịch sử; không chạy firebase deploy --only functions cho kiến trúc mới. Live upload còn chờ credentials và nghiệm thu thực tế.

Phạm vi: upload, xử lý ảnh, đăng/list/xem/thu hồi khoảnh khắc nhóm, hết hạn sau ba giờ. Flutter đăng/xem ở bước 2; thông báo ở [bước 3](../docs/moments-alerts-step3-report.md); cleanup/retention và CLI demo ở [bước 4](../docs/moments-cleanup-step4-report.md). Chưa deploy cloud hoặc triển khai friendship.

Publish transaction tạo outbox server-only; deliverGroupMoment là Firestore created trigger, retryMomentDeliveries là scheduled function mỗi phút. Processor recheck member/opt-in/mute/Groups, loại tác giả, ghi reference inbox rồi gửi data-only FCM có TTL. Giới hạn 20 member/page, 10 token/UID, 10 due job/lượt retry. Trong Functions Emulator sender luôn null: tạo inbox thật nhưng không gửi FCM cloud. Scheduler cần hạ tầng cloud được owner review; bộ test gọi retryDue trực tiếp. Không deploy bằng hướng dẫn local.

## Chạy local trên Windows

Cần Node 22 trong PATH, Java 21 và Firebase CLI. Tại root repository:

```powershell
npm.cmd --prefix functions ci
npm.cmd --prefix firebase ci
npm.cmd --prefix functions run build
npm.cmd --prefix functions test
.\scripts\test-moments-emulators.ps1
```

Script cuối chạy Auth 9099, Functions 5001, Firestore 8080 và Storage 9199 bằng **demo-hobbytracker-moments**, sau đó chạy Rules tests cũ và integration tests mới. Không dùng project cloud thật hoặc cần billing để chạy emulator. Integration tests từ chối chạy nếu thiếu biến môi trường emulator Auth/Firestore/Storage. Dữ liệu A/B/C và ảnh mẫu chỉ nằm trong tests.

Để mở emulator cho công việc Flutter ở bước sau, sau khi build:

```powershell
firebase.cmd emulators:start --project demo-hobbytracker-moments --only auth,functions,firestore,storage
```

App Flutter hiện chưa nối API/emulator này; `flutter run` hiện tại không làm tính năng xuất hiện.

## Hợp đồng callable, region asia-southeast1

| Callable | Request data | Kết quả |
|---|---|---|
| beginGroupMomentUpload | requestId, groupId, hobbyId, caption | momentId, bucket, stagingPath, uploadDeadline, status |
| publishGroupMoment | momentId | Metadata có publishedAt/expiresAt ISO, tên snapshot và path nội bộ |
| listGroupMoments | groupId, limit? (1–20), cursor? | items, serverNow, nextCursor; expiry tăng dần rồi ID |
| getGroupMoment | groupId, momentId | Metadata còn hạn và serverNow |
| getGroupMomentImage | groupId, momentId, variant=photo hoặc thumbnail | contentType, base64, expiresAt, serverNow |
| retractGroupMoment | groupId, momentId | status=retracted, cleanupPending |

UID chỉ lấy từ ID token đã được Functions xác minh, không nhận authorId. Caption tối đa 160 Unicode characters; field lạ, lifetime/path tùy ý và ID traversal bị từ chối. Cursor `{expiresAtMs,momentId}` lấy từ page trước. Giữ cùng requestId (ví dụ UUID) khi retry cùng nội dung; đổi nội dung dùng ID mới.

Luồng client (đã có adapter Flutter ở bước 2; xem [báo cáo](../docs/moments-ui-step2-report.md) và [chạy local](../docs/moments-local-run.md)):

1. Xin session; backend kiểm tra membership, profile và hobby của tác giả chưa archive. Interested/Active đều được phép.
2. Dùng Storage SDK upload vào đúng bucket/stagingPath, MIME JPEG/PNG/WebP, tối đa 5 MB. Chỉ create, không overwrite; session upload có hạn 10 phút. Nếu file không hợp lệ, dùng request mới.
3. Publish: backend kiểm tra bytes/giới hạn 24 triệu pixel, bỏ EXIF, xuất JPEG tối đa 1600px/2 MB và thumbnail tối đa 512px/200 KB. Không copy custom metadata/token ảnh nguồn.
4. Backend đặt publishedAt và expiresAt = publishedAt + 10.800 giây; retry không đổi hai mốc. Staging được xóa best effort sau đăng thành công.
5. Người xem gọi getGroupMomentImage và giải mã base64 trong bộ nhớ. Không gọi getDownloadURL hay tải mediaPath trực tiếp bằng Storage SDK.

Callable trả bytes có overhead base64 khoảng 33%; photo giới hạn 2 MB. Bản đầu dùng cách này để kiểm soát hết hạn và tránh bearer URL. Có thể thay bằng authenticated streaming sau khi đo tải, vẫn kiểm tra quyền và không cấp URL dài hạn.

## Quyền, retry và giới hạn

- Firestore: groups/{gid}/moments/{mid} backend ghi; member chỉ get metadata còn hạn. List qua callable vì Rules không phải filters. users/{uid}/momentUploads/{mid} backend ghi/owner đọc; momentLimits/{uid} server-only.
- Staging owner-create-only theo session. Media `groupMoments/{gid}/{mid}/{leaseId}/photo.jpg` và `thumb.jpg` deny toàn bộ client SDK read/write; Admin SDK chỉ đọc sau khi service kiểm tra quyền. Staging Rules đọc một document Firestore; cloud cần quyền cross-service Storage–Firestore/default database.
- Image API kiểm tra membership/status/expiry trước và sau IO, trả Cache-Control private/no-store. Người ngoài nhóm hoặc hết hạn không lấy được ảnh, dù file vẫn còn trong bucket.
- IDs hash từ UID + requestId. Lease xử lý 150 giây, invocation timeout 120 giây, output path theo lease để worker cũ không ghi đè/xóa output worker mới.
- Quota v1: 10 upload session mới/giờ, 30 lần xử lý publish/giờ, 60 thao tác đọc/phút/UID. Image API dùng hai thao tác đọc. Không coi đây là biện pháp chống mọi loại abuse.
- Tác giả được thu hồi kể cả sau khi mất membership. Status đổi trước khi xóa bytes; lỗi xóa trả cleanupPending, gọi lại để retry.
- App Check chưa enforce vì Flutter chưa tích hợp; cần review trước triển khai rộng. Không đưa credentials gửi FCM/Admin SDK vào APK.

## Điều chỉnh sau thử nghiệm emulator

Lần test đầu tái hiện việc GET metadata/media qua Firebase Storage có thể sinh token download; token của source cũng được xử lý như metadata đặc biệt. Chỉ tránh gọi getDownloadURL trong app chưa đủ, vì client khác vẫn có thể yêu cầu URL.

Do đó v1 đóng toàn bộ direct reads của ảnh đã đăng và phục vụ bytes qua API xác thực. Output không có download token hữu dụng; source token không chuyển sang output. Tests kiểm tra API member được phép và SDK trực tiếp bị chặn. Đây là thay đổi kỹ thuật so với đường Storage SDK đọc ảnh trong proposal.

Đến hạn, quyền đọc mới bị chặn. Bước 4 thêm source scheduled cleanup mỗi 5 phút, lease/grace/cursor/batch có giới hạn; tombstone giữ ID để ngăn đăng lại cùng request cũ. Snapshot riêng tư bị xóa sau khi dọn media. Outbox/receipt giữ 24 giờ sau expiresAt, inbox tham chiếu bị xóa khi hết hạn. Metadata legacy được backfill dần. CLI local có preview và --run chỉ cho demo emulators; xem hướng dẫn ở báo cáo bước 4. Scheduled execution/cloud Storage precondition/retention vẫn cần nghiệm thu thật.

Trước cloud deployment: review bucket thật/region/Blaze/quyền cross-service, dependency audit, App Check và cleanup. Default bucket dùng cấu hình Firebase runtime; có thể đặt MOMENTS_STORAGE_BUCKET nếu khác. Không commit service-account/private key. Emulator luôn dùng bucket demo.

[Proposal](../docs/moments-implementation-proposal.md) · [Kết quả kiểm thử và báo cáo](../docs/moments-backend-step1-report.md).
