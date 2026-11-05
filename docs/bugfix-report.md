# Sửa lỗi sau audit — 03/11/2026

PHASE: 03–08 | Correctness, recovery, UI and regression verification
STATUS: PARTIAL — các sửa cục bộ đã qua kiểm tra; không phải nghiệm thu mọi dịch vụ cloud.

## Phạm vi và quyết định review

User yêu cầu sửa các lỗi đã audit và kiểm thử lại các chức năng. Giữ MVVM/Riverpod, Firebase thật, bốn tab, custom hobbies và ba flow Lab 2. Không sửa input reference, không deploy Rules/cloud, không nâng billing, không tạo account hoặc tin nhắn cloud giả. Không có thư mục .git; không thể so sánh với Git baseline hoặc tạo bằng chứng lịch sử commit.

| Finding | Quyết định / sửa | Bằng chứng |
|---|---|---|
| Timer không pause khi đổi tab | Accepted P1. Shell gọi chính sách pause/persist trước goBranch; tôn trọng cả true/false, giữ notes | regression_fixes_test: hai ca pauseOnExit |
| Chọn lịch cùng hobby giữ plan ID cũ | Accepted P1. So sánh cả hobby/plan; bảo vệ draft đang chạy hoặc có notes; đổi hobby không tái dùng initialPlan của hobby trước; hủy xác nhận không auto-start | regression_fixes_test: A/B và Finish chỉ hoàn thành B |
| Inbox đọc nhầm notification_preferences | Accepted P2. Loại khóa config khỏi danh sách notification; bỏ qua bản ghi JSON/sai kiểu bị hỏng; không xóa preferences hoặc data của owner khác | unit test LocalOwnerStore dùng mock storage, Android thấy empty inbox thay error |
| 200% text overflow và ô ngày nhỏ | Accepted P2. Calendar cuộn ngang khi thiếu chỗ, mỗi ô >=48dp, chiều cao theo nội dung; bottom nav font 12sp và chiều cao theo text scaler | Home 360/412, các route signed-in 360dp 200%; tests-final.log |
| Settings thất bại nhưng vẫn hiển thị lựa chọn mới | Accepted P2. Rollback, giữ fields vừa thử để Retry; không báo lựa chọn đã lưu khi write thất bại | widget test failWrites rồi retry thành công |
| Sender chưa opt-in nhưng vẫn có nút Chat | Accepted P2. Hiện Enable chat, đưa tới Privacy; người nhận private vẫn không mở chat; mô tả rõ hai bên cần allowMessages, lịch sử vẫn đọc được | widget test không tạo chat khi chưa opt-in; 35 Rules tests giữ deny-by-default |
| Chat dài đẩy composer ra ngoài màn | Accepted P2. Body bounded, ListView reverse hiển thị tin mới ở đáy, composer ở ngoài vùng cuộn và tránh keyboard | 100 message fixtures, keyboard 300px, fail/retry giữ draft và ghi một tin |
| Diagnostics lẫn vào profile | Accepted UX. Gom công cụ Lab3 trong ExpansionTile có nhãn; vẫn giữ đủ PDF, config và crash test có gate debug/confirmation | render toàn bộ screens + Android build |
| Error UI đánh đồng dữ liệu hỏng với lỗi mạng/quyền | Accepted UX. AsyncPanel giữ message của DataFailure, lỗi không rõ dùng thông báo chung có Retry | full widget suite; không đưa exception/raw backend info vào UI |
| Ngôn ngữ Việt/Anh, nhãn nhỏ khác và Figma exact parity | Còn cần editorial/visual acceptance; không tuyên bố đã hoàn thiện toàn bộ typography hoặc localization | docs/figma-ui-report.md |

## File đã sửa

- lib/viewmodels/hyper_view_model.dart
- lib/features/shell/screens/app_shell.dart
- lib/services/local_owner_store.dart
- lib/features/settings/screens/settings_screens.dart
- lib/features/practice/screens/practice_screens.dart
- lib/features/community/screens/community_screens.dart
- lib/widgets/feature_widgets.dart
- lib/widgets/app_navigation_bar.dart
- test/regression_fixes_test.dart (10 regression cases; fixtures chỉ trong test)
- README.md; docs/full-implementation-report.md; docs/figma-ui-report.md; docs/design-traceability.md; docs/open-decisions.md; docs/bugfix-report.md
- docs/evidence/08/bugfix/: logs thực; không có screenshot placeholder. Không thêm dependency vào pubspec.

## Kết quả thực tế

| Check | Kết quả | Evidence |
|---|---|---|
| dart format --output=none --set-exit-if-changed . | PASS, 57 files, 0 changes | docs/evidence/08/bugfix/format.log |
| flutter analyze --no-pub | PASS, No issues found | docs/evidence/08/bugfix/analyze-final.log |
| flutter test --no-pub --reporter expanded | PASS, 77/77 (gồm 10 regression cases) | docs/evidence/08/bugfix/tests-final.log |
| flutter build apk --debug --no-pub | PASS | docs/evidence/08/bugfix/android-build.log |
| adb install -r APK; launch MainActivity | PASS, Success, cài giữ data; app render trên Pixel 9 Android 17 | docs/evidence/08/bugfix/android-install.log; screenshot trong chat/tool output |
| Firestore + Storage Emulator Suite | PASS, 35/35 với Java 21 | docs/evidence/08/bugfix/rules-java21.log |
| Lần Rules đầu với Java 26 | FAIL khởi động/đăng Rules emulator, chưa chạy tests; sau đó đổi Java 21 đạt | docs/evidence/08/bugfix/rules.log |
| git status / git diff --check | NOT AVAILABLE: thư mục không có .git | không tạo Git metadata giả; dùng format và kiểm tra whitespace riêng |
| Trước sửa: plan/tab/text scale | FAIL tái hiện thực | before-plan.log, before-timer.log, before-large-text.log |
| Android native mọi workflow / hai cloud users / offline / process-kill | NOT RUN đầy đủ | test doubles và emulator không thay thế kiểm thử hai tài khoản cloud |
| FCM delivery, Analytics/Crashlytics Console, Remote Config console switching | NOT RUN | cấp quyền thông báo không chứng minh FCM delivery |
| Upload Cloud Storage thật | BLOCKED/chưa kiểm chứng điều kiện dịch vụ và approval billing | không tự nâng gói hoặc deploy |
| ARTEMIS | NOT RUN | chưa có thực thi host/model/key workflow |

Các raw logs mang tên before-* là failure trước sửa; tests-final.log là kết quả source sau sửa. Android XML chỉ là UI state quan sát tại thời điểm Connected Apps; không dùng làm bằng chứng Notifications hoặc hoàn tất flow. Báo cáo này không khẳng định mọi lựa chọn Settings đã được thử trên cloud. Không tự gửi tin nhắn hoặc tạo dữ liệu trên tài khoản production của user.

## Test thủ công còn cần

1. Với account A/B do owner cung cấp: create/edit/duplicate hobby, priority giữ lịch/history, reload; Home schedule -> Hyper pause/resume/notes -> Finish duy nhất một record -> reload.
2. Join group, group chat và DM giữa A/B, quyền user không thuộc hội thoại, privacy off; post/like/comment, RSVP không auto-add, Add to Home đúng một lịch.
3. Offline/reconnect, process-kill/checkpoint timer, FCM foreground/background/terminated, reminders sau cấp quyền/boot, PDF share/upload URL với per-user rules và console evidence.
4. Visual acceptance Figma cùng viewport, text scale và keyboard trên thiết bị; Groups & follows và Preferred reminder time vẫn là gap đã ghi nhận, không tự thêm model/quyền chưa được duyệt.

COMMIT/PR/DEPLOY: NOT CREATED.
READY FOR HUMAN REVIEW: YES — code và kiểm thử local; toàn app chưa nghiệm thu hoàn tất.
NEXT PHASE: NOT STARTED.
