# Flutter handoff — DRAFT FOR REVIEW

Nguồn: reference/Specification.html mục 05–08, Prototype.html và Figma theo traceability. Chỉ là thiết kế triển khai phase 00; chưa tạo widget/service hoặc pin package. Kiến trúc dự kiến: Flutter + Riverpod + go_router + MVVM, Android. docs/architecture.md được hiện thực ở phase01 trước code feature.

## Quy ước chung áp dụng mọi màn

- Layout responsive SafeArea/scroll, 360/412dp; constraints ở design/DESIGN.md áp dụng mọi màn/dialog, hỗ trợ keyboard và Semantics.
- Component tái sử dụng C01–C10; mỗi màn dùng theme token. SDK chỉ trong service, không trong widget.
- Screen data loading → data/empty/error + Retry; ViewModel giữ state. Form idle/submitting/success/error; lỗi giữ nội dung, submit disable. Auth không có dữ liệu rỗng dùng trạng thái signed-out thay vì fake empty list.
- GoRouter auth guard: chưa đăng nhập về /auth/login, auth thành công /home; signout hủy subscription/xóa cache UID trước mở account khác. Back quay về cha hợp lệ, không tạo vòng lặp.
- Nếu route param không tồn tại/không có quyền: thông báo + back/retry phù hợp; không spinner vô hạn. Dữ liệu cập nhật sau server success, optimistic update phải có rollback.

## Handoff cho 15 đích điều hướng

### S01 — Login

- **Layout:** Hero, email/password, Google CTA đã được xác nhận D03; Register/Forgot bên dưới.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `7:8`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 02.
- **Interactions:** Google thành công → Home; hủy hoặc lỗi giữ màn và cho thử lại; email/password dùng Firebase Authentication thật theo D03 đã duyệt.
- **Navigation:** `/auth/login`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `LoginScreen` → `AuthViewModel` → AuthService. Acceptance `TC01`; PLANNED.

### S02 — Register

- **Layout:** Form tên, email, mật khẩu, xác nhận.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `7:52`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 02.
- **Interactions:** Kiểm tra không khớp, giữ form; đăng ký email/password thật theo D03 đã duyệt; Back → Login.
- **Navigation:** `/auth/register`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `RegisterScreen` → `AuthViewModel` → AuthService. Acceptance `TC02`; PLANNED.

### S03 — Forgot Password

- **Layout:** Email, gửi yêu cầu, nút Back.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `7:101`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 02.
- **Interactions:** Thông báo kết quả thật, không giả gửi mail; email lỗi có recovery; gửi reset thật theo D03 đã duyệt.
- **Navigation:** `/auth/forgot-password`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `ForgotPasswordScreen` → `AuthViewModel` → AuthService. Acceptance `TC02`; PLANNED.

### S04 — Home

- **Layout:** Hero Hyper, tuần 7 ngày, Schedule, danh sách theo ngày, History.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:44`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 04.
- **Interactions:** Chọn ngày/tuần; sort tăng theo giờ; không hobby → Create; History nằm trong Home, không route riêng.
- **Navigation:** `/home`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `HomeScreen` → `HomeViewModel` → ScheduleRepository + ActivityRepository. Acceptance `TC04`; PLANNED.

### S05 — Hyper Mode

- **Layout:** Tên hobby, đồng hồ, Start/Pause/Reset, shortcut, notes, Finish.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:147`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 04.
- **Interactions:** Nhận hobbyId và scheduleId tùy chọn; pause không tăng thời gian; reset giữ notes; Finish một record; back theo pauseOnExit.
- **Navigation:** `/home/hyper`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `HyperScreen` → `HyperViewModel` → TimerService + ActivityRepository + ScheduleRepository + ExternalLinkService. Acceptance `TC05`; PLANNED.

### S06 — My Hobbies

- **Layout:** Collection card, priority, Create, Details/Edit/Hyper.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:232`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 03.
- **Interactions:** Tự tạo hobby; đổi priority không xóa lịch/history; rỗng có CTA; trùng tên không ghi đè.
- **Navigation:** `/hobbies`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `HobbiesScreen` → `HobbiesViewModel` → HobbyRepository. Acceptance `TC03`; PLANNED.

### S07 — Hobby Detail

- **Layout:** Tên/icon/màu, mô tả, Edit/Hyper, Upcoming sessions.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:287`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 03.
- **Interactions:** Không có kế hoạch có Schedule; hobby không tồn tại/không quyền có thông báo và Back; lịch sort ngày/giờ.
- **Navigation:** `/hobbies/:id`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `HobbyDetailScreen` → `HobbyDetailViewModel` → HobbyRepository + ScheduleRepository. Acceptance `TC06`; PLANNED.

### S08 — Community Feed

- **Layout:** Subtab, For You/Explore All, post, Like/Comment/Write.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:514`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 05.
- **Interactions:** Post/like/comment phải persist; For You ưu tiên Active nhưng không khóa khám phá; retry không nhân bản like.
- **Navigation:** `/community/feed`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `FeedScreen` → `FeedViewModel` → PostRepository. Acceptance `TC07`; PLANNED.

### S09 — Groups

- **Layout:** Danh sách nhóm, mô tả, số thành viên, Create/Join.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:724`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 05.
- **Interactions:** Join → chat đúng nhóm; tạo nhóm và membership đồng bộ; retry không tăng thành viên hai lần.
- **Navigation:** `/community/groups`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `GroupsScreen` → `GroupsViewModel` → GroupRepository + ChatRepository. Acceptance `TC08`; PLANNED.

### S10 — Activities

- **Layout:** Event cards, thời điểm, RSVP và Add to Home riêng.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:815`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 05.
- **Interactions:** RSVP không tạo lịch; Add to Home cần Going và chưa thêm; hủy RSVP bỏ lịch liên kết theo prototype, không sửa lịch khác.
- **Navigation:** `/community/activities`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `ActivitiesScreen` → `ActivitiesViewModel` → EventRepository + ScheduleRepository. Acceptance `TC09`; PLANNED.

### S11 — People

- **Layout:** Danh sách người dùng được phép công khai và nút Message.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:889`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 05.
- **Interactions:** Không dùng profile giả; tạo/mở DM khi chính sách privacy cho phép; bị từ chối có thông báo.
- **Navigation:** `/community/people`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `PeopleScreen` → `PeopleViewModel` → ProfileRepository + ChatRepository. Acceptance `TC10`; PLANNED.

### S12 — Chats

- **Layout:** Danh sách DM/nhóm và preview tin cuối.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:969`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 05.
- **Interactions:** Chỉ chat của thành viên; rỗng có đường sang Groups/People; chạm → Conversation.
- **Navigation:** `/community/chats`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `ChatsScreen` → `ChatsViewModel` → ChatRepository. Acceptance `TC10`; PLANNED.

### S13 — Conversation

- **Layout:** Header/back, bubbles, composer và Send.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:1052`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 05.
- **Interactions:** Tin rỗng không gửi; gửi lỗi giữ draft/retry; không phải thành viên bị deny; Back → Chats.
- **Navigation:** `/community/chat/:id`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `ConversationScreen` → `ConversationViewModel` → ChatRepository. Acceptance `TC10`; PLANNED.

### S14 — Settings

- **Layout:** Profile, 6 nhóm cài đặt, Sign Out cuối trang.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:1114`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 06.
- **Interactions:** Mở category, Sign Out có confirm; cancel giữ phiên; confirm xóa cache theo UID và về Login.
- **Navigation:** `/settings`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `SettingsScreen` → `SettingsViewModel` → ProfileRepository + SettingsRepository + AuthService. Acceptance `TC11`; PLANNED.

### S15 — Settings Detail

- **Layout:** Back, tiêu đề category, form/toggle/theme lựa chọn.
- **Components:** C01 Button, C02 Input khi có form, C03 Card cho nội dung, C05 AppBar; C04 Nav cho top-level; C07–C09 cho dữ liệu async. Figma `9:1230`.
- **States:** quy ước chung phía trên; bổ sung các trạng thái đặc thù trong tương tác bên dưới. Không có dữ liệu thật trước phase 06.
- **Interactions:** Các category ở bảng phụ bên dưới; lưu có feedback/rollback khi lỗi; Back về Settings; section lạ có recovery.
- **Navigation:** `/settings/:section`; cha/tab và Back theo mô tả; không thêm route vào bottom nav ngoài 4 tab.
- **UI constraints:** token + SafeArea/360/412/48dp/14sp; nội dung dài được scroll; không cố định frame 410×930.
- **Implementation target:** `SettingsDetailScreen` → `SettingsViewModel` → ProfileRepository + SettingsRepository + NotificationService. Acceptance `TC12`; PLANNED.

## Settings Detail — sáu biến thể

- **Profile & Account** (`/settings/profile`, `9:1230`): Form tên ≥2 ký tự, handle chữ/số/_, bio, màu avatar; Save về Settings; lỗi giữ form. Layout header/back → form/toggles → feedback. Loading/retry khi hydrate; save failure giữ draft và báo lỗi; constraints chung áp dụng.

- **Connected Apps** (`/settings/apps`, `9:1306`): Chọn Spotify/YouTube và Google/Cốc Cốc; chỉ là shortcut ngoài, không OAuth. Layout header/back → form/toggles → feedback. Loading/retry khi hydrate; save failure giữ draft và báo lỗi; constraints chung áp dụng.

- **Notifications** (`/settings/notifications`, `9:1367`): Reminder time/lead, messages/groups/weekly summary; phân biệt preference với quyền Android; refusal có hướng dẫn. Demo area/inbox sẽ bổ sung theo Lab3, D09. Layout header/back → form/toggles → feedback. Loading/retry khi hydrate; save failure giữ draft và báo lỗi; constraints chung áp dụng.

- **Hyper Preferences** (`/settings/hyper`, `9:1450`): autoTimer, pauseOnExit và tùy chọn âm thanh theo thiết kế; giữ draft khi đổi màn. Layout header/back → form/toggles → feedback. Loading/retry khi hydrate; save failure giữ draft và báo lỗi; constraints chung áp dụng.

- **Privacy & Safety** (`/settings/privacy`, `9:1511`): DM policy/visibility phải được bảo vệ tại Rules và query, không chỉ toggle trên client; ma trận policy cần chốt D10. Layout header/back → form/toggles → feedback. Loading/retry khi hydrate; save failure giữ draft và báo lỗi; constraints chung áp dụng.

- **Appearance** (`/settings/appearance`, `9:1697`): 7 theme, selected label; persist; thay theme không reset dữ liệu. Layout header/back → form/toggles → feedback. Loading/retry khi hydrate; save failure giữ draft và báo lỗi; constraints chung áp dụng.

## Form/dialog và validation

| UI | Layout/component | State / validation / tương tác | Navigation / constraints |
|---|---|---|---|
| Create/Edit Hobby | Sheet, live preview, form, 12 icon, 6 swatch, 2 priority cards | Tên trim 2–50, description ≤180 theo HTML; priority bắt buộc; duplicate case-insensitive theo owner; edit giữ ID/lịch/history | Cancel/Back đóng không ghi; keyboard + scroll; đồng bộ uniqueness cần transaction/key design phase03 |
| Add Schedule | Hobby select, date, time, duration, title | duration choices 15/30/45/60/90/120; title ≤70; date/time/hobby required; ghi lỗi giữ form | Chưa hobby → Create; Save về ngày đã chọn trên Home; chưa có Figma frame riêng |
| Choose Hyper | Hobby list | Chọn hobby, resume draft đang có; không có hobby → Create | Sheet đóng về Home; không khóa Interested |
| Post / Comments | Topic + textarea / comment list + input | post 3–800; comment nonempty ≤300; không nhận author từ client tùy ý | Save cập nhật feed/comments; cancel giữ collection; error retry |
| Create Group | Name, hobby, description | name 3–60, hobby ≤50, desc ≤300; membership một lần | Save về Groups; Join mở đúng chat; không fake welcome message |
| Sign Out | Confirm/cancel | Chưa confirm không đổi phiên; confirm loading/error rõ | Từ Settings; success về Login; xóa private cache |
| Reset/Remove | Confirm/cancel | Reset >3s có confirm theo HTML, giữ notes; Remove hobby giữ history và xóa linked schedules | Không ảnh hưởng hobby khác; cleanup data cần policy/atomic strategy phase03/04 |

## Model/service contracts dự kiến

| Model | Trường và nguyên tắc | Nguồn |
|---|---|---|
| Profile/Settings | uid, displayName, handle, bio, avatarColor; theme/music/search/reminder/pauseOnExit/privacy; không password | Prototype profile/settings |
| Hobby | id, ownerId, name, normalizedName, description, iconKey, colorKey, priority | F01 |
| Schedule | id, ownerId, hobbyId? hoặc eventId?, startsAt, durationMinutes, title, done | F02 và Add to Home |
| ActivityRecord | stable sessionId, ownerId, hobbyId, hobbyName/icon/color snapshot, elapsedSeconds, notes, finishedAt | F02; HTML ms được chuyển đơn vị rõ ràng |
| Post/Comment/Like | authorId/uid, text/topic, createdAt; like document theo uid | F03; không embed mảng vô hạn |
| Group/Membership/Chat/Message | creatorId, memberIds hoặc membership docs, participants, senderId, sentAt | F03; chọn schema/quy mô tại phase05 |
| Event/RSVP | event metadata, uid, going; không pending staff approval | F03 |
| Notification/Report | id, ownerId, receivedAt/deepLink/read state; report period/fileSize/storagePath | Lab3 demo area |

Timestamp UTC khi lưu, hiển thị theo timezone người dùng; duration không âm. Collection paths, query/index và Rules được chốt khi implement, không phải schema deployed. Per-user CRUD; participant-only chat; public profile projection tách private data. Firebase 6 dịch vụ có adapter tiêm phụ thuộc, ReportExportService tách ReportUploadService. Không custom backend/Staff/Admin/Gemini trong phạm vi hiện tại.

## Ràng buộc dữ liệu và recovery

Timer dùng monotonic elapsed trong phiên; lifecycle/restart phải có policy khôi phục rõ trước phase04, không chỉ Date.now ticks. Finish có stable sessionId và atomic record + schedule completion để retry không nhân bản. Không tuyên bố persist timer sau process kill đã giải quyết.

Privacy options phải map thành query và Rules; xem D10. Permission denied không đổi thành empty state. Logout xóa dữ liệu cục bộ riêng của account, dù HTML giữ browser state. Storage bắt buộc upload thật để nghiệm thu 07A; cấu hình billing chưa được duyệt. Auth và visual/behavior baseline đã được người dùng xác nhận tại D03/D06; demo area và các mục khác giữ trạng thái riêng ở open-decisions. Trường hợp cùng email qua Google/password cần xử lý provider conflict/linking dựa trên xác thực hợp lệ; không tự gộp account hoặc tạo hồ sơ thứ hai. Bổ sung assertions tại phase02 trước nghiệm thu.

## Acceptance và phạm vi

Các case TC01–TC23 ở docs/test-plan.md là kế hoạch NOT RUN. Shell có thể chuẩn bị phase01 sau review; chưa triển khai phase01 trong công việc này. Muốn nghiệm thu app cần test thực tế, console evidence và UI review; handoff không thay thế bằng chứng.
