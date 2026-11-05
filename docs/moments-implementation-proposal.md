# Đề xuất triển khai Khoảnh khắc 3 giờ

Ngày: 04/11/2026. Trạng thái: **Thiết kế đề xuất; người dùng đã cho phép triển khai bước backend đầu tiên**. Các mục bên dưới không phải toàn bộ đã được viết/test. Hợp đồng backend thực tế và điều chỉnh đường tải ảnh nằm trong [functions/README.md](../functions/README.md); kết quả tại [báo cáo bước 1](moments-backend-step1-report.md).

Nguồn yêu cầu: người dùng cho biết giảng viên muốn thành viên/bạn bè nhận thông báo và ảnh khi một người đăng ảnh hoạt động; ảnh biến mất sau ba giờ. Đây là yêu cầu bổ sung qua trao đổi, không phải nội dung đã có trong các PDF/HTML gốc. Giữ nguyên các file requirements/reference và ghi phần mở rộng riêng.

## 1. Phạm vi đề xuất

Làm Android, chia sẻ trong **một nhóm đã tham gia** trước. Giữ bốn tab Home / Community / My Hobbies / Settings, MVVM/Riverpod và ba flow hiện tại.

| Có trong bản đầu | Để đợt sau |
|---|---|
| Chụp/chọn một ảnh, preview, chú thích tối đa 160 ký tự, chọn hobby và một nhóm | Video, nhiều ảnh, vị trí GPS |
| Danh sách khoảnh khắc trong Community và xem ảnh lớn | Bảng xếp hạng, tự xác minh địa điểm/việc luyện tập |
| Popup trong app; thông báo Android có thumbnail khi tải được | Quan hệ kết bạn, lời mời/chấp nhận/hủy kết bạn |
| Hết hạn sau ba giờ; tác giả xóa sớm | Bình luận riêng, reaction riêng; có thể tận dụng chat nhóm để phản hồi trước |
| Bật/tắt thông báo khoảnh khắc, tắt theo nhóm, kiểm soát preview màn hình khóa | Album lưu trữ cá nhân sau hết hạn |

Ba giờ tính từ lúc máy chủ xác nhận đăng thành công, không tính từ lúc chụp hoặc bắt đầu upload. Chia sẻ ảnh không tự tạo lịch hay history luyện tập.

People hiện có khám phá hồ sơ/DM, chưa có quan hệ bạn bè hai chiều. Không coi mọi người trong People hoặc người từng chat là bạn. Đợt sau mới thêm lời mời và quyền xem theo quan hệ đã được hai bên chấp nhận.

## 2. Tận dụng app và các khoảng trống đã kiểm tra

| Hiện có | Thay đổi cần làm |
|---|---|
| groups/{gid}/members/{uid}, groupLinks và group chat | Dùng membership làm điều kiện đăng/xem; thêm lựa chọn nhóm |
| users/{uid}/devices/{id} lưu token, cleanup khi logout | Backend đọc token để gửi; dọn token không còn hợp lệ |
| FirebaseDeviceServices, background handler, LocalOwnerStore inbox theo UID | Thêm loại moment, định danh ổn định, expiresAt, ảnh và trạng thái hết hạn |
| allowedNotificationPath chỉ chấp nhận một số route cũ | Bổ sung route moment có kiểm tra ID, đăng nhập, membership và hạn dùng |
| LocalReminders dùng flutter_local_notifications | Tách ID/channel và bộ hiển thị khoảnh khắc; không để sync lịch cancelAll thông báo khác |
| Storage Rules hiện chỉ cho PDF reports/{uid}/{file} | Thêm đường dẫn staging/media riêng với quyền hạn cụ thể |
| firebase/package.json hiện chỉ phục vụ Rules tests | Thêm functions/ TypeScript riêng; không thay package test bằng backend |
| Preferences có schema khóa chặt trong Rules | Tạo settings/momentNotifications riêng; không thêm field tùy ý làm hỏng schema cũ |

## 3. Trải nghiệm người dùng

1. Community có vùng **Khoảnh khắc đang diễn ra** và nút **Chia sẻ khoảnh khắc**; chọn nhóm để xem, không thêm tab chính.
2. Màn tạo: chụp/chọn ảnh → preview → chú thích → hobby → nhóm → đăng. Có xin quyền, tiến trình upload, hủy và thử lại; lỗi giữ bản nháp trên máy.
3. Người xem thấy thumbnail, tên người đăng, hobby và thời gian còn lại; bấm mở ảnh lớn. Có loading/error/retry/expired/không còn quyền xem.
4. Khi đang dùng app, nhận banner nhỏ khoảng năm giây, bấm mới mở ảnh. Không tự mở modal toàn màn hình.
5. Nếu đang luyện trong Hyper Mode, chỉ thêm inbox/badge và gộp thông báo để xem sau; không làm thay đổi timer.
6. Khi app ở nền, hiển thị thông báo hệ thống có ảnh thu nhỏ nếu tải/kiểm tra quyền thành công; ảnh lỗi có text fallback. Không yêu cầu quyền vẽ đè ứng dụng khác.
7. Khi hết hạn hoặc tác giả thu hồi, đóng nội dung đang xem; mở thông báo cũ sẽ hiện **Khoảnh khắc đã hết hạn hoặc không còn khả dụng**.

Nhãn mới có English/Tiếng Việt, dùng design token hiện tại, hỗ trợ bàn phím/text scale và touch target 48dp. Ghi chênh lệch thiết kế vào traceability khi bắt đầu code; proposal này chưa chỉnh Figma.

## 4. Kiến trúc và chu trình đăng

```mermaid
sequenceDiagram
    participant C as Châu - Flutter
    participant B as Backend tin cậy
    participant S as Storage riêng tư
    participant D as Firestore
    participant F as FCM
    participant A as An - Flutter
    C->>B: Xin phiên upload cho một nhóm
    B->>D: Kiểm tra tác giả và membership
    B-->>C: momentId và đường dẫn staging
    C->>S: Upload ảnh, có progress/retry
    C->>B: Xác nhận đăng với cùng momentId
    B->>S: Kiểm tra ảnh, tạo ảnh chuẩn và thumbnail
    B->>D: Lưu ready, publishedAt, expiresAt và outbox
    B-->>C: Đăng thành công
    B->>F: Gửi cho thành viên hợp lệ, trừ tác giả
    F-->>A: Tín hiệu có khoảnh khắc mới
    A->>D: Kiểm tra quyền và hạn dùng
    A->>B: Xin thumbnail bằng xác thực người dùng
    B->>S: Đọc ảnh sau khi kiểm tra quyền/hạn dùng
    B-->>A: Bytes ảnh, không cấp download URL
    A-->>A: Popup hoặc thông báo Android
    Note over A,S: Hết hạn: chặn đọc mới và ẩn ảnh; backend dọn file sau đó
```

View chỉ gọi ViewModel; ViewModel gọi MomentRepository/MomentMediaService. Firebase SDK/callable nằm trong adapters. Admin SDK và quyền gửi FCM chỉ ở backend, không đưa server credentials vào APK.

### API backend dự kiến

| API / worker | Trách nhiệm |
|---|---|
| beginGroupMomentUpload | Xác thực, kiểm tra membership/hobby tác giả, giới hạn đăng, nhận requestId để retry không tạo nhiều phiên; cấp upload session ngắn hạn |
| publishGroupMoment | Kiểm tra upload session, decode ảnh thật, chuẩn hóa, ghi publishedAt/expiresAt từ giờ backend; cùng momentId publish lại trả kết quả cũ, không kéo dài hạn |
| listGroupMoments | Kiểm tra membership, query ảnh ready chưa hết hạn bằng thời gian backend, phân trang, trả serverNow để đồng bộ đếm ngược |
| getGroupMomentImage | Kiểm tra quyền/hạn trước và sau IO, trả bytes ảnh; bổ sung sau thử nghiệm bước 1 thay cho direct Storage reads |
| retractGroupMoment | Chỉ tác giả được thu hồi; đổi status trước khi dọn file |
| processMomentOutbox | Xác định người nhận, kiểm tra tùy chọn, gửi FCM và lưu kết quả retry |
| cleanupExpiredMoments | Job định kỳ đề xuất mỗi năm phút, dọn media hết hạn/upload bỏ dở và outbox thừa, có retry/phân trang |

Ảnh đầu vào đề xuất tối đa 5 MB. Backend kiểm tra bytes thực, số pixel/kích thước ảnh và re-encode, bỏ EXIF; tạo ảnh xem tối đa khoảng 1600px và thumbnail 512px, mục tiêu thumbnail dưới 200 KB. Không chỉ tin contentType do client gửi. Hủy upload không đăng bài; cleanup dọn staging bỏ dở. Mỗi lần retry dùng ID cũ và kiểm tra trạng thái để tránh nhân đôi ảnh/thông báo.

## 5. Dữ liệu đề xuất, chưa áp dụng schema

| Đường dẫn | Trường / mục đích |
|---|---|
| groups/{gid}/moments/{mid} | authorId, authorNameSnapshot, hobbyNameSnapshot, caption, mediaPath, thumbnailPath, status, publishedAt, expiresAt |
| users/{uid}/momentUploads/{mid} | groupId, requestId, stagingPath, status, uploadDeadline; backend ghi, owner đọc trạng thái |
| users/{uid}/settings/momentNotifications | enabled, previewOnLockScreen; schema riêng, owner cập nhật |
| users/{uid}/momentGroupSettings/{gid} | muted; owner cập nhật |
| momentOutbox/{mid} | groupId, trạng thái fan-out/cursor/retry; server-only |
| momentOutbox/{mid}/deliveries/{uid} | eventId, trạng thái gửi/retry tới người nhận; server-only |
| Storage momentStaging/{uid}/{mid}/source | Client chỉ tạo ảnh của phiên upload hợp lệ, không cho người xem đọc |
| Storage groupMoments/{gid}/{mid}/{leaseId}/photo.jpg và thumb.jpg | Backend ghi/đọc; client nhận bytes qua getGroupMomentImage, direct SDK reads bị deny |

Moment công khai với nhóm chỉ có `ready` hoặc `retracted`; upload/processing/failed nằm trong upload session riêng. Trạng thái expired suy ra từ expiresAt, không cần chờ cron cập nhật status để chặn đọc. Đường dẫn media không phải URL tải công khai.

Index dự kiến: moments trong một nhóm theo status + expiresAt; outbox theo trạng thái/nextAttemptAt; cleanup collection-group moments theo expiresAt. Chỉ khai báo index thực sự dùng sau khi chốt query ở implementation.

## 6. Quyền xem và hết hạn ba giờ

- Tác giả phải là thành viên nhóm tại lúc xin upload và publish. Client không tự ghi authorId, publishedAt, expiresAt, status ready hay danh sách người nhận.
- Đọc một moment/media: đang đăng nhập, thuộc nhóm hiện tại, status ready và thời gian máy chủ chưa đến expiresAt. Người ngoài nhóm, đã mất membership, moment thu hồi/hết hạn đều bị từ chối.
- Firestore Rules: cho get theo các điều kiện trên; **không cho list trực tiếp** collection moments ở bản đầu. listGroupMoments chạy trên backend phải tự kiểm tra auth/membership và filter thời hạn, vì Admin SDK không chịu client Rules.
- Lý do dùng API danh sách: Firestore Rules không phải bộ lọc. Stream một collection chứa cả ảnh đã hết hạn có thể bị từ chối toàn query; chỉ lọc ảnh bằng đồng hồ client cũng không đủ cho bảo mật. App refresh khi mở trang/resume/nhận FCM và có nút tải lại.
- Điều chỉnh bước 1: Storage Rules chỉ kiểm tra upload session cho staging và đóng direct reads của published media. getGroupMomentImage kiểm tra membership/hạn dùng trước và sau IO, tránh download-token URL. Staging Rules cần default Firestore database/quyền liên kết Storage–Firestore; xác minh trước cloud deployment.
- App lấy mốc serverNow, tính thời gian trôi bằng clock đơn điệu và refresh khi resume. Đồng hồ điện thoại không quyết định hạn dùng ở backend. Hết hạn phải bỏ image bytes/cache của tính năng, kể cả màn xem đang mở; chuyển tài khoản cũng xóa cache/inbox theo UID.
- Chặn đọc tại expiresAt là độc lập với cleanup. Job dọn file có thể chạy muộn/retry; không hứa xóa vật lý chính xác từng giây. TTL Firestore chỉ là lớp dọn phụ nếu dùng, không làm đồng hồ hết hạn và không tự xóa ảnh Storage.
- Dữ liệu đã tải về, ảnh chụp màn hình hoặc preview Android đã render không thể thu hồi tuyệt đối từ máy người nhận. Hủy notification khi còn khả năng xử lý, cấu hình timeout Android và kiểm tra lại khi mở app; không dùng lời hứa “mọi bản sao biến mất đúng ba giờ”.

## 7. Thông báo có ảnh và độ tin cậy

Đề xuất **data message FCM + local notification Android**, để app kiểm tra đúng UID/membership/thời hạn trước khi tải thumbnail riêng tư qua getGroupMomentImage. Không nhúng ảnh vào payload, không dùng download URL có token lâu dài cho ảnh nhóm. Đây vẫn là phần thông báo dự kiến, chưa triển khai trong backend bước 1.

Payload tham chiếu: eventId ổn định, ownerId của người nhận, kind=moment, groupId, momentId, expiresAt và route `/community/groups/{gid}/moments/{mid}`. Tên/nội dung lấy từ moment đã được phép đọc; mọi ID/path phải validate.

| Tình huống | Cách xử lý |
|---|---|
| Foreground | Kiểm tra quyền → inbox/badge → banner có ảnh; Hyper đang chạy thì gộp để xem sau |
| Background / đóng app bình thường | Handler chuyển công việc tải ảnh/xác minh quyền sang Android WorkManager; worker khởi tạo SDK, kiểm tra UID/membership/expiry rồi tạo Big Picture notification |
| Ảnh tải chậm nhưng đã xác minh quyền | Text fallback với nút mở; không treo background handler để đợi ảnh |
| Không xác minh được quyền / đã hết hạn / đổi UID | Không hiện ảnh/popup dựa trên payload cũ; refresh khi app mở lại |
| Người nhận tắt thông báo | Vẫn có thể xem danh sách trong nhóm; backend và client đều tôn trọng enabled/muted/groups |
| App bị Force stop hoặc hệ điều hành hạn chế nền | Không cam kết push tức thời; danh sách được nạp lại khi mở app, phải ghi nhận riêng trong device test |

Đề xuất xin bật thông báo khoảnh khắc bằng một lời giải thích trong app, mặc định chưa bật cho đến khi người dùng chọn. previewOnLockScreen mặc định false: màn hình khóa chỉ hiện nội dung chung; khi mở khóa có thể xem ảnh. Tùy chọn này không thay quyền nhóm.

FCM dùng priority phù hợp thông báo hiển thị cho người dùng, TTL bằng thời gian còn lại tới expiresAt, không gửi nếu đã hết hạn. Dùng eventId/notification ID ổn định để giảm hiển thị trùng; outbox tránh mất công việc khi process bị ngắt. Firestore triggers/FCM không bảo đảm exactly-once, nên không tuyên bố server “gửi đúng một lần tuyệt đối”.

Handler FCM chỉ có ngân sách xử lý ngắn; không coi khoảng 30 giây của Flutter background isolate là bảo đảm tải ảnh sẽ xong. Đề xuất enqueue WorkManager ngay khi nhận message; thử expedited work cho thông báo ưu tiên cao, deadline không vượt expiresAt. Worker phải kiểm tra lại tài khoản và quyền khi thực sự chạy, vì công việc có thể bị trì hoãn. Nếu plugin Flutter không hỗ trợ cấu hình expedited cần thiết, đánh giá adapter Kotlin tại M0 thay vì giả định API đã có.

Tách notification channel và namespace ID của moment khỏi reminder. Sửa LocalReminders.sync chỉ hủy các ID reminder do nó quản lý; cancelAll chỉ dùng lúc logout/reset có chủ đích. Foreground và background cùng dùng quy tắc dedupe/expiry, không sinh hai thông báo cho một sự kiện.

**Thử nghiệm kỹ thuật cần làm sớm:** hai Android thật, app foreground/background/đóng bình thường; thử data-only FCM → tải private thumbnail → Big Picture. Nếu thiết bị thực không đáp ứng ổn định, báo hạn chế và review phương án vận chuyển trước khi chốt UI. Không tự đổi ảnh riêng tư thành public để làm notification chạy.

## 8. Các đợt triển khai và điều kiện hoàn tất

| Đợt | Công việc | Điều kiện chuyển tiếp |
|---|---|---|
| M0 — Thử nghiệm và chốt hợp đồng | Ghi nhận yêu cầu bổ sung; thử notification có ảnh trên hai máy; kiểm tra Storage/Functions/billing/region; phác thảo UI | Có log thực về background; xác định rõ mất quyền đọc và thời điểm dọn file; biết điều kiện deploy |
| M1 — Nền tảng dữ liệu/backend | Upload session, media processing, publish/list/retract, Rules, outbox, cleanup và kiểm thử emulator | Người ngoài nhóm bị deny; hết hạn chặn đọc dù file còn; retry không tạo moment mới |
| M2 — Đăng và xem | Camera/gallery, preview/progress/retry, danh sách nhóm, viewer/countdown, thu hồi | A đăng, B xem, C ngoài nhóm không xem; UI xử lý lỗi/quyền/expired và chuyển UID |
| M3 — Popup và push | Foreground banner, Hyper defer, Big Picture background, inbox/deep link, settings/mute, notification namespace | Hai máy nhận đúng người; không lộ ảnh sau đổi UID; đồng bộ lịch không xóa notification moment |
| M4 — Nghiệm thu/demo | Hết hạn/retry/offline tests, kiểm tra ba flow cũ, cập nhật traceability và tài liệu demo | Có evidence thật và danh sách hạn chế; backend deploy chỉ sau khi chủ dự án duyệt thay đổi cụ thể |

Mốc M0–M4 là đợt cho tính năng bổ sung, không đổi tên hay nâng trạng thái nghiệm thu các phase00–08 lịch sử.

## 9. File và dependency dự kiến

| Nhóm | Vị trí dự kiến |
|---|---|
| Model/interface/ViewModel | lib/models/group_moment.dart; lib/services/moment_repository.dart; lib/services/moment_media_service.dart; lib/viewmodels/moment_view_model.dart |
| Firebase adapter | lib/firebase/firebase_moment_repository.dart; lib/services/app_services.dart để inject |
| UI | lib/features/community/screens/moments/; gắn vào community_screens.dart |
| Routes/notifications | app_router.dart, route_paths.dart, firebase_device_services.dart, notification_background.dart, runtime_controller.dart; notifier riêng và local_reminders.dart |
| State/localization | Model inbox tương thích dữ liệu cũ, LocalOwnerStore, màn Settings và lib/l10n/messages.dart |
| Backend | functions/package.json, TypeScript source/tests; firebase.json bổ sung config Functions/emulator |
| Quyền/index/tests | firebase/firestore.rules, storage.rules, firestore.indexes.json; firebase/tests; Flutter unit/widget tests |
| Theo dõi yêu cầu | docs/design-traceability.md, data-model.md, full-manual-checklist.md và demo script cập nhật khi code thực sự thay đổi |

Thêm image_picker cho camera/gallery và cloud_functions cho callable, chọn/pin phiên bản tương thích Flutter dự án lúc triển khai. Phần Android WorkManager cần adapter/plugin phù hợp, quyết định sau thử nghiệm M0 và không giả định plugin hỗ trợ mọi loại expedited work. Firebase Auth/Firestore/Storage/FCM và flutter_local_notifications đã có. Backend TypeScript dùng Functions/Admin SDK và bộ xử lý ảnh như sharp; kiểm tra runtime hỗ trợ, license và pin dependency trước cài. Không đưa thêm state manager.

## 10. Ca kiểm thử tối thiểu

| Ca | Kết quả cần chứng minh |
|---|---|
| A/B cùng nhóm, C ngoài nhóm | B đọc được; C bị từ chối metadata/media/callable kể cả biết ID |
| Từ chối camera / hủy chọn ảnh / file giả hoặc quá lớn | Có thông báo phù hợp; không publish, không mất draft |
| Upload lỗi / publish retry / trigger chạy lại | Không nhân đôi moment; publishedAt/expiresAt cũ không đổi; có xử lý delivery trùng |
| App ở foreground/background/đóng bình thường | Popup/ảnh/push/deep link đúng trên thiết bị thật; ghi nhận điều kiện nhận |
| Hyper đang chạy | Không mở modal/ngắt timer; có inbox/badge để xem sau |
| Hết hạn trong khi viewer đang mở; chỉnh đồng hồ điện thoại | Ẩn nội dung, không mở lại; backend vẫn từ chối quyền đọc |
| Cleanup bị dừng hoặc lỗi xóa ảnh | Hết hạn vẫn chặn truy cập; job retry được và dọn lại idempotent |
| Tác giả thu hồi trước hạn / membership mất hiệu lực | Lần đọc/tải mới bị deny; thông báo cũ mở trạng thái không còn khả dụng |
| Tắt thông báo/mute nhóm / khóa màn hình | Tôn trọng lựa chọn; không tự đưa preview ảnh lên màn hình khóa |
| Logout A, đăng nhập B trên cùng máy, push A đến muộn | Không hiện ảnh/popup của A dưới tài khoản B; cache cũ được dọn |
| Đồng bộ/xóa lịch luyện tập | Notification moment không bị cancelAll ngoài ý muốn |
| Hồi quy ba flow cũ và reports PDF | Hobbies, Hyper/history, group/DM/RSVP, Rules PDF vẫn đúng |

Test tự động có fake clock gần ranh giới ba giờ. Nếu demo dùng thời hạn hai phút, chỉ cấu hình trên backend project demo/emulator riêng và ghi rõ; client không được tự gửi lifetime để rút ngắn/kéo dài trên project chính. Chạy thử một phiên đủ ba giờ trên cấu hình chính trước khi xác nhận hành vi ba giờ.

## 11. Điều kiện hạ tầng và quyết định còn cần review

- Các con số 5 MB/160 ký tự/kích thước thumbnail/tần suất cleanup là đề xuất sản phẩm, chưa phải quy định của giảng viên.
- Yêu cầu đầy đủ có nhóm và bạn bè; bản đầu đề xuất nhóm, phần kết bạn cần một đợt riêng. Chốt lộ trình này với nhóm/giảng viên khi review.
- Cần xác minh Storage hoạt động, quyền Functions/FCM/Storage–Firestore, region phù hợp và mức sử dụng dự kiến. Deploy Functions yêu cầu Blaze theo tài liệu Firebase; không giả định project hiện đã có billing.
- Có thể làm source và emulator tests trước. Bật billing, cấp quyền cloud hoặc deploy Rules/Functions là bước riêng do chủ dự án duyệt sau khi có code/config review được. Proposal không thực hiện các thao tác này.
- Đăng ảnh hết hạn được ghi là mở rộng Community của Lab 3 theo yêu cầu mới; không kéo theo Staff/Admin, web hoặc AI thuộc Final.

## 12. Tài liệu kỹ thuật tham khảo

- [Firebase: nhận FCM trong Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages) — foreground/background, quyền thông báo và giới hạn khi force-stop.
- [Firebase: mức ưu tiên Android](https://firebase.google.com/docs/cloud-messaging/android-message-priority) — ngân sách xử lý và cân nhắc tải nội dung trong background.
- [Firebase: lifespan của FCM](https://firebase.google.com/docs/cloud-messaging/customize-messages/setting-message-lifespan) — TTL là thời gian có thể giữ để gửi, không xóa notification đã hiện.
- [Firebase: Storage Rules kết hợp Firestore](https://firebase.google.com/docs/storage/security/rules-conditions) — membership/metadata checks, giới hạn hai document và quyền cross-service.
- [Firebase: Rules không phải filters](https://firebase.google.com/docs/firestore/security/rules-query) — thiết kế truy vấn phải phù hợp quyền.
- [Firebase: Firestore TTL](https://firebase.google.com/docs/firestore/ttl) — xóa không tức thời, không xóa subcollections hay file Storage.
- [Firebase: Firestore triggers](https://firebase.google.com/docs/functions/firestore-events) — event có thể lặp/không theo thứ tự, cần idempotence.
- [Firebase: bắt đầu Functions](https://firebase.google.com/docs/functions/get-started) — emulator và điều kiện Blaze khi deploy.

Tài liệu này mô tả phương án toàn tính năng. Source/kết quả backend bước 1 nằm trong báo cáo liên kết đầu tài liệu. Flutter đăng/xem ở [bước 2](moments-ui-step2-report.md), thông báo ở [bước 3](moments-alerts-step3-report.md), cleanup và QA local ở [bước 4](moments-cleanup-step4-report.md), cùng [hướng dẫn local](moments-local-run.md). Cloud deployment, lịch cleanup chạy thật và nghiệm thu hai máy/ba giờ ngoài đời chưa được thực hiện.
