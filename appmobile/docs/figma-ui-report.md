> **Cập nhật sửa lỗi và môi trường 03/11/2026:** Android SDK/Pixel 9 đã khả dụng, APK debug đã build/cài; đăng nhập và Home đã chạy trong phiên này. Bản sửa timer, inbox, Settings recovery, chat/layout đạt 77 Flutter tests và 35 Rules emulator tests, analyze sạch. Xem [bugfix report](bugfix-report.md). Những dòng thiếu SDK/chưa cấu hình Firebase phía dưới là lịch sử; các gate hai tài khoản cloud, dịch vụ Console, Storage upload thật và ARTEMIS vẫn chưa đóng.

# Hobby Tracker — Figma UI update, 03/11/2026

PHASE: 06 | Live Figma UI/UX applied across integrated Lab 3 app
STATUS: PARTIAL — implementation/rendering checked; exact visual and native acceptance still open

## Nguồn đã đọc

File Figma `5JiJtLyXN6DEpC1LycQPBb`, trang `01 · Tổng` (0:1). Đã truy cập thành công và lấy design context + ảnh cho 30 frame: 23 màn hình/trạng thái chính và 7 preview theme. `docs/design/figma-source.json` lưu node ID; `docs/design/figma-context/` lưu nội dung truy xuất thực tế, đường dẫn asset được đổi thành file local. Không sửa thiết kế Figma.

## Đã thay đổi

- Font Inter được đóng gói trong app cùng giấy phép OFL; font PDF DejaVu giữ nguyên.
- Dùng màu Figma cho cả 7 theme, gồm background, paper, ink, muted, primary, on-primary, soft, border, hero. Không còn sinh các theme phụ từ seed color. Cyber dùng góc vuông và font Inter theo bản Figma; 6 theme còn lại giữ góc bo.
- Đưa 260 file SVG gốc về `assets/figma`, kèm ánh xạ và kiểm kê SHA-256/kích thước. Các thành phần dùng chung chọn đúng biểu tượng tương ứng và tint theo theme; họa tiết hero dùng đúng asset riêng của từng theme.
- Header thương hiệu, tên/ảnh đại diện từ tài khoản thật; bottom navigation 4 tab, indicator 46×32, icon 19, nhãn 9, tổng cao 76.
- Sign in / Create account / Reset password: hero, nhãn trường bên ngoài ô nhập, thứ tự nội dung và bố cục theo Figma; giữ Google Sign-In và Firebase thật.
- Home: hero mint/theme, tiêu đề hai màu, điều khiển chuyển tuần, 7 ngày, lịch theo ngày, thẻ lịch gọn, Start, lịch sử/empty state.
- Hyper Mode: đồng hồ tròn 230, trạng thái, start/pause/resume/reset, thẻ mở nhạc/tìm tài liệu, ghi chú, Finish. Giữ nguyên ViewModel, timer active-time, draft và idempotent Finish.
- My Hobbies: eyebrow, hàng tiêu đề/Create, hướng dẫn, empty state; chi tiết có thẻ hobby và Upcoming sessions. Form create/edit có preview trực tiếp, 12 icon theo thứ tự Figma, 6 màu, 2 priority, Cancel/Save; giữ validation và draft khi lỗi.
- Community: tiêu đề/giới thiệu dùng chung, thanh Feed/Groups/Activities/People/Chats một hàng, bộ lọc feed, avatar và post cards; nhóm, hoạt động, hồ sơ và danh sách chat được định dạng lại; khung chat mint và composer ngang. Tin nhắn vẫn đi qua repository và quyền Firebase.
- Settings: profile card, danh sách 6 mục với icon, bố cục từng mục, grid 7 theme; lựa chọn ứng dụng/theme/notification/hyper/privacy lưu ngay khi chọn; profile có Save rõ ràng. Sign Out dùng bottom sheet xác nhận.
- Kiến trúc MVVM/Riverpod và các luồng dữ liệu/security không đổi. Không thêm dữ liệu demo vào production.

## Kiểm tra đã thực thi

| Kiểm tra | Kết quả / bằng chứng |
|---|---|
| flutter pub get | PASS, thêm flutter_svg 2.2.4 để render SVG gốc, lockfile được cập nhật |
| flutter analyze --no-pub | PASS — No issues found. Xem `docs/evidence/figma/analyze.log` |
| flutter test --no-pub --reporter expanded | PASS — 67/67. Xem `docs/evidence/figma/tests-final.log`; bao gồm test cũ và test giao diện mới |
| Render widget tại 360, 410, 412dp | `test/figma_ui_review_test.dart`, 30 ảnh mỗi kích thước, tổng 90 ảnh ở `test/figma_review/` |
| Review ảnh | Đã xem contact sheet toàn bộ 30 trạng thái tại 410dp và ảnh riêng. Đây là ảnh widget harness với fixture trong test, không phải ảnh Android/Firebase thật |
| flutter build apk --debug --no-pub | BLOCKED: thiếu Android SDK; log `docs/evidence/figma/android-build.log` |
| Firebase Rules | Không sửa rules/schema trong lần này. Kết quả 35/35 ở `docs/evidence/full/rules-all.log` thuộc lượt tích hợp trước; không phải chạy mới |
| Figma pixel diff tự động | NOT RUN; không có tuyên bố khớp từng pixel hoặc 100% |

## Khác biệt chức năng phải giữ rõ

1. Figma là prototype: các chữ Demo, simulated login/reset, dữ liệu người dùng mẫu và local-only chat không đưa vào production. App dùng Firebase thật; thêm Google, loading/error/retry và các công cụ báo cáo cần cho Lab 3.
2. Khung viền điện thoại 4px/góc bo 28 trong Figma là khung trình bày, không vẽ thành viền bên trong ứng dụng Android. Kích thước có thể thay đổi theo safe-area, bàn phím, font scale và dữ liệu thật.
3. Body giữ 14sp để đọc dễ, trong khi nhiều nhãn nhỏ của Figma là 12sp. Giữ vùng chạm tối thiểu 48dp; không tuyên bố đã đạt WCAG.
4. Privacy: backend hiện hỗ trợ bật/tắt nhận direct chat và công khai hồ sơ. Lựa chọn **Groups & follows** trong Figma chưa có mô hình follow/quyền tương ứng, nên chưa được trình bày như chức năng đã hoạt động. Không hạ security rules để mô phỏng nó.
5. Notifications: có nhắc trước theo phút và quyền thiết bị; trường **Preferred reminder time** trong Figma chưa được triển khai như một lịch giờ cố định. Không thêm nút Preview notification giả thành công. FCM và reminder cần test trên Android thật.
6. Số thành viên nhóm, số liệu like/comment và tên hội thoại chỉ dùng dữ liệu có thể đọc hợp lệ; không sao chép số 142/12/23 hay người dùng mẫu từ thiết kế. Người chưa có public profile được hiển thị tên hội thoại chung, không lộ UID trong UI.
7. Thêm hoạt động, xóa lịch/hobby, xuất PDF, chẩn đoán và linking Google là các chức năng tích hợp có thêm so với screenshot tĩnh. RSVP và Add to Home vẫn là 2 hành động riêng.
8. Register vẫn dùng minimum password theo cơ chế Firebase hiện có; dòng 8+ của prototype không được dùng để mô tả sai validation hiện tại. Priority bắt buộc chọn rõ, không mặc định ngầm.
9. Còn cần kiểm tra typography/spacing chi tiết trên Android, tất cả màn hình ở font lớn, keyboard overlap, TalkBack và các trạng thái dữ liệu dài/offline. Các bản render chứng minh bố cục chạy, không đủ để nghiệm thu 100% visual.

## Còn thiếu để nghiệm thu

- Android SDK/emulator hoặc máy thật; build và kiểm tra tất cả luồng Firebase, các theme và responsive trên thiết bị.
- Đối chiếu cuối cùng tại cùng viewport/font với Figma, ghi nhận/sửa các sai số còn lại; hiện chưa có pixel-diff toàn bộ.
- Hoàn thiện/được quyết định cho Groups & follows và Preferred reminder time; đây là gap có thật, không đánh dấu PASS.
- Các gate cloud/ARTEMIS/slide/video của dự án Lab 3 vẫn theo `docs/full-manual-checklist.md`.

CHANGED FILES: theme, shared widgets, 4 feature screen files, auth screens/panel, assets/font, pubspec/lock, UI tests, docs; xem `docs/figma-changed-files.json`.
DESIGN TRACEABILITY: `docs/design/figma-source.json`, `docs/design-traceability.md`.
SECURITY & DATA CHECK: chỉ tầng UI; không sửa Firestore/Storage rules, SDK repositories, timer business logic hay quyền người dùng.
COMMIT/PR/DEPLOY: NOT CREATED.
READY FOR HUMAN REVIEW: YES — bản sửa và bằng chứng có trong ZIP; chưa nghiệm thu toàn bộ dự án.
NEXT PHASE: phạm vi all-phases đã được cho phép; các gate native/cloud còn BLOCKED.

## Correctness / usability follow-up — 03/11/2026

DX20: Calendar now uses >=48dp day targets with horizontal scrolling on narrow widths; nav labels 9->12sp and bar grows with text scale. This is an accessibility adaptation to Figma; approval pending, not exact pixel parity.
DX21: Conversation keeps composer outside a bounded scrolling message list, newest messages at bottom. Settings controls rollback and offer Retry on save failure; privacy explains sender opt-in. Lab3 diagnostic tools remain accessible in a clearly labeled collapsed section.
Current screenshots/tests from the earlier Figma capture are historical, not new images of these changes. Current widget tests render routes at 360/410/412 and test large text; visual review on Pixel 9 was limited to observed screens. See bugfix-report.md for actual evidence and remaining gates.

## Navigation/feedback follow-up — 03/11/2026

DX22 removes persistent success cards from page content. Success auto-hides after 3 seconds and can be closed; errors remain inline with dismissal/retry. UID-only session gating keeps Settings/features and unsaved forms open on name/token/provider updates. Full Flutter suite now 81/81; APK installed and Connected Apps native smoke observed. Exact Figma parity and broader cloud/device acceptance remain pending. See navigation-feedback-report.md.

## Bilingual UI — 03/11/2026

DX23 adds Settings/Language at the user's request. English/Vietnamese copy is centralized, including forms/errors and picker localization. User text and brand names stay unchanged. 96 Flutter tests pass; both locales render at 360/412, selected screens at 200% text; native English/Vietnamese samples observed after installing APK. This supersedes the earlier note that mixed UI language remained unaddressed. OS/Google screens are controlled by their own language settings; no complete pixel-parity claim.
