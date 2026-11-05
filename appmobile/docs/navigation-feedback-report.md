# Sửa điều hướng và thông báo dùng chung — 03/11/2026

PHASE: 02/06/08 | Session, navigation and feedback regression fix
STATUS: PARTIAL — mục tiêu sửa đã qua kiểm thử local/native smoke; các gate toàn Lab3 chưa đóng.

## Nguyên nhân

- FirestoreHobbyRepository.savePreferences cập nhật Firebase Auth displayName sau mọi lần lưu, kể cả tên không đổi. FirebaseAuthService phát userChanges; authSessionProvider trước đây watch mọi userChanges.future và chạy lại profile gate. Router thấy loading -> /auth/loading -> /home, làm mất trang/biểu mẫu đang mở. Token refresh/provider linking cũng có thể kích hoạt cùng lỗi.
- FeaturePage render state.message/error từ state action dùng chung. Thành công không có thời hạn và không được clear khi đổi route, nên hiện trên cả Home và các trang khác.

## Sửa

- Auth profile gate dùng UID qua selectAsync; thay UID/logout vẫn vô hiệu phiên cũ và kiểm tra profile mới. Cập nhật tên/token/provider của cùng UID không bootstrap lại, không redirect hoặc phá bản nháp.
- currentUserProvider cung cấp metadata mới cho header, Settings và account panel; không dùng session bootstrap snapshot làm nguồn tên/provider hiện tại.
- Không gọi updateDisplayName nếu tên không đổi. Link Google không ép invalidate toàn bộ authSession nữa.
- Success dùng ScaffoldMessenger SnackBar một lần, tự đóng sau 3 giây, có nút Close. Thao tác mới thay thông báo cũ; đổi route dọn feedback, không phát lại khi rebuild/theme đổi. Không thay đổi routes/4 tab.
- Lỗi vẫn inline, đọc được và có nút dismiss; không dùng snackbar che Retry hoặc composer. Clear feedback giữ nguyên PDF bytes, upload receipt/progress và không xóa bản nháp.

## Kiểm chứng thực

| Check | Result | Evidence |
|---|---|---|
| 6 Settings sections lưu preferences và phát same-UID auth metadata | PASS: giữ /settings/<section>, profile gate chỉ chạy một lần | test/navigation_feedback_test.dart, regression.log |
| Home/Hyper/Hobbies/detail/Feed/Groups/Activities/People/Chats/Conversation/Settings + metadata event | PASS: giữ route; UID khác vẫn đi auth error gate, sign-out về Login | regression.log |
| Profile draft + cập nhật tên/provider | PASS: không mất text, metadata mới đọc được | regression.log |
| Success tự đóng/Close/đổi trang + giữ PDF | PASS: không replay trên trang khác, PDF còn nguyên | regression.log |
| Full Flutter suite | PASS 81/81 | docs/evidence/08/navigation-fix/tests.log |
| Analyze | PASS No issues found | analyze-final.log |
| Format check | PASS 58 files, zero changes | format.log |
| Android debug build + adb install -r | PASS, app mở trên Pixel 9 Android17, giữ dữ liệu | android-build-final.log, install.log |
| Android read-only smoke sau thao tác chọn lại Spotify hiện có | PASS quan sát vẫn ở Connected Apps, không có banner thành công cố định | android-save.xml, android-after-feedback.xml; screenshots trong tool output |
| Firestore/Storage Rules | Không đổi; 35/35 ở lượt bugfix trước, KHÔNG chạy lại lần này | docs/evidence/08/bugfix/rules-java21.log |
| 2-account cloud E2E / Storage upload thật / FCM delivery / ARTEMIS | NOT RUN lần này; không được thay bằng widget tests | gate toàn Lab3 còn mở |

Native smoke không tạo post/message hoặc đổi privacy, không đổi giá trị shortcut hiện có. XML không bắt được thời điểm snackbar đang hiện; thời hạn 3 giây được assert bằng widget test, không tuyên bố XML chứng minh cloud write hoặc Console evidence.

Initial-tests.log ghi lại lần thử dùng error snackbar bị che Retry/composer; lỗi này đã được sửa bằng inline errors, initial-tests-2.log và full suite sau đó PASS. Analyze ban đầu báo unused import/braces; analyze-final.log là kết quả sau sửa. Không đổi rules, dependency, billing, project config hoặc deploy.

## Changed files

lib/app.dart; lib/viewmodels/auth_view_model.dart; lib/viewmodels/feature_actions.dart;
lib/firebase/firestore_hobby_repository.dart; lib/widgets/feature_widgets.dart;
lib/features/settings/screens/settings_screens.dart; lib/features/auth/screens/auth_settings_panel.dart;
test/full_ui_test.dart (helper injection); test/navigation_feedback_test.dart;
docs/navigation-feedback-report.md; docs/architecture.md; docs/design-traceability.md;
docs/figma-ui-report.md; docs/full-implementation-report.md; README.md;
docs/evidence/08/navigation-fix/ logs và XML thực.

COMMIT/PR/DEPLOY: NOT CREATED; không có .git nên git status/diff unavailable.
READY FOR HUMAN REVIEW: YES.
NEXT PHASE: NOT STARTED.
