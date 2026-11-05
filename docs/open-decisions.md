> **Cập nhật Work 03/11/2026 (ưu tiên hơn ghi chú lịch sử bên dưới):** Phase02 PARTIAL; `flutter analyze` đạt, 41 unit/widget tests và 9 local Firestore Rules tests đạt. Android/Firebase thật/Figma parity chưa có evidence; Phase03 NOT STARTED. Chi tiết tại [Phase02 report](phase-02-report.md) và [manual acceptance](phase-02-manual-acceptance.md). Những dòng “NOT RUN/missing SDK/source only” cũ bên dưới mô tả thời điểm viết, không thay kết quả lần này.

# Quyết định và đầu vào còn mở — Lab 3

Bản gốc 02/11/2026; audit đối chiếu lại 03/11/2026: D05 được mở lại do 3 HTML mismatch. OPEN/PROPOSED không phải phê duyệt. Chủ sở hữu là vai trò cần nhóm phân công, chưa tự suy ra tên thành viên.

| ID | Nguồn / vấn đề | Đề xuất và ảnh hưởng | Người chốt | Hạn cần chốt | Trạng thái |
|---|---|---|---|---|---|
| D01 | Specification mục11; PDF Lab3 prerequisite; Figma audit | Đã truy cập 6 trang nhưng 0 reactions/flow start; trang hiện chia theo chức năng, không chứng minh đúng cấu trúc formal Lab2. Nối 3 flow + recovery và xác nhận design chính thức, hoặc xin chấp nhận HTML; chưa có bằng chứng giảng viên duyệt | Nhóm + giảng viên | Trước nghiệm thu design parity | OPEN |
| D02 | Lab3 mục3/6: cloud upload | Xác minh điều kiện Storage/chi phí hiện hành với project; owner duyệt hạ tầng hoặc giảng viên duyệt ngoại lệ. Không tự nâng gói; local PDF chưa đủ | Chủ Firebase + giảng viên | Trước 07A | OPEN |
| D03 | Figma 7:8/7:52/7:101 và Lab3 mục6 | Người dùng xác nhận Google Sign-In + email/password thật để giữ Register/Forgot; bỏ demo bypass ở submission. Cần thiết kế xử lý cùng email/hai provider trước triển khai | Người dùng — xác nhận trong chat 02/11/2026 | Trước 02 | APPROVED — phạm vi, chưa triển khai |
| D04 | Lab3 mục9: tên repo và thông tin nộp | Nhóm cung cấp StudentID/thành viên và chốt PRM393_Lab03_<StudentID>; giữ remote hiện tại đến khi được giao đổi | Nhóm | Trước nộp | OPEN |
| D05 | Kiểm chứng provenance 7 tệp Lab2/Lab3 | Đóng gói đủ 7 tệp nhưng hash/kích thước của 3 HTML lệch manifest 02/11. Giữ nguyên tệp, cần bản nguồn tại đường dẫn gốc để đối chiếu hoặc xác nhận cập nhật provenance. `docs/source-provenance.md` | Chủ nguồn Lab2 + nhóm | **Trước Phase00 PASS** | **REOPENED / BLOCKED** |
| D06 | Figma và HTML khác vai trò | Người dùng xác nhận giao diện theo Figma, hành vi theo Specification/HTML; Light làm baseline đầu tiên, mọi khác biệt có DX ID. Không thay thế phê duyệt giảng viên hoặc review chi tiết còn mở | Người dùng — xác nhận trong chat 02/11/2026 | Trước 01 | APPROVED — baseline |
| D07 | Creator Figma Interested selected; HTML priority=null | Đề xuất giữ priority chưa chọn để đáp ứng validation; snapshot là trạng thái minh họa | Nhóm | Trước 03 | PROPOSED |
| D08 | Chưa có state đầy đủ/network recovery trong thiết kế | Đề xuất C07–C09 và state templates trong handoff; cập nhật Figma và review layout/contrast | Nhóm | Trước 06 | PROPOSED |
| D09 | Lab3 mục3 yêu cầu demo area; UI chưa có đầy đủ | Đề xuất Settings/Profile chứa export-upload, notification center, RC values và crash actions có confirm; không thêm tab | Nhóm | Trước 07A/07B | PROPOSED |
| D10 | Privacy toggle và notification options của HTML chưa enforce | Chốt DM policy/visibility thành allowed/denied matrix; chốt reminder local vs FCM, âm thanh/weekly summary để không hứa behavior giả | Nhóm | Trước 05/06 | OPEN |
| D11 | Prototype timer Date.now và session draft | Chốt khôi phục khi background/process kill, notes/draft và lifecycle policy; monotonic timer cho active duration | Nhóm | Trước 04 | OPEN |
| D12 | Repo private; Lab3 mục9/11 yêu cầu link mở được | Chốt cách cấp quyền giảng viên và kiểm tra access trước deadline, không tự publish source | Nhóm + giảng viên | Trước 08 | OPEN |

Phase00 có thể review bộ tài liệu với các mục OPEN nêu rõ. D03/D06 đã được người dùng xác nhận; không đồng nghĩa các mục còn mở hoặc toàn bộ handoff được phê duyệt. Chưa bắt đầu phase01. Final là tham khảo riêng, không thêm gate cho Lab3.

## Xác nhận người dùng ngày 02/11/2026

> Đồng ý giao diện theo Figma, hành vi theo Specification/HTML; dùng Google và email/password thật.

Áp dụng cho D06 và D03. Login hỗ trợ Google và email/password; Register tạo tài khoản email/password thật; Forgot Password gửi yêu cầu reset thật qua Firebase Authentication. Không lưu password trong Firestore. Cùng email qua hai provider cần xử lý account linking/conflict theo xác thực hợp lệ, không tự gộp tài khoản chỉ vì email trùng. Chi tiết SDK và trường hợp lỗi sẽ được thiết kế/kiểm thử tại phase02.

D01 về prototype và bằng chứng chấp nhận giảng viên vẫn OPEN. D08/D09 về state/demo area cùng các mục khác giữ trạng thái riêng; xác nhận này không cấp quyền sửa Figma, deploy, billing hoặc chuyển phase.

## Phase 01 implementation status (03/11/2026)

Owner has indicated local Flutter/Android/Git/Figma prep is ready, but did not attach `flutter doctor -v`, original HTML provenance or lecturer approval evidence. Therefore D01/D05 remain OPEN, and Android build/run remain NOT RUN. Phase01 code uses the previously documented D06 baseline as a provisional implementation reference. No previously open decision was silently approved.

## Kết quả Work Phase02 — 03/11/2026

- D03: Google/email/reset/linking source và tests được cập nhật; không đồng nghĩa Firebase cloud/device acceptance. Tên Register đã bổ sung.
- D06: tokens và MVVM/Riverpod giữ nguyên; Figma create_session bị trả lỗi không có Editor access ngày 03/11, nên live parity còn BLOCKED.
- D01/D05 vẫn OPEN/BLOCKED. D02 thuộc Storage sau này, chưa kích hoạt billing.
- User đã cho phép Phase03 sau khi Phase02 hoàn thành; không cần approval lặp lại, nhưng phase gate hiện chưa đạt.


## Integrated user scope 03/11/2026

User authorizes all Lab3 phases in a single pass. No further permission request at phase transitions. Evidence gates remain. Source-level decisions: UID subcollections, canonical name keys, archive rather than history deletion, private public-profile defaults with explicit DM opt-in, local inexact reminders and paused draft restore. These are implemented and documented for review, not teacher/Figma approval. D01/D05 source/Figma gaps remain; D02 cloud Storage eligibility/billing still owner-controlled. Native ID vn.prm393.hobbytracker is ready to register. No billing/cloud deploy/PR/Git history was created.


### Live Figma UI request — 03/11/2026

User authorizes updating all app UI to Figma. Read access now works. Live Figma is the current visual target over older HTML geometry, without replacing actual Firebase services with prototype simulations. Groups & follows permission semantics and preferred fixed reminder time are unresolved backend/product gaps; do not expose fake supported choices. See docs/figma-ui-report.md. Owner: project owner; no new billing/deployment authorization.

## Update after user-authorized audit repairs — 03/11/2026

- Owner configured Android Firebase JSON, Google Auth/SHA and Firestore during this chat. SDK/emulator/build startup is no longer BLOCKED. Two-account cloud isolation and Console evidence remain NOT RUN; prior local test passes do not imply cloud acceptance.
- Storage service/billing authorization D02 remains OPEN: user/owner must decide; no upgrade/deploy performed. Live upload remains BLOCKED until eligibility/config and real test evidence.
- DX20/DX21 accessibility/chat/recovery changes need human visual review against Figma. Groups & follows and Preferred reminder time retain their documented gaps; owner/design decision needed, not silently treated as complete.
- ARTEMIS and formal source/instructor provenance remain unresolved; docs/bugfix-report.md records current evidence without altering reference inputs.

## Language scope — 03/11/2026

User approved an English/Vietnamese Settings choice. Implementation stores language per device so Login/offline UI can use it without Firestore/schema deployment. Cross-device synchronization and translating user-authored/sender-authored content are not requested. No billing or cloud deployment performed. Existing Lab3 open decisions remain unchanged.

## Yêu cầu bổ sung Khoảnh khắc 3 giờ — 04/11/2026

Người dùng cho biết giảng viên muốn thông báo kèm ảnh khi bạn bè/thành viên nhóm đăng ảnh hoạt động và ảnh mất sau ba giờ; người dùng yêu cầu đề xuất hướng triển khai. Chi tiết tại [moments-implementation-proposal.md](moments-implementation-proposal.md). Đây là yêu cầu bổ sung qua trao đổi, không sửa nội dung tài liệu gốc.

| Mục | Hướng đề xuất / điểm cần review | Trạng thái |
|---|---|---|
| MOM01 — Phạm vi | Nhóm đã tham gia trước; quan hệ bạn bè hai chiều làm sau vì app hiện chưa có friendship | PROPOSED |
| MOM02 — Hết hạn | Chặn truy cập và ẩn trong app sau ba giờ từ publish trên backend; cleanup file riêng, không hứa thu hồi bản sao đã tải | PROPOSED |
| MOM03 — Popup có ảnh | Banner foreground, tránh ngắt Hyper; data-only FCM + private thumbnail + local notification; thử độ tin cậy trên hai máy sớm | PROPOSED, NOT TESTED |
| MOM04 — Hạ tầng | Kiểm tra Storage/Functions/Blaze/cross-service Rules; source và emulator trước; billing/deploy cần owner duyệt thay đổi cụ thể | OPEN, NO DEPLOY AUTHORIZATION |

Yêu cầu này không bổ sung Staff/Admin, web hoặc AI thuộc Final.

### Cho phép triển khai bước backend đầu tiên — 04/11/2026

Người dùng: “được hãy triển khai bước đầu tiên giúp tôi nhé”. Áp dụng nhóm trước, upload/xử lý ảnh, quyền đọc và hết hạn ba giờ trên emulator; không cấp quyền billing/deploy. Backend đã có source và 60 test local đạt, không nâng trạng thái toàn bộ feature hay Lab 3. Xem [báo cáo thực tế](moments-backend-step1-report.md).

MOM01/MOM02 được áp dụng cho bước backend này. Điều chỉnh kỹ thuật: ảnh phục vụ qua getGroupMomentImage có auth/expiry checks, direct Storage reads bị deny sau khi emulator tái hiện download-token URL. MOM03 popup/push chưa bắt đầu; MOM04 cloud và dependency audit chưa đóng. Dọn file định kỳ và tích hợp Flutter thuộc bước tiếp theo.

### Cho phép triển khai Flutter bước 2 — 04/11/2026

Người dùng: “triển khai bước 2 giúp tôi nhé”. Đã nối camera/gallery → preview → upload/publish → danh sách nhóm → viewer/countdown/thu hồi bằng MVVM/Riverpod và adapter Firebase thật. Không dùng dữ liệu fixture trong app. Bổ sung chế độ debug demo emulators để phát triển khi chưa được phép deploy cloud; email/password local tách khỏi Google/cloud.

UI mới là phần mở rộng theo yêu cầu trong chat, dùng thành phần/tokens hiện có; chưa có frame Figma riêng hoặc xác nhận giảng viên. Bản nháp giữ caption/hobby theo UID, ảnh chỉ trong bộ nhớ; idempotent retry được kiểm thử trong màn đăng, chưa bảo đảm phục hồi publish sau process restart. MOM03/MOM04, friendship, cleanup định kỳ và kiểm thử hai máy/ba giờ ngoài đời vẫn mở. Kết quả thực tế tại [báo cáo bước 2](moments-ui-step2-report.md).

### Cho phép triển khai thông báo bước 3 — 04/11/2026

Người dùng yêu cầu “triển khai bước 3 cho tôi nhé”. MOM03 đã có source outbox/fan-out, reference inbox, popup, Hyper defer, opt-in/mute, private thumbnail WorkManager và Android local notification. Local emulator chứng minh Rules/luồng dữ liệu, không chứng minh push thật. Preview mặc định PRIVATE theo hệ điều hành; expedited chỉ khi xác định được API ≥31. Native worker/cold-start/lockscreen cần kiểm tra hai máy. MOM04 cloud/billing/deploy chưa được cấp quyền; cleanup/retention, friendship và dependency audit vẫn mở. [Báo cáo bước 3](moments-alerts-step3-report.md) không nâng trạng thái toàn bộ Lab 3 thành PASS.

### Bước 4 Khoảnh khắc — 04/11/2026

Người dùng yêu cầu triển khai và tiếp tục bước 4. Đã có source cleanup có giới hạn/lease/retry, backfill metadata, xóa file/expired inbox/receipt và local retention. Lựa chọn triển khai để review: grace 5 phút, sweep orphan tối thiểu 24 giờ, outbox giữ 24 giờ sau expiresAt, marker local một ngày, tombstone ID giữ lâu dài để ngăn replay. Đây không phải con số do PDF giảng viên quy định.

MOM04 deployment/billing/bucket soft delete/retention/IAM và test hai máy vẫn OPEN. App Check, dependency audit, friendship và formal ARTEMIS/submission evidence chưa đóng. [Báo cáo bước 4](moments-cleanup-step4-report.md) tách local PASS với nghiệm thu cloud NOT RUN, không tự nâng toàn bộ Lab 3 thành PASS.

### Đợt 5 — cho phép deploy với điều kiện giữ gói, 04/11/2026

Người dùng chọn “Triển khai lên Firebase hiện tại, không đổi gói cước”; tin nhắn “N” sau đó được người dùng xác nhận là gửi nhầm và yêu cầu tiếp tục. Đây là quyền deploy Moments lên đúng hobbytracker-6ace6, không cấp quyền nâng billing/chuyển dự án. Tài khoản CLI đã được chọn lại cho repo, dự án GET 200. Preflight thực tế: billingEnabled=false, bucket cấu hình 404; do Functions yêu cầu Blaze nên deploy BLOCKED theo ràng buộc hiện tại. Không bật API/billing, tạo bucket hoặc deploy riêng Rules trong lượt này. Xem [báo cáo đợt 5](moments-cloud-step5-report.md).

### Chốt thay nơi upload và backend Khoảnh khắc — 04/11/2026

Người dùng cho biết thầy cho phép Cloudinary/AWS S3 thay phần upload, sau đó chốt Firebase Auth/Firestore/FCM + Cloudinary + backend Node.js riêng và yêu cầu chỉnh sửa. Người dùng chọn chạy backend trên PC qua USB trước; đã có tài khoản Cloudinary nhưng chưa cung cấp cloud name/credentials tại thời điểm ghi nhận. Đây là nguồn quyết định trong chat, không sửa PDF/HTML và không tự nghiệm thu upload PDF của Lab 3.

MOM04: bỏ phụ thuộc Blaze/Storage/Cloud Functions trong đường production Khoảnh khắc mới. Không đổi gói Firebase. Source HTTP backend, Cloudinary media adapter và Flutter adapter đã có; hosting/Rules/indexes chưa deploy. Owner cần cấu hình Cloudinary key/secret và Firebase Admin credentials trong file ignored tại máy; không gửi secret qua chat. Worker PC chỉ chạy khi backend hoạt động. Authenticated asset support/quota của tài khoản thật, hai máy FCM và kỳ hết hạn ba giờ thực tế vẫn NOT RUN. Xem moments-cloudinary-run.md và moments-cloudinary-report.md. Legacy emulator/tests giữ để hồi quy; không phải cloud acceptance. Không tạo tài khoản/hosting/chi phí mới.

### Cloudinary sẵn sàng, IAM deploy còn thiếu — 04/11/2026

Người dùng đã sửa Cloudinary config; readiness và upload/download/delete ảnh thử authenticated đạt trên provider thật. Firestore deploy qua CLI bị 403 thiếu serviceusage.services.use trước khi Rules/indexes thay đổi. Người dùng xác nhận không quản lý IAM và cần owner cấp quyền. Không tự cấp IAM hoặc dùng cách khác để bỏ qua gate. Owner action và giới hạn target tại moments-owner-deploy-handoff.md; không nâng billing/không Functions/Storage deploy.

### Owner đã gỡ blocker IAM — 04/11/2026

Ảnh người dùng cung cấp cho thấy Service Usage Consumer đã được thêm. Probe live xác nhận serviceusage.services.use=true và đúng tài khoản CLI; deploy chỉ Firestore Rules/indexes đã thành công, Rules khớp local, 5 composite indexes và inbox expiry index đều READY. Không cần owner cấp thêm IAM cho lỗi cũ. Backend local 8787 đã chạy, health/outbox query đạt, APK debug API mới đã cài/mở trên R5CY81PSMAJ; quan sát ảnh thật trong list. Tổng feature PARTIAL, native FCM/background/hai máy/ba giờ còn lại chưa nghiệm thu. Không đổi billing, Functions/Storage hoặc tài khoản IAM. Evidence hiện tại tại moments-retest-report.md ưu tiên hơn ghi chú BLOCKED lịch sử.

### Chốt luồng lập lịch nhanh theo thiết kế mới — 04/11/2026

Nguồn: người dùng gửi ảnh trước/sau và yêu cầu chỉnh đúng phần sau. Người dùng xác nhận lặp hằng ngày/hằng tuần có ngày kết thúc. Cả Active/Interested vẫn được chọn; tile lấy hobbies thật, không thay bằng catalog. Form mặc định ngày Home đang chọn, auto title có thể sửa, thời lượng custom lưu integer minutes.

Implementation choices: 1–1440 phút để phù hợp history max24h; tối đa 100 occurrence/giao dịch; repeat materialize thành plans độc lập tới inclusive end date, default end +28 ngày. Transaction owner-scoped và stable per-form request IDs tránh duplicate/reset completed sessions khi retry; không hứa offline queue hoặc process-restart recovery. Không thêm cron, group notification hoặc whole-series editing.

Rules thay đúng điều kiện duration (int/range thay enum), đã qua 33 emulator Rules tests và deploy/readback đúng hobbytracker-6ace6. 166 Flutter tests đạt; sau polish font/tap target UI rerun 8 ca. Cần review/native save+sync+reminder thật trước khi nghiệm thu toàn phase04. Không commit/push; xem quick-schedule-update.md.
