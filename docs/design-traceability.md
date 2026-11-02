> **Cập nhật Work 03/11/2026 (ưu tiên hơn ghi chú lịch sử bên dưới):** Phase02 PARTIAL; `flutter analyze` đạt, 41 unit/widget tests và 9 local Firestore Rules tests đạt. Android/Firebase thật/Figma parity chưa có evidence; Phase03 NOT STARTED. Chi tiết tại [Phase02 report](phase-02-report.md) và [manual acceptance](phase-02-manual-acceptance.md). Những dòng “NOT RUN/missing SDK/source only” cũ bên dưới mô tả thời điểm viết, không thay kết quả lần này.

# Truy vết thiết kế — phase 00

Ngày đối chiếu: 02/11/2026. Trạng thái: DRAFT FOR REVIEW; mọi route/widget/ViewModel là đề xuất, chưa có code. Không dùng bảng này làm bằng chứng app đã chạy.

Nguồn: [Specification](requirements/reference/Specification.html#screens) mục 03–08, [Prototype](requirements/reference/Prototype.html), [DesignArchive](requirements/reference/DesignArchive.html), Figma và PDF Lab 3 mục 3–7. Bằng chứng đọc Figma: [cấu trúc](evidence/00/figma-structure.json), [node inventory](evidence/00/figma-node-inventory.json).

## Màn hình → triển khai → kiểm thử

15 là số đích điều hướng theo Specification. Figma có 23 component giao diện + 7 theme preview: gồm dialog và 6 category Settings riêng; không cộng chúng vào 15 rồi tuyên bố có thêm yêu cầu màn hình.

| ID | Màn / Figma | Route đề xuất | Widget / ViewModel | Nguồn dữ liệu | Phase | Test | Trạng thái |
|---|---|---|---|---|---|---|---|
| S01 | [Login](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=7-8) | `/auth/login` | `LoginScreen` / `AuthViewModel` | AuthService | 02 | TC01 | SOURCE IMPLEMENTED; Firebase/device NOT RUN |
| S02 | [Register](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=7-52) | `/auth/register` | `RegisterScreen` / `AuthViewModel` | AuthService | 02 | TC02 | SOURCE IMPLEMENTED; Firebase/device NOT RUN |
| S03 | [Forgot Password](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=7-101) | `/auth/forgot-password` | `ForgotPasswordScreen` / `AuthViewModel` | AuthService | 02 | TC02 | SOURCE IMPLEMENTED; Firebase/device NOT RUN |
| S04 | [Home](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-44) | `/home` | `HomeScreen` / `HomeViewModel` | ScheduleRepository + ActivityRepository | 04 | TC04 | PLANNED |
| S05 | [Hyper Mode](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-147) | `/home/hyper` | `HyperScreen` / `HyperViewModel` | TimerService + ActivityRepository + ScheduleRepository + ExternalLinkService | 04 | TC05 | PLANNED |
| S06 | [My Hobbies](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-232) | `/hobbies` | `HobbiesScreen` / `HobbiesViewModel` | HobbyRepository | 03 | TC03 | PLANNED |
| S07 | [Hobby Detail](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-287) | `/hobbies/:id` | `HobbyDetailScreen` / `HobbyDetailViewModel` | HobbyRepository + ScheduleRepository | 03 | TC06 | PLANNED |
| S08 | [Community Feed](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-514) | `/community/feed` | `FeedScreen` / `FeedViewModel` | PostRepository | 05 | TC07 | PLANNED |
| S09 | [Groups](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-724) | `/community/groups` | `GroupsScreen` / `GroupsViewModel` | GroupRepository + ChatRepository | 05 | TC08 | PLANNED |
| S10 | [Activities](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-815) | `/community/activities` | `ActivitiesScreen` / `ActivitiesViewModel` | EventRepository + ScheduleRepository | 05 | TC09 | PLANNED |
| S11 | [People](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-889) | `/community/people` | `PeopleScreen` / `PeopleViewModel` | ProfileRepository + ChatRepository | 05 | TC10 | PLANNED |
| S12 | [Chats](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-969) | `/community/chats` | `ChatsScreen` / `ChatsViewModel` | ChatRepository | 05 | TC10 | PLANNED |
| S13 | [Conversation](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-1052) | `/community/chat/:id` | `ConversationScreen` / `ConversationViewModel` | ChatRepository | 05 | TC10 | PLANNED |
| S14 | [Settings](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-1114) | `/settings` | `SettingsScreen` / `SettingsViewModel` | ProfileRepository + SettingsRepository + AuthService | 06 | TC11 | PLANNED |
| S15 | [Settings Detail](https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=9-1230) | `/settings/:section` | `SettingsDetailScreen` / `SettingsViewModel` | ProfileRepository + SettingsRepository + NotificationService | 06 | TC12 | PLANNED |

## Settings Detail — ánh xạ đầy đủ các category

| Category | Figma node | Section | Hành vi cần giữ |
|---|---|---|---|
| Profile & Account | `9:1230` | `profile` | Form tên ≥2 ký tự, handle chữ/số/_, bio, màu avatar; Save về Settings; lỗi giữ form. |
| Connected Apps | `9:1306` | `apps` | Chọn Spotify/YouTube và Google/Cốc Cốc; chỉ là shortcut ngoài, không OAuth. |
| Notifications | `9:1367` | `notifications` | Reminder time/lead, messages/groups/weekly summary; phân biệt preference với quyền Android; refusal có hướng dẫn. Demo area/inbox sẽ bổ sung theo Lab3, D09. |
| Hyper Preferences | `9:1450` | `hyper` | autoTimer, pauseOnExit và tùy chọn âm thanh theo thiết kế; giữ draft khi đổi màn. |
| Privacy & Safety | `9:1511` | `privacy` | DM policy/visibility phải được bảo vệ tại Rules và query, không chỉ toggle trên client; ma trận policy cần chốt D10. |
| Appearance | `9:1697` | `appearance` | 7 theme, selected label; persist; thay theme không reset dữ liệu. |

## Ba flow và nhánh phục hồi

| Flow | Màn và thao tác | Recovery/invariant | Test |
|---|---|---|---|
| F01 Minh | S01 → S06 → Create → icon/màu/priority → collection → S07 | Tên thiếu/trùng, priority thiếu giữ form; Active/Interested không giới hạn Schedule/Hyper | TC01, TC03, TC06 |
| F02 Khoa | S04 → Add Schedule → S05 → Start/Pause/Resume/Reset + notes → Finish → Home History | Chưa hobby dẫn Create; pauseOnExit; draft; Finish idempotent; thay priority không mất dữ liệu | TC04, TC05, TC17 |
| F03 Community | S08 → S09/S11 → Join/Message → S12/S13 → Send; S10 → RSVP → optional Add to Home | Membership/privacy deny, lỗi gửi giữ draft; RSVP không auto-schedule; hủy RSVP chỉ xóa schedule liên kết | TC07–TC10, TC18 |

## Dialog và trạng thái không phải màn độc lập

| UI | Figma | Flutter / ViewModel | Nguồn / test |
|---|---|---|---|
| Create/Edit Hobby | 9:356 (Create) | HobbyEditorSheet / HobbyEditorViewModel | HobbyRepository; TC03; edit dùng cùng form và giữ ID |
| Add Schedule | Chưa có component riêng trong inventory | ScheduleSheet / ScheduleEditorViewModel | ScheduleRepository; TC04; tham chiếu modalMarkup trong HTML |
| Choose Hyper hobby | Chưa có component riêng | HobbyPickerSheet / HyperViewModel | HobbyRepository; TC05; HTML choose-hyper |
| Create Post / Comments | 9:609 / HTML comments | PostComposerSheet, CommentsSheet / FeedViewModel | PostRepository; TC07 |
| Create Group | HTML newgroup | GroupEditorSheet / GroupsViewModel | GroupRepository; TC08 |
| Sign Out | 9:1568 | SignOutDialog / AuthViewModel | AuthService; TC11 |
| Reset timer / Remove hobby | HTML focus-reset / delete-hobby | ConfirmationDialog / HyperViewModel hoặc HobbiesViewModel | TC05, TC17; lịch liên quan xóa khi remove hobby, history giữ snapshot |

## Component → widget → state

| ID | Component | Figma | Widget đề xuất | Variants/states | Test |
|---|---|---|---|---|---|
| C01 | Button | 4:5, 4:7, 4:9, 4:11 | `HobbyButton` | default/pressed/disabled/loading; primary/secondary/outline/danger | TC16 |
| C02 | Input | 4:13 | `HobbyTextField` | empty/focused/filled/error/disabled; password visibility | TC16 |
| C03 | Card | screen components | `HobbyCard` | default/pressed/focus; hobby/schedule/post/event | TC16 |
| C04 | Navigation | 4:33, 4:57, 4:81, 4:105 | `AppNavigationBar` | 4 selected states; label + icon | TC16 |
| C05 | App bar | 4:15, 4:23 | `HobbyAppBar` | auth/app/back | TC16 |
| C06 | Dialog/sheet | 9:356, 9:1568 | `HobbyDialog` | confirm/cancel/validation/submitting | TC16 |
| C07 | Loading | chưa có dedicated component xác minh | `LoadingState` | loading → data/empty/error | TC16 |
| C08 | Empty | Home/Hobbies screens | `EmptyState` | reason + CTA | TC16 |
| C09 | Error | chưa có dedicated component xác minh | `ErrorState` | message + retry giữ draft | TC16 |
| C10 | Checkbox | 4:129, 4:132 | `HobbyCheckbox` | checked/unchecked/disabled; tap area ≥48dp | TC16 |

## Khác biệt và đề xuất thích nghi

| ID | Quan sát nguồn | Thích nghi Lab 3 | Quyết định |
|---|---|---|---|
| DX01 | Figma và HTML dùng form auth demo; không có Google CTA trong screenshot 7:8 | Bổ sung Google và email/password thật cho Login/Register/Forgot | D03 APPROVED bởi người dùng 02/11/2026; chưa triển khai |
| DX02 | Figma 6 trang có 0 reaction/0 flow start; HTML có handler tương tác | Cần nối 3 flow và recovery trong Figma hoặc giảng viên chấp nhận HTML | D01 OPEN |
| DX03 | HTML browser storage + data mẫu/chat local | Auth/Firestore thật, tách dữ liệu theo UID và membership | Bắt buộc Lab 3; chưa triển khai |
| DX04 | Figma 410×930; Specification nhắm 360/412; có text phụ nhỏ | Layout thích ứng, hit target ≥48dp, body ≥14sp, test text scale | Bắt buộc Lab 3; chưa đo trên thiết bị |
| DX05 | Chưa thấy bộ loading/error/retry đầy đủ trong inventory | Bổ sung state rõ ở mọi màn tải dữ liệu và form async | Bắt buộc Lab 3; Figma cần cập nhật |
| DX06 | Figma Creator đang minh họa Interested selected; HTML Create khởi tạo priority=null | Giữ yêu cầu chọn priority rõ ràng và validation, không mặc định theo ảnh | Đề xuất theo Specification, nhóm review D07 |
| DX07 | Thiết kế không có demo area 6 Firebase service đầy đủ | Thêm demo area trong Settings/Profile; cùng token; không thêm tab | D09 OPEN trước 07A/07B |
| DX08 | Specification mục 11 ghi Figma chỉ 3 trang (ghi chú cũ) | Kiểm tra trực tiếp nay có 6 trang theo chức năng; không khẳng định đúng nội dung 6 trang rubric | D01 còn OPEN; giữ nguồn gốc nguyên bản |

Nguồn mẫu journal/search/chart trong PDF chỉ là ví dụ. Không thêm chức năng tìm journal/chart vào Hobby Tracker. AI code review là bắt buộc; Gemini trong app, Staff/Admin và web thuộc Final, ngoài phase 00–08.

## Phase 01 source implementation — 03/11/2026

- `lib/app/router/app_router.dart` now declares all **S01–S15** paths and six S15 Settings sections, with 4 StatefulShellRoute branches. Route presence is source-level, **not proof of successful Android runtime**.
- S01–S03 now use real Firebase Auth service via `lib/features/auth/screens/auth_screens.dart` and route guards, but require owner configuration and runtime evidence. S04–S15 features remain transparent placeholders for phases 03–06.
- C01–C10 implementation skeleton lives in `lib/widgets/`; no full Figma pixel parity claim. Tests created under `test/` but cannot be marked PASS without Flutter SDK.
- **DX09 (Phase01 temporary scaffold):** initial route `/home` is visible without signing in, solely for shell testing; not a production auth bypass. Phase02 must implement real auth-state redirects; no demo credentials or dummy logged-in UID.
- **DX10 (Phase01 temporary UI):** route screens intentionally display a feature-unavailable placeholder instead of the final Figma screens. This deviation is temporary and must be removed by the corresponding implementation phase; it does not count as Lab2 screens complete.
- Design approval D01 and HTML source provenance D05 remain **OPEN/BLOCKED**, and UI screenshots/route-back behavior on device are **NOT RUN**. See `docs/phase-01-report.md`.

## Phase 02 traceability note (source authored, no runtime PASS)

S01→AuthScreens.LoginScreen / AuthViewModel / FirebaseAuthService; S02→RegisterScreen; S03→ForgotPasswordScreen. Settings sign-out/explicit linking via AuthSettingsPanel. Profile owner creation is transaction-based and Firestore Rules deny other UIDs. Google cancel, invalid password, account conflict and offline profile errors have explicit handling. The Figma match and Firebase Console evidence are NOT VERIFIED.

## DX11–DX13 — Work Phase02 correctness

- **DX11:** Auth profile-error recovery có “Đổi tài khoản” + confirmation để thoát phiên lỗi mà không mở Settings bị guard chặn. Đây là recovery ngoài shell, không thêm Sign Out vào Home; cần cập nhật/review state này trên Figma.
- **DX12:** S02 bổ sung Tên hiển thị theo Specification và handoff; giữ component/theme, validation 2–80 ký tự. Widget tests 360/412 đạt; Figma/device parity vẫn chưa được xác minh.
- **DX13:** Account actions nằm cuối Settings theo invariant Sign Out. Luồng bootstrap thêm timeout/error/retry; không đổi 4 tab hoặc thêm fake content.


## Full integration update 03/11/2026 — supersedes historical NOT STARTED notes

S04–S15 now route to implemented practice/hobbies/community/settings views. Shared FeaturePage/AsyncPanel provide actual async loading/error/retry and domain empty states. Old placeholder classes/catalog were removed. DX14: hobby deletion uses logical archive/name release and plan filtering to preserve immutable history. DX15: local reminder preferences require native permission/device acceptance; weekly summary schedules the next instance during app sync. DX16: For You ranks topic matches by Active/Interested but never locks scheduling/Hyper. DX17: native package chosen vn.prm393.hobbytracker. DX18: theme morphology foundation differs by radius/elevation/monospace, full Figma visual approval still blocked.

Ten test-harness renders cover main tabs/Hyper at 360/412 using test fixtures and explicit fonts. They demonstrate code rendering, not Android/Figma pixel parity. Figma update/review remains required. No design file was modified.


## Live Figma update — 03/11/2026

DX19: User explicitly requests all Figma screens/colors/UI/UX applied to app. Live source file 5JiJtLyXN6DEpC1LycQPBb accessed; all 30 contexts retrieved with screenshots. Applied Inter, source SVGs, seven exact palette sets, shared brand/navigation, features and settings. See docs/figma-ui-report.md for intentional native/Firebase adaptations and unresolved Groups & follows / Preferred reminder time gaps. Human visual acceptance pending; no 100% or pixel parity claim.

## DX20–DX21 — audit bug fixes, 03/11/2026

- DX20 (Home/Calendar + four-tab shell): >=48dp day widths, horizontal scroll when needed, dynamic calendar height and text-scaled nav height/font 12sp. Reason: reproduced 200% text overflow and small day targets. Widget tests pass; human visual approval pending.
- DX21 (Conversation + Settings): bounded lazy reversed message list and keyboard-visible composer, preference rollback/retry, sender opt-in guidance, and grouped Lab3 diagnostics. Reason: usable long chats and truthful async state. No Firestore permissions were weakened or simulated data introduced. See docs/bugfix-report.md.
- Timer same-hobby/plan selection and bottom-tab pause, notification storage parsing: correctness repairs preserving Flow 2 and owner isolation, not new product flows.

## DX22 — shared feedback and navigation stability, 03/11/2026

Settings and all signed-in routes retain their current page/draft during same-UID Auth metadata refresh. Success feedback is a 3-second dismissible SnackBar instead of a persistent top card; errors stay inline and dismissible, feedback clears on navigation without erasing PDF or drafts. Reason: reproduced user reports of save->Home and stuck success banners. Figma routes/flows unchanged; visual adaptation human approval pending. Evidence: docs/navigation-feedback-report.md, 81 Flutter tests and native Connected Apps smoke. No new cloud deployment.

## DX23 — English/Vietnamese language setting, 03/11/2026

User explicitly requests a Language category and consistent English or Vietnamese copy. Added seventh Settings detail section (not a bottom tab), local language persistence and localization of app-owned UI/errors/pickers/generated reports/reminders. Existing user content, Firebase fields and three flows remain intact. User authorization covers this functional extension; exact visual review remains pending. See docs/localization-report.md and docs/evidence/06/localization/.

## Repository organization — 03/11/2026

User requests separating app code from supplied requirements/documents for GitHub. Materials moved under docs/ according to docs/repository-layout-report.md; original reference inputs and raw evidence hashes unchanged. No screen, flow, theme, authentication, language behavior or Firebase schema change.
