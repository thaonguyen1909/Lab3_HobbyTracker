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
