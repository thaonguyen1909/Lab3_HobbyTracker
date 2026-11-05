# Checklist rubric Lab 3

Nguồn chính: PDF Lab 3 mục 3–11, đặc biệt bảng điểm tr.12–15 (bản 18 trang trong docs/requirements/reference/). Preparation Guide bổ sung checklist vận hành. Điểm là trọng số đề bài, không phải điểm tự chấm. Tất cả tính năng/evidence dưới đây PLANNED, chưa đạt; phase00 chỉ lập coverage.

| ID | Tiêu chí | Điểm | Nguồn PDF | Điều kiện đạt | Phase | Bằng chứng cần có | Hiện trạng |
|---|---|---|---|---|---|---|---|
| R01 | Flows/navigation | 1.0 | Mục 3,10; tr.2–3,12 | 15 màn/3 flow + recovery, Back, sign-in/profile | 02–06 | TC01–TC12, TC22; video từng flow | PLANNED / NOT RUN |
| R02 | Data/content | 0.75 | Mục 3,10; tr.3,12 | Firestore thật, không sample; file khớp dữ liệu hiển thị | 03–07A | TC03–TC10, TC14; Console/data screenshots | PLANNED / NOT RUN |
| R03 | States/error | 0.75 | Mục 3,10; tr.3,13 | Mọi data screen loading/empty/error/retry; service failures không crash | 02–07B | TC01–TC22; evidence offline/deny/empty | PLANNED / NOT RUN |
| R04 | Authentication | 0.25 | Mục 6; tr.6 | Google, auth routing, signout clears private data, cancel message | 02 | TC01,TC02,TC11; Authentication Users | SOURCE IMPLEMENTED / FIREBASE RUNTIME NOT RUN |
| R05 | Cloud Storage | 0.25 | Mục 6; tr.6 | Generate/upload theo UID, progress, URL, private Rules | 07A | TC14; storage.rules, file list, denied tests | PLANNED / NOT RUN |
| R06 | Cloud Messaging | 0.5 | Mục 6; tr.7 | 3 app states, permission Android13+, inbox, deep link | 07B | TC15; Console message + ảnh 3 states | PLANNED / NOT RUN |
| R07 | Analytics | 0.5 | Mục 6; tr.7,16–17 | ≥7 events, trigger/params/types/question/flow, UID, no PII | 07B | analytics-plan.md + TC21 DebugView từng event | PLANNED / NOT RUN |
| R08 | Crashlytics | 0.25 | Mục 6; tr.7 | nonfatal real path + test crash, UID/custom key | 07B | TC20; dashboard cả 2 loại | PLANNED / NOT RUN |
| R09 | Remote Config | 0.25 | Mục 6; tr.7 | ≥2 parameters thay hành vi, defaults, không rebuild | 07B | TC19; before/after + console values | PLANNED / NOT RUN |
| R10 | MVVM separation | 0.5 | Mục 5; tr.4–6 | SDK qua service, business logic ngoài widget, architecture khớp code | 01–07B | architecture.md, diagram/sequence/VM-service table, static review | PLANNED / NOT RUN |
| R11 | State management | 0.25 | Mục 5; tr.5,14 | Provider hoặc Riverpod, DI, typed async state, no global mutable shared state | 01–07B | unit/widget tests ViewModel với fake service | PLANNED / NOT RUN |
| R12 | Design fidelity | 0.5 | Mục 5; tr.6,14 | ThemeData token + reusable widgets, deviations ghi và sync Figma | 01–06 | traceability, component tests, Figma/app comparison | PLANNED / NOT RUN |
| R13 | Usability/a11y | 0.25 | Mục 5,10; tr.6,14 | 48dp,14sp,contrast,360/412,feedback,no overflow | 06 | TC13,TC16,TC22; thiết bị/screenshot/semantics | PLANNED / NOT RUN |
| R14 | E2E plan/coverage | 0.5 | Mục 7; tr.8–9,14 | ≥10 cases,3 flows,error/native,Pro exploratory | 08 | test-plan.md, e2e_test/, TC23 report | PLANNED / NOT RUN |
| R15 | E2E quality | 0.5 | Mục 7; tr.8–9,14 | Observable assertions,≥3 runs/case,Semantics,independent preconditions | 08 | ARTEMIS source + traces + ít nhất 1 analytics assertion | PLANNED / NOT RUN |
| R16 | E2E evidence | 0.5 | Mục 7; tr.9,14 | Trace/screenshot mọi run,pass rate/time,flaky explanations | 08 | Raw logs/results table; không claim chưa chạy | PLANNED / NOT RUN |
| R17 | AI review decisions | 0.25 | Mục 8; tr.10,15 | ≥5 findings file:line,≥2 kinds,accept/modify/reject lý do,AI disclosure | 08 | docs/code-review.md, saved tool output | PLANNED / NOT RUN |
| R18 | Review fixes | 0.25 | Mục 8; tr.10,15 | ≥3 accepted fixes,commit riêng linked finding | 08 | 3 commit IDs thật; chưa tạo trong phase00 | PLANNED / NOT RUN |
| R19 | Slides | 1.0 | Mục 9; tr.11–12,15 | 12–15 slides PDF, các chủ đề bắt buộc, evidence từng claim | 08 | docs/submission/slides/Lab03_<StudentID>_slides.pdf | PLANNED / NOT RUN |
| R20 | Video | 1.0 | Mục 9; tr.12,15 | 5–10 phút live,flows/errors/export-upload/FCM/RC/crash/test/review fix | 08 | README video link hoạt động | PLANNED / NOT RUN |

Tổng: functional 2.5 + Firebase 2.0 + architecture 0.75 + UI/UX 0.75 + tests 1.5 + review 0.5 + docs/submission/slides/video 2.0 = 10.

## Điều kiện nộp bắt buộc không có điểm riêng

- Report PDF 8–12 trang theo mục 9, có evidence cho từng claim; README map deliverables, versions, cách chạy và AI disclosure.
- Tiếp tục Git history theo giai đoạn; không bịa số commits/ngày [N] trong đề, hỏi giảng viên nếu cần ngưỡng cụ thể.
- Repository/report/slides/video phải mở được tại hạn nộp; repo hiện private nên cần chốt quyền truy cập/nộp với giảng viên, không tự đổi public.
- Không commit service-account keys, API secrets, keystore; project ID trong evidence khớp app config.
- Có khả năng trình diễn trực tiếp và giải thích ViewModel, rule/code-review decision; tool AI không thay trách nhiệm của nhóm.
- Figma/handoff được đối chiếu và deviations cập nhật. Hiện Figma không có reactions, xem gap-review và D01.
- Cloud Storage vẫn bắt buộc; local PDF hoặc blocker billing không tự miễn yêu cầu. Quyết định ngoại lệ phải được giảng viên ghi nhận.
- Không yêu cầu web admin, multi-role approval, Gemini trong app, announcements cross-role hay shared mobile/web package trong Lab3.
