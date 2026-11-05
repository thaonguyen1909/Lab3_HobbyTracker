> **Sắp xếp repository 03/11/2026:** Source app giữ ở root; yêu cầu/thiết kế/evidence/hồ sơ nộp gom vào docs/. 96 tests, analyze và APK build sau di chuyển đạt. Xem [mục lục](README.md) và [báo cáo](repository-layout-report.md). Không nâng trạng thái các gate cloud/ARTEMIS còn thiếu.

> **Ngôn ngữ — 03/11/2026:** Đã thêm Settings/Language với English và Tiếng Việt, lưu trên thiết bị; nội dung UI/validation/error/date/PDF và nhắc lịch do app tạo dùng ngôn ngữ đã chọn. 96/96 Flutter tests, analyze và APK build/cài đạt. Xem [localization report](localization-report.md); không nâng các gate cloud/ARTEMIS còn thiếu.

> **03/11/2026 — cập nhật mới nhất:** Đã sửa lỗi lưu Settings/refresh metadata bị đưa về Home và thông báo thành công treo ở các trang. Full suite 81/81, analyze sạch, build/cài Android đạt; xem [navigation/feedback report](navigation-feedback-report.md). Các kết quả cloud/ARTEMIS chưa đóng vẫn giữ trạng thái cũ.

> **Cập nhật sửa lỗi và môi trường 03/11/2026:** Android SDK/Pixel 9 đã khả dụng, APK debug đã build/cài; đăng nhập và Home đã chạy trong phiên này. Bản sửa timer, inbox, Settings recovery, chat/layout đạt 77 Flutter tests và 35 Rules emulator tests, analyze sạch. Xem [bugfix report](bugfix-report.md). Những dòng thiếu SDK/chưa cấu hình Firebase phía dưới là lịch sử; các gate hai tài khoản cloud, dịch vụ Console, Storage upload thật và ARTEMIS vẫn chưa đóng.

> Cập nhật giao diện Figma 03/11/2026: đọc `docs/figma-ui-report.md` trước. Quyền Figma đã được giải quyết; các ghi chú cũ nói Figma BLOCKED là lịch sử. Các gate Android/Firebase/ARTEMIS vẫn chưa được thay bằng PASS.

# Hobby Tracker — Bản tích hợp Phase 00–08 — 03/11/2026

**Trạng thái tổng thể: PARTIAL, chưa nghiệm thu 100%.** Người dùng đã đổi phạm vi sang làm toàn bộ các phase trong một đợt, không chờ xin phép từng phase. Source đã được mở rộng qua toàn bộ phạm vi Lab3. Final web/admin/AI vẫn ngoài phạm vi.

## Đã thực hiện

- Bảo toàn Firebase Auth Google/email, Register/Forgot, profile gate, linking, xác nhận logout và MVVM/Riverpod từ bản trước.
- My Hobbies: custom create/edit, 12 icon, 6 màu, Active/Interested, validation, tên trùng theo owner, canonical name reservation trong transaction và logical removal. Đổi priority giữ lịch/history. Xóa hobby gỡ lịch tìm được và ẩn mọi lịch gắn hobby đã archive, giữ lịch sử snapshot.
- Home: chọn ngày/tuần, tạo lịch và sắp xếp theo giờ; Hyper Mode dùng Stopwatch, start/pause/resume/reset, ghi chú, draft theo UID, restore ở trạng thái pause, chính sách pause khi rời; Finish dùng session ID ổn định và transaction history + plan completion. Không ghi lặp khi retry.
- Community: feed For You/Explore All, post/like/comment, create/join group, group chat, events/RSVP, Add to Home riêng, People opt-in, DM theo participant và privacy. Message/comment dùng stable draft ID và create-if-absent transaction để retry không ghi đè tin đã gửi.
- Settings: profile, external shortcuts, thông báo, Hyper prefs, privacy và 7 theme được lưu trên Firestore. Token màu và component chung giữ từ baseline. Theme có khác biệt màu, bo góc, elevation và Cyber monospace; chưa chứng minh khớp Figma toàn bộ.
- PDF bằng font Unicode có license đi kèm; export/share tách upload. Storage adapter có progress/URL và rules theo UID, MIME, kích thước tối đa 10 MB.
- FCM foreground/background/terminated-entry handler, local inbox theo UID, whitelist deep links, xin quyền Android; token registry riêng tư và cleanup khi logout. Local reminders, weekly summary một lần kế tiếp và âm thanh completion đã có code, cần thiết bị thật kiểm chứng.
- Analytics event plan và instrumentation không gửi tên/email/nội dung vào parameters; Crashlytics handled/fatal hooks, test crash có debug flag + xác nhận; Remote Config community_enabled và feed_limit có default/failure state và ảnh hưởng UI/query.
- Sinh native Android template, application ID **vn.prm393.hobbytracker**, INTERNET/POST_NOTIFICATIONS/boot receivers/desugaring, Firebase Gradle plugins chỉ áp dụng khi có google-services.json.
- Chuẩn bị ARTEMIS theo SDK commit thật, 17 ca ×3 lượt và Pro exploratory opt-in; tài liệu data model, rules, review, checklist và kịch bản demo.

## Kiểm chứng đã chạy

| Kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| Flutter analyze | PASS, không có issues sau sửa cuối | docs/evidence/full/analyze-final.log |
| Flutter unit/widget tests | PASS, 63/63 | docs/evidence/full/tests-final.log |
| Firestore + Storage emulator tests | PASS, 35/35 | docs/evidence/full/rules-all.log |
| Routes/UI | Các đích signed-in và 6 Settings sections đã render ở 360/412dp, không overflow trong test | test/full_ui_test.dart |
| 7 theme persistence | Widget test đổi theme, giữ hobby data | test/full_ui_test.dart |
| PDF exporter | Tạo PDF thật từ 50 history fixtures có tiếng Việt | test/full_viewmodels_test.dart |
| UI previews | 10 PNG từ Flutter widget harness, dữ liệu test và font test đã nạp | test/goldens/ |
| Android APK | BLOCKED: không có Android SDK; chưa tạo APK | docs/evidence/full/android-build.log |
| ARTEMIS | NOT RUN: không có Android/daemon/model key; SDK source và cú pháp test đã kiểm tra | e2e_test/README.md |
| Firebase cloud/Console | NOT RUN: chưa có project config, owner test accounts hoặc device | docs/full-manual-checklist.md |
| Figma live parity | BLOCKED: lần truy cập hiện có thiếu Editor permission | docs/evidence/02/work-review-2026-11-03/figma-access.json |

Ảnh PNG là render thật của code trong widget tests với fixture, **không phải ảnh Android/Firebase thật hoặc bằng chứng Figma parity**. Test doubles chỉ nằm dưới test/. Các raw logs cũ/failing trước sửa được giữ để truy vết; log `*-final` và `rules-all.log` là kết quả cuối tương ứng.

## Trạng thái từng phase

| Phase | Source hiện có | Gate còn thiếu | Trạng thái phase |
|---|---|---|---|
| 00 | Tài liệu, requirements review, traceability | 3 HTML lệch hash lịch sử, formal Lab2/Figma approval | PARTIAL |
| 01 | Shell, 4 tabs, design system, tests | Android launch/back/device acceptance | PARTIAL |
| 02 | Auth/profile/guards/link/logout và test | Google picker, email reset, Console Users, 2 UID thật | PARTIAL |
| 03 | Hobbies CRUD/validation/name transaction/rules | Firestore thật + Android E2E | PARTIAL |
| 04 | Lịch, timer, notes, draft, history idempotence | Background/process-kill/device timing | PARTIAL |
| 05 | Feed/group/events/People/DM/chat thật qua adapter | Hai tài khoản thật và native E2E | PARTIAL |
| 06 | Settings, 7 theme, 360/412 widget renders | Figma visual review và full accessibility audit | PARTIAL |
| 07A | PDF/share/upload adapter, Storage tests | Cloud upload/progress/URL trên device + Console; owner xác minh điều kiện dịch vụ | PARTIAL |
| 07B | FCM/Analytics/Crashlytics/RC/reminder source | Console/notification permission/3 native lifecycle states | PARTIAL |
| 08 | Unit/widget/rules tests, E2E SDK suite, review notes | ARTEMIS 3 runs, exploration, PR review/commit trail, final docs/submission/slides/video/StudentID | PARTIAL |

Không dừng triển khai vì Phase02 chưa PASS trong đợt này; chỉ giữ các gate nghiệm thu đúng thực tế. Không phase nào được nâng thành PASS bằng fixture hoặc code source.

## Hạn chế cần biết

- Native Android template chưa được build vì môi trường thiếu SDK. Sự tương thích Gradle/native plugins cần được kiểm tra trên máy Android đã cài toolchain; Dart analyze/test không chứng minh phần đó.
- FCM cần ownerId và path trong data payload. Inbox và local handlers lọc theo owner; notification payload do Android tự hiển thị ở background cần sender tôn trọng preferences. Không gửi PII trong push. Data-only background delivery và reminders/inexact scheduling phụ thuộc OS/device và phải kiểm thử.
- Draft timer ghi định kỳ khoảng 5 giây và khi pause/nhập ghi chú. Process-kill đột ngột có thể mất phần active time chưa checkpoint; restore luôn pause để tránh tự tính giờ ngoài ý muốn.
- Logical removal không hard-delete history. Lịch tạo đồng thời với thao tác archive được ẩn và không thể tiếp tục dùng hobby đã archive. Đây là thích nghi đã ghi traceability, cần review với chủ dự án.
- Feed/nhóm hiện tập trung vào các thao tác của flow; chưa có moderation, role Staff/Admin hoặc server scheduler. Không có dữ liệu mẫu trong production. Group member count/suggestion personalization sâu hơn cần đối chiếu Figma khi được cấp quyền.
- Bản báo cáo PDF và outline slide trong gói là tài liệu review kỹ thuật, chưa phải hồ sơ nộp đã có đủ docs/evidence/StudentID/video. Không tạo Git commits/PR/tag hoặc deploy để giả lịch sử.

## Việc cần bạn cung cấp/thực hiện một lần cho toàn dự án

1. Cài Android SDK, đăng ký application ID vn.prm393.hobbytracker trong Firebase, thêm SHA-1/SHA-256, bật Google và Email/Password, chạy FlutterFire configure.
2. Review/deploy Firestore và Storage rules vào đúng test project khi đã xác minh quyền/dịch vụ. Không có billing hoặc production deployment nào được thực hiện ở Work.
3. Dùng hai tài khoản test, chạy checklist toàn bộ flow/6 services trên Android và chụp Console evidence. Không gửi password/service-account private keys vào chat.
4. Cấp Figma permission hoặc export chính thức; chốt D01/D05 về formal docs/design/handoff/provenance.
5. Thiết lập ARTEMIS host/model key, chạy 17 ca ×3 và exploratory, cung cấp repo/StudentID, review PR và quay video live để hoàn tất Phase08.

## Theo mẫu AGENTS

PHASE: 00–08 | Integrated Lab3 implementation
STATUS: PARTIAL
SCOPE: Toàn bộ phase trong một đợt; Final không triển khai.
CHANGED FILES: docs/full-changed-files.json.
DESIGN TRACEABILITY: docs/design-traceability.md; live Figma BLOCKED.
ACCEPTANCE GATES: PASS 63 Flutter tests/35 rules tests/analyzer; BLOCKED Android/cloud/Figma; ARTEMIS NOT RUN.
COMMANDS ACTUALLY RUN: raw logs under docs/evidence/full; Flutter 3.47.9, Dart 3.13.7, Firestore 1.19.8, Storage rules runtime 1.1.3.
SECURITY & DATA CHECK: deny-by-default; UID/private paths; canonical hobby names; group/DM membership/privacy; PDF type/size/owner rules.
OPEN DECISIONS / RISKS: mục hạn chế và docs/full-manual-checklist.md.
COMMIT/PR/DEPLOY: NOT CREATED.
READY FOR HUMAN REVIEW: YES, source/tests/integration readiness, chưa nghiệm thu 100%.
NEXT PHASE: Toàn bộ phase đã được xử lý trong phạm vi; tiếp theo là đóng các gate còn thiếu trên môi trường thật.
