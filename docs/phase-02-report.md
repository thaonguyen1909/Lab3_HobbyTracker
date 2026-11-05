> Historical Phase02 handoff. Superseded by docs/full-implementation-report.md and docs/full-manual-checklist.md for the integrated 00–08 source.

# Hobby Tracker — Phase02 Work Review — 03/11/2026

**Phase02: PARTIAL, chưa PASS. Phase03: NOT STARTED.** Đã sửa source và chạy kiểm tra thực; còn thiếu native Android/Firebase Console/UI acceptance. Không lấy screenshot Phase01 cũ hoặc static audit làm bằng chứng auth hoạt động.

## Kết quả thực tế

| Kiểm tra | Kết quả | Evidence trong project |
|---|---|---|
| Flutter SDK | 3.47.9 stable / Dart 3.13.7 | `docs/evidence/02/work-review-2026-11-03/flutter-version.log` |
| Dependency resolution | PASS, có `pubspec.lock` và npm lock | `pub-get-lock.log`, `npm-lock.log` |
| `flutter analyze --no-pub` | PASS — No issues found | `analyze-final.log` |
| `flutter test --no-pub --reporter expanded` | PASS — 41/41 | `test-final.log` |
| Firestore Rules Emulator | PASS — 9/9, allowed và denied | `firestore-rules-final.log`, `firestore-emulator-local.log` |
| Dart format | PASS — 34 files, 0 changed | `format-check.log` |
| Phase01/02 static audits | PASS, chỉ source contracts | `verify_phase01_static.py.log`, `verify_phase01_design.py.log`, `verify_phase02_static.py.log` |
| Phase00 provenance | FAIL ở đối chiếu hash lịch sử: 3 HTML lệch; phase00 vẫn PARTIAL | `verify_phase00.py.log`, `docs/source-provenance.md` |
| `flutter build apk --debug --no-pub` | BLOCKED — thiếu native Android/Android SDK | `android-build.log`, `flutter-doctor.log` |
| Google picker / auth thật / reset email / cloud profile / 2 account thật | NOT RUN — thiếu config, account và thiết bị của chủ dự án | `docs/phase-02-manual-acceptance.md` |
| Figma trực tiếp / visual Android parity | BLOCKED — kết nối trả không có Editor access | `figma-access.json` |

Các file log ngắn trong bảng nằm dưới `docs/evidence/02/work-review-2026-11-03/`. Android command được thử, exit 1 trong bước chuẩn bị artifacts Android, không tạo APK; doctor xác nhận không có Android SDK và project chưa có native folder. không gọi đó là lỗi biên dịch Dart. Flutter tests đã biên dịch code được dùng trong test harness, không chứng minh Gradle/native SDK integration.

## Đã hoàn thành trong đợt này

1. Đọc `docs/history/00_START_HERE.md`, AGENTS, source Dart/tests/Firebase/scripts và các tài liệu kiến trúc/roadmap/traceability. Đã trích xuất/đối chiếu 3 PDF yêu cầu; xem `docs/requirements-work-review.md` về scope và xung đột Storage giữa Lab3/Final.
2. Thay `asyncMap` tuần tự bằng identity stream độc lập và profile `FutureProvider`. Profile timeout sau 20 giây; auth guard tiếp tục đóng khi loading/error. Logout/đổi UID không bị xếp sau profile I/O, kết quả/error muộn bị loại bỏ. Tests kiểm tra những race này và retry.
3. Chặn ghi state sau khi AuthViewModel bị dispose; giữ chống submit đôi, cancel không coi là crash, lỗi có thể thử lại. Kiểm tra mounted sau dialog/linking.
4. Dùng Firebase `userChanges()` để cập nhật provider/profile sau linking. Chặn link nếu UID thay đổi trong lúc chọn Google; chỉ link cùng email và sau xác nhận. Không tự gộp tài khoản.
5. Bổ sung Tên hiển thị ở Register theo handoff; validation 2–80 ký tự; trim, cập nhật Firebase Auth và profile transaction. Nếu initial auth event đã tạo fallback profile, registration chỉ update displayName và giữ nguyên role. Bootstrap thông thường không sửa hồ sơ đã có. Dùng Unicode runes khi giới hạn tên, không cắt giữa surrogate pair.
6. Giữ role `user` khi tạo hồ sơ, không lưu password. Rules deny-by-default không mở rộng sang hobby/chat. Thêm tests schema, timestamps, đổi tên hợp lệ, nâng quyền, list/delete/cross-user và nested paths bị chặn.
7. Sửa đường dẫn file rules theo `import.meta.url`, tách dữ liệu từng rules test bằng `beforeEach`; pin npm dependencies và thêm lock. Không cần đăng nhập Firebase để chạy test local.
8. Sửa test navigation bấm ngoài viewport: scroll tới nút, hit-test warning thành lỗi; thêm Register validation/success ở 360dp và 412dp. 13 adapter tests (Google token/cancel/conflict, email trim, network, logout cleanup, linking, register/profile), 6 ViewModel/session tests, 9 router/widget auth tests và 13 theme/component tests — tổng 41.
9. Sửa 15 analyzer notices, format source/tests, nâng minimum Flutter/Dart cho API theme hiện dùng, thêm mocktail 1.0.4 dev-only và `pubspec.lock`. Theme tokens/4 tabs/MVVM/Riverpod giữ nguyên. Account actions ở cuối Settings; auth recovery có Đổi tài khoản + confirm và nội dung scroll được.
10. Static audit bỏ qua generated dependency folders, nhận diện brand widget bất kể Dart formatter xuống dòng, và không còn tự khẳng định môi trường thiếu SDK. Những script này không thay semantic/runtime tests.

## Những lỗi/lượt chạy đã được xử lý

- Flutter bootstrap ban đầu dò Azure metadata, bị automatic review chặn. Đã đọc `bot_detector.dart` và chạy chế độ CI có sẵn, bỏ qua metadata probe; không đọc credentials.
- SDK tar ban đầu không đổi được uid/gid trong container: dùng `TAR_OPTIONS=--no-same-owner`, pub get sau đó đạt.
- Lượt Flutter test đầu: 33 đạt, 2 lỗi do bấm links ngoài viewport. Đã sửa test và chạy lại.
- Các test bổ sung profile từng lỗi generic callback của test double; đã chỉ rõ `runTransaction<void>` và chạy lại. Kết quả cuối cùng mới là 41/41.
- Phase00 hash mismatch là tồn đọng nguồn, không sửa manifest để che lỗi. Các input reference gốc không thay đổi byte.

## Chưa hoàn thành / việc chủ dự án cần làm

1. Chốt Android application ID; tạo native Android folder; cấu hình project Firebase, Google/Email providers, support email, SHA-1/SHA-256 và native config bằng FlutterFire. Review đúng project trước khi deploy rules. Không có backend nào được thay đổi trong đợt này.
2. Build/chạy Android, Google sign-in/cancel, email register/login/reset mail thật, cold start, logout, offline/retry, linking/conflict và hai UID thật. Chụp Console Users, `users/{uid}` và màn trước/sau theo checklist `docs/phase-02-manual-acceptance.md`.
3. Cấp quyền Figma cho tài khoản đang kết nối hoặc cung cấp export được duyệt; review Android ở 360/412dp. Token/source tests không chứng nhận pixel parity hoặc WCAG toàn bộ app.
4. Đóng D01/D05 về formal Lab2/Figma và provenance khi có dữ liệu chủ nguồn. Chủ Firebase/giảng viên còn cần chốt Storage D02 ở phase07A; chưa bật billing.

Phase03 chưa có model/repository/viewmodel, CRUD, rules hoặc dữ liệu hobbies. Quyền tiếp tục đã có trong yêu cầu hiện tại, nhưng điều kiện Phase02 hoàn thành chưa đạt; không triển khai Phase03 để bù cho thiếu bằng chứng Phase02.

## Báo cáo theo AGENTS

PHASE: 02 | Firebase Authentication
STATUS: PARTIAL
SCOPE: Auth correctness, register/profile, adapter/session/widget/rules tests; không cloud deploy, không Phase03.
CHANGED FILES: Xem `docs/work-changed-files.json`; những Dart khác chủ yếu format/lint. Thay đổi chính: AuthService/FirebaseAuthService/AuthViewModel/AuthScreens/AuthSettingsPanel/AuthGates, Settings placement, pubspec+locks, tests, verification scripts và docs.
DESIGN TRACEABILITY: S01–S03, Settings và recovery; `docs/design-traceability.md`. Live Figma review BLOCKED.
ACCEPTANCE GATES: PASS analyzer + 41 Flutter tests + 9 rules tests; BLOCKED Android/Firebase/Figma; Phase00 provenance FAIL còn tồn đọng.
COMMANDS ACTUALLY RUN: version/doctor/pub get/analyze/test/format/build/static scripts/npm/Java emulator; raw logs ở evidence folder nêu trên.
SECURITY & DATA CHECK: Local rules tests allowed/denied 9/9; không nâng role, không password, không production data; account isolation thật NOT RUN.
OPEN DECISIONS / RISKS: Chủ dự án thực hiện checklist Android/Firebase/Figma; D01/D02/D05 còn mở. SDK dependencies pin cũ để giữ tương thích, chưa nâng major.
COMMIT/PR/DEPLOY: NOT CREATED — ZIP bàn giao không có lịch sử .git.
READY FOR HUMAN REVIEW: YES — review source/tests và các blockers; chưa nghiệm thu phase.
NEXT PHASE: NOT STARTED
