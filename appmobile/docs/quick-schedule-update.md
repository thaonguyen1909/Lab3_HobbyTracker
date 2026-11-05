# Lên lịch tập trung — cập nhật theo thiết kế mới

Ngày 04/11/2026. Người dùng yêu cầu thay form lập lịch hiện tại bằng phần “Đề xuất mới” trong [ảnh trước/sau của team](design/quick-schedule-proposal.png), dựa trên góp ý giảng viên do người dùng cung cấp. Người dùng xác nhận hỗ trợ **lặp hằng ngày hoặc hằng tuần, có ngày kết thúc**. Không sửa HTML/PDF gốc hoặc đổi cấu trúc bốn tab.

## Hành vi đã triển khai

- Mở form có tiêu đề Lên lịch tập trung và nút đóng; chọn nhanh từ sở thích thật đang có, tối đa ba ô hiện ngay, Khác mở toàn bộ danh sách hoặc tạo sở thích. Không hardcode Guitar/Gym/Đọc sách vào production.
- Tự chọn sở thích được truyền từ Hobby Detail hoặc sở thích đầu tiên; tự điền Luyện {tên sở thích}. Đổi sở thích chỉ thay tên tự động, giữ tên người dùng đã tự sửa. Tên trống lúc lưu dùng tên mặc định theo sở thích.
- Ngày mặc định lấy ngày đang chọn trên Home; giờ mặc định hiện tại. Ngày/giờ nằm cạnh nhau; chữ lớn chuyển thành hai dòng. Cả Active và Interested đều dùng được.
- Thời lượng 15p, 30p, 1 giờ, 2 giờ hiển thị bằng nút; Tùy chỉnh nhận số phút nguyên 1–1.440, gồm 75/90/120/150 phút. Lưu dưới dạng phút, không đổi sang chuỗi giờ.
- Lặp lại là phần mở rộng tùy chọn, mặc định không lặp. Hằng ngày/hằng tuần từ ngày bắt đầu tới ngày kết thúc (tính cả ngày cuối nếu đúng chu kỳ). Mặc định ngày cuối sau 28 ngày; có bộ chọn ngày thật và số buổi dự kiến. Tối đa 100 buổi/lần tạo.
- Các buổi lặp được tạo ngay thành lịch riêng trong một transaction; quản lý/hoàn thành/xóa riêng từng buổi, không có thao tác sửa/xóa cả chuỗi. Không thêm cron hoặc tự sinh vô hạn sau ngày cuối.
- Một request ID giữ nguyên khi retry trong form đang mở, mỗi buổi có ID ổn định. Retry không tạo trùng hoặc reset buổi đã hoàn thành. Một transaction thất bại không lưu một phần chuỗi; lỗi vẫn giữ tên/ngày/giờ/thời lượng. Không hứa khôi phục form sau process restart.
- Home có shortcut +30p hôm nay, +2 giờ tối nay, Lặp hằng tuần, Tùy chỉnh. Shortcut mở form điền sẵn, không tự lưu. Shortcut tối nay chọn 20:00 nếu chưa tới 20h, hoặc giờ hiện tại nếu đã qua 20h; CTA chính giữ ngày lịch đang chọn.
- Reminder và Hyper Mode vẫn dùng mỗi plan hiện có; timer ghi thời gian hoạt động thật, không ghi planned minutes thành thời gian luyện tập. RSVP không tự tạo lịch.

Giới hạn 24 giờ phù hợp với giới hạn lịch sử luyện tập hiện có; giới hạn 100 buổi là quyết định triển khai để giao dịch có giới hạn, không phải con số từ ảnh/PDF giảng viên. Không có thay đổi kỳ hạn ảnh/FCM/Cloudinary trong lượt này.

## Mã và dữ liệu

`lib/features/practice/screens/schedule_editor.dart` chứa form mới; Home và Hobby Detail mở form này. `models/schedule_draft.dart` kiểm tra thời lượng và tính ngày theo lịch, giữ giờ địa phương khi qua tháng/năm. FeatureActions chuyển yêu cầu thành danh sách plan. `HobbyRepository.createPlans` và Firestore adapter dùng transaction đọc trước/ghi sau, bỏ qua các ID có cùng nội dung, giữ done/completionId; xung đột nội dung bị từ chối.

Schema PracticePlan không thêm trường: vẫn hobbyId/title/startsAt/minutes/done/eventId/completionId. Dates lưu UTC như trước. Firestore Rule đổi đúng một điều kiện từ enum cố định sang **minutes is int, 1≤minutes≤1440**; quyền owner/hobby/history và mọi Rule Khoảnh khắc giữ nguyên. Snapshot cloud trước deploy đã đối chiếu tự động với source cũ, backup trong deployment-artifacts/quick-schedule-rollout (ignored).

## Kiểm tra và evidence

| Kiểm tra | Kết quả |
|---|---|
| Flutter toàn bộ | 166/166 — [flutter-all.log](evidence/04/quick-schedule/flutter-all.log) |
| Test nghiệp vụ/UI mới | 15/15 trong lượt targeted — [targeted-tests.log](evidence/04/quick-schedule/targeted-tests.log) |
| Render/UI sau tinh chỉnh font/nút | 8/8 — [visual-capture.log](evidence/04/quick-schedule/visual-capture.log) |
| Firestore Rules emulator riêng | 33/33, gồm custom duration/type/bounds/batch 100/cross-user atomic deny — [firestore-rules.log](evidence/04/quick-schedule/firestore-rules.log) |
| Analyze | Sạch — [analyze.log](evidence/04/quick-schedule/analyze.log) |
| Android build | [android-build.log](evidence/04/quick-schedule/android-build.log) |
| Cài APK qua USB R5CY81PSMAJ | Success — [android-install.log](evidence/04/quick-schedule/android-install.log), không clear data/không tự thao tác đăng nhập hoặc tạo lịch |
| Deploy chỉ Firestore Rules | Thành công — [firestore-deploy.log](evidence/04/quick-schedule/firestore-deploy.log) |
| Rules cloud khớp local, indexes cũ READY | Đạt — [firestore-post-deploy.json](evidence/04/quick-schedule/firestore-post-deploy.json) |

Ảnh render test fixtures: [360dp tiếng Việt](../test/schedule_review/schedule_360_vi.png), [412dp tiếng Việt](../test/schedule_review/schedule_412_vi.png), cùng bản English. Agent đã xem ảnh và sửa font của CTA qua kế thừa font theme trước build cuối. Ảnh cho thấy Tùy chỉnh xuống dòng ở màn hẹp để giữ vùng bấm; màn 412dp đủ chỗ cho cả năm lựa chọn. Test 200% chữ vẫn cuộn và lưu được.

APK cuối SHA256: 15fa137a9d294fc2d9dbf59cafa071b4240dddde082acedd771ecfef95479f5f. Giữ dart-define API Khoảnh khắc http://127.0.0.1:8787 và ADB reverse 8787. Build có cảnh báo workmanager_android/KGP đã có từ trước nhưng exit 0. Sau full suite 166 tests, các chỉnh font/padding tối thiểu 48dp chỉ chạy lại 8 UI tests, analyze và build; không cộng các lượt rerun thành số test duy nhất.

Không tạo lịch giả trên tài khoản production để quay demo, không thao tác chọn tài khoản Google/camera của người dùng. Native lưu/đồng bộ/nhắc lịch trên máy thật và xác nhận hình thức của người dùng còn cần nghiệm thu; unit/widget/emulator không thay bằng chứng đó. Không tự commit/push/merge.

## Cách thử

Home → chọn ngày → + Lên lịch: kiểm tra ngày giữ nguyên, chọn sở thích thật, chọn 2 giờ hoặc tùy chỉnh 75 phút → Tạo lịch. Mở lại Home phải thấy đúng giờ/phút. Lặp lại → Hằng tuần → chọn ngày kết thúc → Tạo lịch: xem các ngày tương ứng, hoàn thành một buổi qua Hyper và kiểm tra các buổi khác chưa bị hoàn thành.

```text
PHASE: 04 | Quick focus scheduling redesign
STATUS: PARTIAL (source/tests/cloud Rules ready; human/native acceptance pending)
SCOPE: New scheduling sheet, duration/custom, daily/weekly finite recurrence, atomic/idempotent creation, quick actions and localization
CHANGED FILES: schedule_editor.dart, schedule_draft.dart, practice/hobby screens, FeatureActions, repository/interface, feature_widgets, messages, Rules, tests and docs
DESIGN TRACEABILITY: User-supplied before/after image; docs/design-traceability.md
ACCEPTANCE GATES:
  [PASS] 166 Flutter tests; final UI rerun 8; 33 Firestore Rules tests; analyze; rendered 360/412dp en/vi
  [PASS] Rules deploy and readback match, existing indexes READY
  [NOT RUN] User approval and full phone save/sync/reminder acceptance
COMMANDS ACTUALLY RUN:
  - dart format/fix; flutter analyze/test; emulator firestore test:rules -> passing after fixes
  - firebase deploy only firestore:rules hobbytracker-6ace6 -> 0; readback -> 0
  - flutter build apk --debug with existing Moments API URL -> 0; adb install -r -> Success
SECURITY & DATA CHECK: Owner rules preserved, bounded integer duration and atomic writes; no production fake plans or billing changes
OPEN DECISIONS / RISKS: 24-hour/100-occurrence limits documented, no whole-series editing or process-restart draft recovery
COMMIT/PR/DEPLOY: No commit/PR; Firestore Rules deployed
READY FOR HUMAN REVIEW: YES
NEXT PHASE: NOT STARTED
```
