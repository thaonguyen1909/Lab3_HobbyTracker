> **Cập nhật Work 03/11/2026 (ưu tiên hơn ghi chú lịch sử bên dưới):** Phase02 PARTIAL; `flutter analyze` đạt, 41 unit/widget tests và 9 local Firestore Rules tests đạt. Android/Firebase thật/Figma parity chưa có evidence; Phase03 NOT STARTED. Chi tiết tại [Phase02 report](phase-02-report.md) và [manual acceptance](phase-02-manual-acceptance.md). Những dòng “NOT RUN/missing SDK/source only” cũ bên dưới mô tả thời điểm viết, không thay kết quả lần này.

# Kế hoạch acceptance ban đầu — phase 00

DRAFT: xác định coverage để triển khai, chưa phải pytest suite hoặc báo cáo chạy test. Phase08 phải hoàn thiện hướng dẫn ARTEMIS, fixtures và assertions theo SDK/commit đã pin.

Mỗi case bắt đầu từ precondition độc lập, dùng account test; không phụ thuộc thứ tự. TC01–TC22 khi tự động hóa chạy ít nhất 3 lần/case, báo pass rate/average time/traces và nguyên nhân flaky. Kiểm tra giá trị quan sát được chứ không chỉ SUCCESS. TC23 là phiên khám phá riêng 15–30 phút. Tất cả hiện NOT RUN.

| ID | Flow | Precondition | Steps | Expected observable result | Type | Phase | Result |
|---|---|---|---|---|---|---|---|
| TC01 | Auth/F01 | Signed-out; tài khoản Google test riêng | Google Sign-In → chọn tài khoản; lặp lại với Cancel và mất mạng | Thành công thấy Home + 4 tab; cancel/offline ở Login có thông báo và retry | Native/error | 02 | NOT RUN |
| TC02 | Auth | D03 APPROVED; signed-out | Register: password mismatch → sửa → submit; Forgot: email sai → sửa → gửi | Lỗi giữ form; kết quả auth/mail thật, không simulated success; auth guard chặn link riêng tư; cùng email qua Google/password không tự gộp account hoặc tạo profile trùng | Validation | 02 | NOT RUN |
| TC03 | F01 | Signed-in; owner chưa có hobby tên test | Tạo hobby, chọn icon/màu/priority; thử thiếu tên, thiếu priority và duplicate; relaunch | Đúng tên/icon/color/priority sau tải lại; lỗi không ghi đè hoặc mất form; hai priority đều dùng được | Happy/error | 03 | NOT RUN |
| TC04 | F02 | Signed-in; có 1 hobby | Home → Schedule hai hoạt động khác giờ cùng ngày; đổi ngày rồi quay lại | Đúng 2 lịch, thứ tự tăng theo giờ và đúng ngày; khi không hobby có đường Create | Happy/empty | 04 | NOT RUN |
| TC05 | F02 | Signed-in; hobby và lịch test | Start → pause → chờ → resume → notes → reset/cancel → Finish double tap | Pause không tăng; reset giữ notes; một record đúng duration/notes; linked schedule complete | Timer/error | 04 | NOT RUN |
| TC06 | F01/F02 | Có hobby, lịch và record snapshot | Details → Edit → đổi priority → save; mở Details/Hyper và re-login | ID/lịch/history giữ nguyên; Interested không bị khóa; inaccessible ID có recovery | Regression | 03–04 | NOT RUN |
| TC07 | F03 | Hai account test, feed truy cập hợp lệ | Đăng post, like/unlike và comment; account kia reload; thử mất mạng khi gửi | Post/comment persist; like không bị đếm đôi; lỗi giữ draft và có retry | Happy/error | 05 | NOT RUN |
| TC08 | F03 | Signed-in; chưa join group test | Tạo nhóm hoặc Join → mở conversation; lặp Join | Membership một lần; chat đúng group; không tạo tin welcome giả | Happy | 05 | NOT RUN |
| TC09 | F03 | Có event, account chưa RSVP | RSVP → xem Home → Add to Home → bấm lại → hủy RSVP | RSVP chưa tạo lịch; Add tạo đúng một lịch; hủy chỉ bỏ linked event schedule | Happy/alternative | 05 | NOT RUN |
| TC10 | F03 | Account A/B, DM được policy cho phép; C không là thành viên | People → Message → Send → B xem; C thử truy cập conversation | Tin nhận thật và persist; C bị deny read/write; lỗi mạng giữ draft; Back về Chats | Integration/security | 05 | NOT RUN |
| TC11 | Settings/Auth | Signed-in với cache private test | Mở Settings → Sign Out cancel → confirm → back/deep link | Cancel giữ phiên; confirm về Login, không mở private route và không lộ cache qua account khác | Happy/security | 02/06 | NOT RUN |
| TC12 | Settings | Signed-in; cài đặt mặc định | Lưu profile, music/search, reminder, autoTimer/pauseOnExit, privacy; relaunch | Từng giá trị persist và hành vi đúng; shortcut mở ngoài; save failure có message/rollback | Happy/error | 06 | NOT RUN |
| TC13 | Theme | Có hobby/lịch/record | Chuyển lần lượt 7 theme và relaunch | Theme đúng, selected label rõ; data không đổi; không overflow ở 360/412dp | UI | 06 | NOT RUN |
| TC14 | Report | Signed-in; dataset và tổng duration biết trước; Storage khả dụng | Export → Upload; thử mất mạng và account khác đọc/ghi folder | PDF khớp số liệu; progress/URL/Console thật; private path deny account khác; lỗi có retry | Integration/error | 07A | NOT RUN |
| TC15 | FCM | Android13+; Console test sender; 3 app states | Xin quyền; nhận/tap message khi foreground/background/terminated; thử từ chối quyền | Có evidence mỗi state; inbox lưu, tap mở đúng màn; không crash khi permission denied | Native | 07B | NOT RUN |
| TC16 | Components/a11y | Shell/component preview hoặc screen đã code | Kiểm tra C01–C10 variants; keyboard/focus, semantics, text scaling tại 360/412 | 48dp targets, body≥14sp, labels/selected/error rõ; loading/empty/error/retry không overflow | Widget/UI | 01/06 | NOT RUN |
| TC17 | F02 lifecycle/remove | Có focus draft, hobby, schedule và history | Đổi tab theo pauseOnExit; restore draft; remove hobby confirm/cancel | Đúng elapsed policy; reset giữ notes; remove chỉ xóa hobby/lịch liên quan, giữ history snapshot | Alternative | 04 | NOT RUN |
| TC18 | Isolation/privacy | A/B/C và group/private fixtures | Đọc/ghi private doc, membership/chat, DM theo policy; thử sửa author/owner | Owner/member allowed đúng; outsider denied; shape và senderId sai bị deny | Rules | 02–05 | NOT RUN |
| TC19 | Remote Config | Có defaults trong app và demo area | Đổi 2 tham số hành vi thật qua Console; fetch/activate; thử offline | Hành vi thay đổi không rebuild; hiển thị giá trị nguồn/default; offline dùng fallback | Integration | 07B | NOT RUN |
| TC20 | Crashlytics | Chỉ test build/demo area; test account | Gây lỗi handled thực; chạy test crash có confirm; mở lại | Console có nonfatal + crash, UID/custom key; UI thông báo lỗi thật; không crash ngoài demo | Integration | 07B | NOT RUN |
| TC21 | Analytics | Debug mode, kế hoạch event đã duyệt | Thực hiện ≥7 events theo flow, kiểm tra params/types/UID ở DebugView hoặc Logcat | Mọi event trong plan có bằng chứng; không PII; ít nhất 1 ARTEMIS test kiểm tra event logged | Integration | 07B/08 | NOT RUN |
| TC22 | Navigation/states | App installed; fixture empty/data/error hợp lệ | Đi qua 4 tab, 15 destinations, 6 Settings categories; kích hoạt data error/retry | Back đúng cha; không dead end; từng data screen loading/data/empty/error; retry phục hồi | E2E | 06/08 | NOT RUN |
| TC23 | Exploratory | Pro profile, thiết bị/test account riêng | Khám phá không script 15–30 phút: keyboard, mạng, navigation, long text, repeat submit | Lưu thời lượng thực, traces và issues; không tạo pass rate giả từ phiên chưa chạy | Exploratory | 08 | NOT RUN |

## Bằng chứng cần lưu sau khi chạy

`docs/evidence/<phase>/`: command, device/OS/tool versions, run ID/trace, ảnh/replay thật, kết quả actual vs expected, giải thích failed/skipped/flaky. Không tạo file ảnh giả. Test fixtures chỉ emulator/test; submission build dùng nguồn dữ liệu thật. Các case composite nên tách thành pytest functions ngắn, vẫn trace về ID gốc.

Console evidence phải cùng Firebase project ID với cấu hình app. ARTEMIS Flash cho regression, Pro cho exploratory; pin commit, Python≥3.12/uv/ADB theo PDF. Phase 02 widget/fake auth tests và Firestore Rules emulator tests đã được viết nhưng CHƯA CHẠY vì môi trường thiếu Flutter/Firebase. ARTEMIS chưa triển khai (Phase 08).
