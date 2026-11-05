# Hobby Tracker — Design system / DRAFT FOR REVIEW

Nguồn: Specification mục 02–06, DesignArchive và Figma node 4:2; đối chiếu tại docs/figma-html-comparison.md. Bản biên soạn phase 00, không phải export Figma hoặc phê duyệt giảng viên.

## Baseline được người dùng xác nhận

Ngày 02/11/2026: giao diện theo Figma, hành vi theo Specification/HTML (D06); Google Sign-In + email/password thật (D03). Light là chuẩn đầu tiên. Các thay đổi chi tiết còn lại và chấp nhận giảng viên chưa được suy ra từ xác nhận này.

## Mục tiêu và người dùng

Sinh viên 18–24 tuổi: Minh cần bắt đầu hobby và kết nối tự nguyện; Khoa cần duy trì luyện tập, giảm xao nhãng và thấy kết quả. 9 cuộc phỏng vấn trong slide là AI-simulated. Target kiểm chứng, chưa phải kết quả: tạo hobby ≤60s, schedule ≤45s, lưu duration/notes không mất dữ liệu, từ nhóm đến chat ≤3 thao tác.

## Information architecture

Auth tách khỏi app. Bottom navigation theo thứ tự Home / Community / My Hobbies / Settings. History trong Home; Community có Feed/Groups/Activities/People/Chats; Conversation là màn con. Settings có 6 category; Sign Out ở cuối Settings và có confirm. Danh sách màn/route đầy đủ ở docs/design-traceability.md.

## Token → Flutter

| Token | Giá trị baseline | Mapping |
|---|---|---|
| primary | #087F72 | ColorScheme.primary |
| text | #213D36 | onSurface |
| muted | #4F6F63 | ThemeExtension.muted |
| background | #F7FAF7 | scaffold/surface |
| soft | #E7F5ED | selected/container |
| border | #D8E9DF | outline |
| spacing | 4/8/12/16/20/24/32 | AppSpacing constants |
| radius | controls 10–12, card 16, hero 21 | AppRadii |
| typography | page title 26, section 17, body ≥14 | TextTheme; responsive text scale |
| elevation | card nhẹ; không copy shadow khung điện thoại | AppElevation; giá trị Flutter xác minh khi phase01 |

Thông số là baseline Specification, không khẳng định toàn bộ Figma đã bind token. Font system theo nền tảng; cần review sai khác font khi Flutter render. Primary/error/success phải dùng nhãn/icon cùng màu; chọn semantic colors và kiểm tra contrast trước nghiệm thu. Không hardcode style trong screen.

## Component và trạng thái

Dùng C01–C10 trong traceability. Buttons có loading/disabled chống submit đôi; input có label/error không mất text; card có semantics nếu bấm được; nav selected có label; dialog focus/keyboard/back/cancel; loading có semantics; empty có next action; error có retry. Checkbox nhìn thấy 18×18 trong metadata nhưng vùng chạm Flutter phải ≥48×48.

## Bảy theme

| Theme | Primary tham khảo CSS | Hình thái |
|---|---|---|
| Light | #087F72 | mint, rounded, nhẹ |
| Dark | #88BAFF | nền đêm, xanh lạnh |
| Energetic | #D54A20 | cam ấm, offset shadow |
| Cyber | #00E6DA | góc cắt, grid, monospace accent |
| Art | #9C508B | giấy/pastel, bo bất đối xứng |
| Sad | #70698B | tím xám, tương phản dịu nhưng đủ đọc |
| Rainy Day | #347C98 | xanh sương, waterglass |

Nguồn chi tiết: Prototype CSS data-theme; đây không chỉ recolor. Lưu theme qua SettingsRepository, không đổi data. Mỗi theme phải qua contrast và text scale checks; chưa được chứng nhận accessibility.

## Constraints

SafeArea, layout co giãn và scroll tại 360/412dp; ảnh Figma 410×930 không là kích thước cứng. Hit target ≥48dp, body ≥14sp, normal contrast mục tiêu ≥4.5:1; selected/error không chỉ dựa màu. Keyboard không che submit/composer; Semantics cho Create, Schedule, timer, Finish, RSVP, Send và nav. Reduced motion; không thêm trang giới thiệu dài vào app.

## Trạng thái dữ liệu

Mỗi ViewModel có loading/data/empty/error, retry; form có idle/submitting/success/error. Giữ draft khi lỗi, disable submit lúc pending. Snapshot Firestore là nguồn persist; không dùng sample posts/people của HTML trong bản nộp. Chi tiết mỗi màn xem docs/design/handoff/flutter-handoff.md.
