# HOBBY TRACKER — KẾ HOẠCH TRIỂN KHAI THEO ĐỢT CHO CODEX

> Bản lập kế hoạch dựa trên bộ tài liệu người học cung cấp ngày 01/11/2026. Đây là kế hoạch **đề xuất** để hiện thực Lab 2 thành ứng dụng Android Lab 3; không phải các bước đã được triển khai hoặc được giảng viên phê duyệt.

## 1. Nguồn tham chiếu và nguyên tắc ưu tiên

**Lab 2 (thiết kế và hành vi):** `Specification.html` là nguồn truy vết màn hình, flow, invariant và token; `Prototype.html` là tham chiếu thao tác có dữ liệu trình diễn trong trình duyệt (không phải backend); `DesignArchive.html` là hình ảnh/thị giác; `HobbyTracker_Design_Journey_12_Slides.pptx` và `HobbyTracker_Design_Journey_Rebuilt_V3.pptx` giải thích quyết định thiết kế, persona và lý do sửa UX.

**Lab 3 (bắt buộc):** `PRM393 - Lab 3 Cloud-Enabled Mobile App (Firebase, Patrol, AI Code Review).pdf` là rubric/nguồn tiêu chí chính; `PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf` là checklist thực hành.

**Final (giai đoạn sau):** `PRM393 - Final Assignment One Complete System on Firebase.pdf` định nghĩa mobile + web admin + shared Firebase + một AI feature. Không áp dụng yêu cầu Final thay thế cho Lab 3 trước khi Lab 3 được nghiệm thu.

Khi nguồn xung đột, **ghi vào `docs/open-decisions.md`, không để Codex tự suy đoán hoặc âm thầm lược bỏ yêu cầu**.

## 2. Phạm vi chức năng phải giữ từ Lab 2

**Người dùng:** sinh viên 18–24 tuổi; persona Minh (khám phá hobby) và Khoa (duy trì hobby). Chín nhân vật phỏng vấn trong slide là mô phỏng bằng AI, không phải dữ liệu khảo sát thật.

**15 màn hình độc lập** (dialog không tính thành màn hình):

| Nhóm | Màn hình | Giai đoạn hiện thực đầy đủ |
|---|---|---|
| Auth | Login; Register; Forgot Password | Đợt 02 |
| Home | Home; Hyper Mode | Đợt 04 |
| My Hobbies | My Hobbies; Hobby Detail | Đợt 03 |
| Community | Feed; Groups; Activities; People; Chats; Conversation | Đợt 05 |
| Settings | Settings; Settings Detail | Đợt 06 |

4 tab chính và thứ tự: **Home / Community / My Hobbies / Settings**. Sign Out chỉ ở cuối Settings, có bước xác nhận.

**Flow 1 — Discover & Create (Minh):** Login → My Hobbies → Create Hobby → icon/màu/Active hoặc Interested → collection; lỗi thiếu tên, thiếu priority, trùng tên phải được xử lý mà không mất thông tin nhập. Hobby là do người dùng tạo, KHÔNG có catalog ép chọn. Active và Interested đều được phép lập lịch và dùng Hyper Mode. Đổi priority không xóa lịch hoặc lịch sử.

**Flow 2 — Plan & Practice (Khoa):** Home → Add Schedule → Hyper Mode (start/pause/resume/reset, tool shortcuts và notes) → Finish → History. Không có hobby thì dẫn đến tạo hobby. Timer cần theo dõi thời gian thực chạy, không tích lũy thời gian khi pause; một lần Finish tạo một record; lịch cùng ngày sắp xếp theo giờ; các lịch cũ phải còn nguyên. Các liên kết Spotify/YouTube là shortcut tới web, KHÔNG tuyên bố là tích hợp OAuth/phát nhạc.

**Flow 3 — Connect & Participate:** Community → Groups/People → Join/Message → Chat → Send; nhánh khác: Activities → RSVP → **Add to Home chỉ khi người dùng chủ động bấm**, không tự lên lịch. Dữ liệu chat phải thay từ local echo sang Firestore có quyền truy cập theo thành viên.

**Design system:** Light mặc định, 7 theme (`Light`, `Dark`, `Energetic`, `Cyber`, `Art`, `Sad`, `Rainy Day`). Base token: `#087F72` primary, `#213D36` text, `#4F6F63` muted, `#F7FAF7` background, `#E7F5ED` soft, `#D8E9DF` border. Spacing: 4/8/12/16/20/24/32. Touch target ít nhất 48dp, nội dung văn bản mục tiêu ít nhất 14sp, test ở 360dp và 412dp. 7 theme cần khác biệt hợp lý về cách thể hiện, không chỉ thay HEX.

**Các giới hạn prototype phải được chuyển thành việc thật:** login mô phỏng; localStorage/sessionStorage; chat local; notification không có; loading/retry mạng chưa đủ; không có backend/rules. Tuyệt đối không copy dữ liệu demo hard-code vào bản nộp làm dữ liệu thật.

## 3. Những điểm cần xử lý trước khi Codex bắt đầu

1. **Đầu vào Lab 2 cần review:** đã gom 7 nguồn vào reference/, đọc 6 trang Figma trực tiếp và soạn draft design/DESIGN.md cùng handoff/flutter-handoff.md. Figma hiện có 0 reaction/flow start; baseline, formal prerequisite và handoff còn chờ nhóm/giảng viên xác nhận. Xem docs/figma-html-comparison.md, docs/gap-review.md và docs/phase-00-review.md; không dùng ghi chú cũ “Figma 3 trang” trong Specification để mô tả hiện trạng mới.
2. **Cloud Storage bắt buộc trong Lab 3:** tạo file và upload theo UID, hiển thị progress/URL, có Rules và bằng chứng thực. Xác minh điều kiện dịch vụ/chi phí hiện hành trước cấu hình, không tự nâng billing. Chưa đủ điều kiện thì ghi BLOCKED; local PDF chưa đủ nghiệm thu. Tách ReportExportService và ReportUploadService để dễ kiểm thử.
3. **Lab 2 có form email/password, Lab 3 bắt buộc Google Sign-In:** đề xuất hỗ trợ Google Sign-In và bảo tồn các route Login/Register/Forgot Password với xử lý auth thật khi khả thi; mọi khác biệt phải ghi traceability.

## 4. Quy chuẩn vận hành Codex ở mọi đợt

- Đưa **7 nguồn gốc Lab 2/Lab 3** vào thư mục `reference/` trong workspace của Codex trước đợt 00. Các prompt trong tài liệu này chỉ có tác dụng khi Codex thật sự nhìn thấy file.
- Mỗi đợt = 1 phạm vi nhỏ/1 PR hoặc nhánh riêng, có mục tiêu, file đầu ra, test và tiêu chí hoàn tất (DoD). Không chạy đồng loạt 3–5 đợt trong một prompt.
- Trước khi sửa: Codex phải đọc README, `docs/open-decisions.md`, `docs/design-traceability.md`, `docs/architecture.md`, trạng thái Git và các file nguồn liên quan; thông báo phần nào bị BLOCKED.
- Không tự deploy lên production, không tăng billing, không xóa dữ liệu thật, không thay đổi quyền IAM hoặc commit secret/keystore/API key. Thao tác có tác động hạ tầng phải được người phụ trách xác nhận.
- UI chỉ gọi ViewModel; ViewModel gọi injected Service/Repository; SDK chỉ ở service layer. Ưu tiên Riverpod (đề xuất) hoặc Provider, không pha trộn hai hệ tùy ý.
- Mọi screen có tải dữ liệu phải xử lý `loading / data / empty / error + retry`; lỗi và đường đi thay thế của 3 flows phải có test.
- Cuối mỗi đợt, chạy các phép kiểm tra khả dụng: `flutter analyze`, `flutter test` (hoặc `dart test`), rules emulator tests khi có rules, ARTEMIS khi được giao. Nếu không chạy được, ghi rõ lý do và **KHÔNG ghi PASS**.
- Báo cáo sau mỗi đợt gồm: file thay đổi; quyết định kỹ thuật; màn hình/flow hoàn tất; cách chạy/test; kết quả thực tế; ảnh/evidence thật nếu có; cảnh báo và bước kế tiếp. Commit được tách nhỏ, tên phản ánh đợt.
- Mọi thay đổi ngoài Lab 2 cần ghi `docs/design-traceability.md`, mọi gap/ngoại lệ ở `docs/open-decisions.md`.

## 5. Kế hoạch phân đợt và điều kiện nghiệm thu

### ĐỢT 00 — Chốt đầu vào và truy vết yêu cầu (CHỈ TÀI LIỆU)

**Mục tiêu:** tránh viết code sai vì thiếu spec. **Công việc:** đọc 7 nguồn Lab 2/Lab 3, xác lập danh sách 15 màn hình/3 flow/7 theme/4 tab; lập ma trận `Lab2 -> Flutter route -> widget -> viewmodel -> data source -> test case`; lập checklist rubric Lab 3; liệt kê gaps Figma/Handoff, Cloud Storage/billing, auth. **Deliverables:** `docs/gap-review.md`, `docs/design-traceability.md`, `docs/open-decisions.md`, `docs/rubric-checklist.md`, draft `design/DESIGN.md`, draft `handoff/flutter-handoff.md`. **DoD:** không có màn hình hoặc recovery path bị bỏ sót; mỗi yêu cầu có nguồn; các quyết định chưa được phê duyệt có `OPEN/BLOCKED`, không coi là đã hoàn thành.

**Prompt Codex:** `prompts/00-audit.md`.

### ĐỢT 01 — Flutter shell, navigation và design system

**Mục tiêu:** app Android khởi chạy, đủ route để tiếp tục implement mà không tạo kiến trúc rối. **Công việc:** Flutter stable, go_router, Riverpod, MVVM, 4 tabs, 15 route có placeholder minh bạch, design tokens/ThemeData, components chung Button/Input/Card/AppBar/Nav/Dialog/Loading/Empty/Error, responsive 360/412. Tạo `docs/architecture.md` có diagram, sequence, services-ViewModels table. **DoD:** app launch, navigate/back, 4 tab đúng, component demo state có test; không có Firebase SDK trong widget, không fake thành màn hình đã hoàn thành. Chủ yếu hoàn thiện Light; giữ khung 7 theme.

### ĐỢT 02 — Firebase foundation, Auth và route guards

**Mục tiêu:** người dùng thực đăng nhập và dữ liệu tách theo UID. **Công việc:** Firebase project/FlutterFire CLI setup dưới hướng dẫn người phụ trách; Google Sign-In (required), auth-state routing, sign-out, cancel/no-network/retry; xử lý Login/Register/Forgot từ Lab2 và ghi sai khác nếu có; `users/{uid}` profile và Firestore Rules tối thiểu, DI auth service, separate demo account. **DoD:** signed-out không truy cập app; login thành công tới Home; signout xác nhận ở Settings; cancel không crash; không lưu password trong Firestore. **Lưu ý:** giảng viên có thể yêu cầu demo profile, nhưng profile nằm trong Settings theo Lab2.

### ĐỢT 03 — Flow 1: My Hobbies + Firestore CRUD

**Mục tiêu:** hoàn thiện Minh journey end-to-end. **Công việc:** models/repos/services/ViewModels cho Hobby, My Hobbies, Create/Edit dialog, Hobby Detail; icon grid/color swatch/priority, validation required/duplicate, empty/retry, owner-scoped reads/writes; indexes/rules và tests. **DoD:** tạo hobby tự đặt tên và thấy ở collection sau tải lại/re-login; cả Interested/Active có đầy đủ quyền lịch/timer; edit không làm mất plan/history; trùng tên hiện lỗi không ghi đè bản cũ. **Không** dựng catalog.

### ĐỢT 04 — Flow 2: Home Calendar → Hyper Mode → History

**Mục tiêu:** hoàn thiện Khoa journey end-to-end. **Công việc:** Schedule + ActivityRecord Firestore; week/day list sort theo giờ; Add Schedule, CTA Hyper; accurate timer (Stopwatch/lifecycle), pause/resume/reset/finish, note snapshot; one record per finish (chống double-submit); mark linked schedule complete; History; preference pauseOnExit; links ngoài chỉ là shortcut. **DoD:** lưu và tải lại lịch, session duration/notes; pause không tăng elapsed; complete không tạo bản ghi đôi; không hobby có đường dẫn Create; RSVP không auto-add lịch (invariant chung).

### ĐỢT 05 — Flow 3: Community dùng dữ liệu thật

**Mục tiêu:** hoàn thiện Connect & Participate theo thiết kế Lab 2. **Công việc:** Feed/Post/Like/Comments; Groups + Join/Create + Chat; Activities/Events + RSVP + optional Add to Home; People + DM; Chats + Conversation; Firestore snapshots + participant rules; validation/empty/error. **DoD:** 2 tài khoản thực có thể nhìn nội dung chia sẻ phù hợp, trao đổi tin nhắn được phân quyền, data persist; người không thuộc chat không đọc messages; RSVP một mình không thêm schedule. Ghi nhận rõ nếu dùng dữ liệu seed **chỉ trong emulator**, không hard-code data vào production.

### ĐỢT 06 — Settings, 7 themes và UI/A11y parity

**Mục tiêu:** đóng toàn bộ màn hình và chất lượng giao diện Lab 2. **Công việc:** Settings/Settings Detail: profile, external-tool shortcuts, notifications, Hyper prefs, appearance, privacy, signout confirmation; 7 theme với riêng style hợp lý, persistence; screen/device states; Semantics labels; screenshot comparison với DesignArchive; audit 15 màn tại 360/412. **DoD:** mọi route 15/15 có chức năng chủ yếu và trạng thái rõ; không overflow, 48dp targets, text >=14sp ở nội dung chính; theme switch không làm mất data; external links không giả là Spotify/YouTube integration.

### ĐỢT 07A — File report và chiến lược Cloud Storage (BLOCKER PHẢI CHỐT)

**Mục tiêu:** PDF export thực và đường upload theo yêu cầu Lab 3 nếu hạ tầng được duyệt. **Công việc:** `ReportExportService` dựng PDF summary từ các dữ liệu hiện tại; `ReportUploadService` abstract; sau khi xác minh điều kiện dịch vụ và được duyệt phương án hạ tầng cần thiết thì Firebase Storage upload `reports/{uid}/...` + progress + URL + storage.rules + denied tests + offline error. Nếu chưa có quyết định billing, chỉ implement local export và đánh dấu Cloud Storage requirement còn thiếu, không giả evidence. **DoD:** file tương ứng số liệu màn hình; local export/share hoạt động; upload chỉ tính DONE nếu cloud upload thật + console evidence + rules tests; Local export không thay thế upload Lab 3.

### ĐỢT 07B — FCM, Analytics, Crashlytics, Remote Config

**Mục tiêu:** hoàn tất các dịch vụ Lab 3 còn lại, có bằng chứng. **Công việc:** FCM permission Android 13+, foreground/background/terminated, local inbox & deep link; ≥7 analytics events map Flow1-3 và export (không PII), DebugView; Crashlytics nonfatal error + gated test crash (ID/key); Remote Config 2 giá trị thay đổi hành vi thực có defaults, offline fallback; Firebase demo area trong Settings/Profile; `docs/analytics-plan.md`. **DoD:** mỗi dịch vụ có thành công + failure path và screenshots/console proof; events seen in DebugView; configs thay đổi không rebuild; crash test không bao giờ vô tình chạy trên màn thường.

### ĐỢT 08 — ARTEMIS E2E, AI Code Review, khóa mốc Lab 3

**Mục tiêu:** nghiệm thu Lab 3 có evidence, không chỉ ảnh giao diện. **Công việc:** `docs/test-plan.md` ≥10 case; pytest/Google ARTEMIS (mỗi case ≥3 runs, assert kết quả nhìn thấy, test native Google picker/notification, 1 Pro exploratory 15–30 phút), traces/pass-rate/flaky report; AI code review PR ≥5 findings thuộc ≥2 loại, quyết định và ≥3 fixes ở commits riêng; report Lab 3 8–12 trang, slide 12–15, video 5–10 phút. **DoD:** test records là kết quả thực, code review có file:line/commit, README có versions, AI disclosure, links mở được; đánh tag mốc `lab3-submission` (chỉ sau kiểm tra). Không bịa kết quả/chạy test giả.

## 6. Phụ thuộc và thứ tự bắt buộc

```
00 (gap/handoff) -> 01 (shell) -> 02 (auth/firebase)
                                      -> 03 (hobbies) -> 04 (schedule/hyper)
                                      -> 05 (community) -> 06 (settings/UI)
                                      -> 07A (export/storage*) + 07B (Firebase services)
                                      -> 08 (Lab 3 QA + submission tag)
```

`*` 07A chỉ hoàn tất Cloud Storage khi có phương án billing/ngoại lệ chính thức, không được đánh dấu đạt bằng local PDF.

**Gate trước khi chuyển đợt:** branch sạch hoặc có commit giải thích; yêu cầu của đợt đạt; test đã chạy (hoặc có blocker thật); docs/traceability cập nhật; người phụ trách xem UI/UX và chấp nhận. Khi FAIL phải sửa trong **cùng đợt** trước, không đẩy lỗi sang đợt tiếp theo.

## 7. Ma trận kiểm tra thiết yếu

| Kiểm tra | Tiêu chí | Mốc |
|---|---|---|
| UI/UX | 15 màn, 4 tabs, 3 flows, recovery paths, 7 themes; 360/412dp, 48dp, 14sp | 06 |
| Architecture | MVVM, injected services, no SDK in widgets, ThemeData components | 01–06 |
| Identity/Data | Google Sign-In, guard, Firestore real data, permissions, no mock in prod | 02–05 |
| Lab 3 Firebase | Auth, Storage*, FCM, Analytics, Crashlytics, Remote Config; failure paths & evidence | 07A–07B |
| Lab 3 ARTEMIS | ≥10 cases, ≥3 runs each, native+error, 1 Pro exploratory | 08 |
| Lab 3 review | ≥5 findings, ≥2 categories, ≥3 fix commits | 08 |

## 8. Những việc con người phải làm (Codex không thể giả thay)

- Xác nhận Figma chính thức, `DESIGN.md`/handoff và sự chấp nhận HTML Lab 2 với giảng viên.
- Tạo/quản lý Firebase/Google project, Google Sign-In SHA, test accounts, cấu hình dịch vụ và billing và secret một cách an toàn.
- Chốt điều kiện Cloud Storage/ngân sách hoặc ngoại lệ chính thức với giảng viên; không tự kích hoạt chi phí.
- Cấp quyền và thiết bị Android thật/emulator, Google account picker, test notification foreground/background/terminated, ARTEMIS model API key.
- Chụp evidence thực trong Firebase Console/DebugView/Crashlytics, ghi nhận test runs, làm review và quyết định từng AI finding.
- Review UI và các khác biệt với Lab2, duyệt branch/PR từng đợt, nộp report/slides/demo đúng hạn.

## 9. Mẫu lệnh giao việc cho Codex (áp dụng cùng file prompt của từng đợt)

```
Bạn đang làm ở repository Hobby Tracker. Hãy đọc AGENTS.md, 7 nguồn Lab 2/Lab 3
trong reference/, docs/open-decisions.md và docs/design-traceability.md.
Chỉ thực hiện ĐỢT <SỐ> trong prompts/<FILE>.md; không làm đợt sau.

Trước khi sửa code:
1. Kiểm tra hiện trạng repo, branch, test commands và blockers.
2. Liệt kê các file dự kiến sửa và acceptance criteria.
3. Nếu gặp yêu cầu xung đột/billing/quyền ngoài phạm vi, ghi BLOCKED và
   chỉ triển khai phần không phụ thuộc; không tự đoán và không deploy.

Sau khi sửa:
1. Chạy flutter analyze, flutter test, và test chuyên biệt khi khả dụng.
2. Cập nhật traceability, architecture và docs/evidence đúng thực tế.
3. Báo cáo file changed, checks PASS/FAIL/NOT RUN, hạn chế còn lại.
4. KHÔNG đánh dấu hoàn thành nếu test/bằng chứng còn thiếu.
```

---

**Tên repository khi nộp theo Lab 3:** `PRM393_Lab03_<StudentID>`. Tên hiện tại `Lab3_HobbyTracker` cần chốt trước nộp; chưa tự đổi tên.

**Phạm vi hiện tại:** chỉ phase 00–08. Kế hoạch Final ở `planning/final/roadmap.md` là tham khảo, không thuộc tiêu chí nghiệm thu Lab 3 và không được tự khởi chạy.
