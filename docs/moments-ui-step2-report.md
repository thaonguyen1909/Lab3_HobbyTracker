# Khoảnh khắc — bước 2: đăng và xem trên Flutter

Ngày 04/11/2026. Phạm vi do người dùng yêu cầu: triển khai bước 2 sau backend bước 1. **Đã có source UI + adapter thật và 119 test Flutter đạt; chưa nghiệm thu thiết bị/cloud.** Đây là phần mở rộng Community phase 05, không phải phase 02 Authentication hay xác nhận toàn bộ Lab 3 hoàn tất.

## Hành vi đã triển khai

- Community Feed/thẻ nhóm đã tham gia → Khoảnh khắc → chọn nhóm, xem danh sách 6 mục/lần, refresh/load more.
- Form chọn/chụp ảnh, preview, chọn hobby Active hoặc Interested, caption, giới hạn bytes/định dạng, progress upload, hủy và retry. Lỗi giữ nội dung. Chống double submit; giữ request ID và kiểm tra publish trước khi thử ghi lại source sau mất phản hồi upload. Publish không rõ kết quả khóa chỉnh sửa để retry cùng giao dịch trong màn đang mở.
- Viewer gọi metadata và ảnh qua callable có auth; đếm ngược theo thời gian server + Stopwatch. Hết hạn bỏ ảnh; background bỏ state và resume kiểm tra lại quyền. Tác giả được thu hồi bằng xác nhận; thành viên khác không có nút này.
- Caption/hobby/request ID lưu local theo UID/nhóm. Ảnh chỉ trong memory của app; hỗ trợ retrieveLostData cho Android picker, ràng buộc UID. Đổi UID/dispose bỏ kết quả cũ. Không dùng getDownloadURL/direct read ảnh đã publish.
- Anh/Việt, reuse theme/components, giữ bốn tab. Chế độ debug Firebase Emulator có nhãn rõ, named app demo riêng; không giả lập thành công trên Firebase cloud.

## Files của bước 2

| Phần | Files |
|---|---|
| Model, state | lib/models/group_moment.dart, lib/viewmodels/moment_view_models.dart |
| Contracts, picker, draft, providers | lib/services/moment_repository.dart, moment_photo_picker.dart, local_moment_draft_store.dart, moment_providers.dart |
| Firebase adapter/runtime | lib/firebase/firebase_moment_repository.dart, firebase_runtime.dart; main.dart, app.dart, app_services.dart, auth_service_provider.dart; firebase_auth_service.dart, firebase_device_services.dart |
| UI, route, language | lib/features/community/screens/moments/*; community_screens.dart; app/router/*; l10n/messages.dart; widgets/hobby_text_field.dart |
| Android/dependencies | debug/AndroidManifest.xml; android/gradle.properties; pubspec.yaml/lock |
| Test | test/moment_view_models_test.dart, moments_ui_test.dart, support/moment_fakes.dart, fixtures/moment.jpg |
| Developer guide | scripts/start-moments-emulators.ps1; moments-local-run.md; architecture/design-traceability/open-decisions/docs index/proposal/backend contract |

cloud_functions **5.4.0** phù hợp firebase_core 3.x đang pin; image_picker **1.2.0** phù hợp Dart/Flutter minimum của repo. Không nâng toàn bộ Firebase stack hoặc Flutter minimum. Android cleartext chỉ cho debug để kết nối emulator HTTP. Giữ kotlin.incremental=false đã có của người dùng. Sau Gradle JVM thiếu native memory, giảm heap 8G → 2G, metaspace 4G → 1G, code cache 512m → 256m, tối đa 2 worker để phù hợp máy 16 GB.

## Kiểm chứng thực tế

| Kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| Dependency resolution | PASS | flutter pub get, exit 0; lockfile cập nhật |
| Format | PASS | [format.log](evidence/05/moments-ui/format.log): 76 files, 0 changed |
| Phân tích tĩnh | PASS | [analyze-final.log](evidence/05/moments-ui/analyze-final.log): No issues found, exit 0 |
| Toàn bộ Flutter tests | PASS, **119/119** | [flutter-tests-final.log](evidence/05/moments-ui/flutter-tests-final.log), exit 0 |
| UI mới | PASS, 7 tests trong 119 | Post/retry/view/expiry ở 360/412dp × en/vi; chưa tham gia nhóm; lifecycle/quyền; form 200% text |
| State/error mới | PASS, 16 tests trong 119 | Validation, mất ack upload/publish, không nhân đôi, cancel/dispose, UID draft, clock, pagination, expired/late image, revoked permission, local config guards; session hết hạn khác transport timeout |
| Build APK debug local | PASS | [android-build-final.log](evidence/05/moments-ui/android-build-final.log), exit 0; APK build/app/outputs/flutter-apk/app-debug.apk; [SHA256](evidence/05/moments-ui/apk-sha256.log) |
| Thiết bị USB | NOT RUN | adb devices -l trả danh sách trống; chưa cài app/chạy camera/gallery thực |
| Firebase Rules/backend | Không thay đổi ở bước 2 | 60 test đã PASS ở [bước 1](moments-backend-step1-report.md); không tuyên bố chạy lại trong bước 2 |
| Hai người dùng/ba giờ thật/cloud | NOT RUN | Chưa kết nối thiết bị, chưa deploy/đổi billing |

Lượt full suite chạy song song đầu dừng sau 22 test, không có kết quả cuối; giữ log riêng, không tính PASS. Chạy lại tuần tự được 117/117 trong 65 giây, sau bổ sung xử lý session hết hạn chạy cuối được 119/119 trong 64 giây. Test lifecycle ban đầu kiểm tra widget tree khi Flutter paused nên FAIL; sửa thành kiểm tra state bỏ ảnh khi paused và widget bỏ ảnh ở frame resumed. Tất cả tests sau sửa đạt. Không dùng kết quả fake repository làm bằng chứng cloud.

## Giới hạn còn mở

1. Chưa có popup/FCM ảnh nền, notification inbox/deep link, mute, defer Hyper hoặc friendship. Đây là bước 3+, không tự triển khai trong bước 2.
2. Chưa deploy Functions/Rules lên project thật. Chưa bật billing. App mặc định có thể báo dịch vụ khoảnh khắc chưa khả dụng; thử theo [hướng dẫn local](moments-local-run.md).
3. Caption/hobby lưu qua đóng app; bytes ảnh/ticket/trạng thái publish chưa lưu bền vững. Phải chọn ảnh lại sau rời màn/restart, trừ trường hợp Android lost picker recovery. Chưa bảo đảm retry chống trùng sau kill process ở mọi thời điểm.
4. Quyền được kiểm tra mỗi lần tải và khi resume, không subscribe thu hồi ảnh tức thời trên thiết bị đang mở. Hết hạn chặn đọc backend dù file chưa xóa; cleanup định kỳ còn thiếu. Không thu hồi screenshot/bản sao đã tải/OS snapshot.
5. Session 10 phút/quota có thể yêu cầu đợi. Adapter phân biệt hai message session-expired chính xác của backend hiện tại với timeout transport: session hết hạn tạo request mới nhưng giữ ảnh/text, timeout không rõ kết quả tiếp tục cùng request. Nếu backend thay message, cần đồng bộ contract/test (không mặc định mọi timeout là hết hạn). Caption code points khác bộ đếm grapheme của TextField với một số emoji; backend luôn kiểm tra 160 code points, lỗi giữ draft.
6. Cần human visual review các màn mở rộng, camera/gallery thực, offline, A/B/C cùng/ngoài nhóm và một phiên đủ ba giờ. Sáu cảnh báo npm moderate/audit endpoint ECONNRESET từ bước 1 còn mở trước deploy.

## Báo cáo theo hợp đồng repository

```text
PHASE: 05 | Community extension — moments Flutter step 2
STATUS: PARTIAL
SCOPE: Source đăng/xem/thu hồi và debug emulator runtime; chưa popup/push/cleanup/cloud
CHANGED FILES: Danh sách trong bảng Files của bước 2; giữ thay đổi bước 1 và người dùng
DESIGN TRACEABILITY: docs/design-traceability.md — Moments Flutter step 2
ACCEPTANCE GATES:
  [PASS] 119 Flutter unit/widget tests, gồm 23 mới
  [PASS] Format 76 files, 0 changed
  [PASS] flutter analyze: No issues found
  [PASS] Android debug emulator APK built from final source
  [PASS] git diff --check, touched Markdown local links and PowerShell script syntax
  [NOT RUN] Device picker/two-account/three-hour/cloud acceptance
COMMANDS ACTUALLY RUN:
  - flutter pub get -> 0
  - dart format --output=none --set-exit-if-changed lib test -> 0
  - flutter analyze -> 0, No issues found
  - flutter test --no-pub --concurrency=1 --reporter expanded -> 0, 119/119
  - adb devices -l -> 0, no devices
  - flutter build apk --debug --no-pub --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1 -> final 0, initial 1 (JVM native memory)
SECURITY & DATA CHECK: UID-scoped state/drafts; private callable bytes; previous backend Rules evidence remains separate
OPEN DECISIONS / RISKS: Device/visual/cloud acceptance; durable publish recovery, cleanup, existing dependency audit
COMMIT/PR/DEPLOY: NOT CREATED
READY FOR HUMAN REVIEW: YES
NEXT PHASE: NOT STARTED
```
