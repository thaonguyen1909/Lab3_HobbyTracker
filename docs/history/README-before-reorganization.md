> **Anh / Việt:** Settings → Language (Cài đặt → Ngôn ngữ). Lựa chọn lưu trên thiết bị và giữ khi mở lại/đăng xuất. 96 Flutter tests đạt; xem [báo cáo](docs/localization-report.md). Tên và nội dung người dùng nhập không bị tự dịch.

> **Bản sửa mới nhất 03/11/2026:** Lưu Settings giữ đúng trang; thông báo thành công tự ẩn sau 3 giây. 81 Flutter tests đạt, analyze sạch, APK đã cài lên Pixel 9. Xem [báo cáo](docs/navigation-feedback-report.md).

> **03/11/2026 — bản sửa sau audit:** APK đã build/cài trên Pixel 9; 77 Flutter tests và 35 Firestore/Storage Rules emulator tests đạt, analyze sạch. Xem [báo cáo sửa lỗi](docs/bugfix-report.md) cho thay đổi và những kiểm chứng cloud/ARTEMIS còn thiếu. Các ghi chú thiếu Android SDK bên dưới mô tả môi trường cũ.

> Cập nhật giao diện Figma 03/11/2026: đọc `docs/figma-ui-report.md` trước. Quyền Figma đã được giải quyết; các ghi chú cũ nói Figma BLOCKED là lịch sử. Các gate Android/Firebase/ARTEMIS vẫn chưa được thay bằng PASS.

# Hobby Tracker — PRM393 Lab3 integrated source

**03/11/2026: implementation spans all phases 00–08 in one pass. Overall PARTIAL, not 100% accepted.**

Flutter analyze clean, 63 Flutter unit/widget tests and 35 Firestore/Storage emulator tests pass. Android SDK, Firebase project config/Console evidence, Figma parity and real ARTEMIS execution remain unavailable. See [full report](docs/full-implementation-report.md) and [one combined checklist](docs/full-manual-checklist.md). Historical Phase02 reports are superseded by the full report.

## Included

MVVM/Riverpod, real Firebase Auth, owner-scoped custom hobbies/unique names, calendar/schedules, Stopwatch Hyper Mode and immutable history, feed/likes/comments, groups/events/RSVP, opt-in People/DM/group chat, settings and 7 theme foundations, Unicode PDF export/share, Storage upload/progress/URL, FCM inbox/deep links, local reminders, Analytics/Crashlytics/Remote Config, native Android template, rules/tests and ARTEMIS acceptance suite. No production seed users/posts or fake success.

Application ID: `vn.prm393.hobbytracker`. This is a source-level default; register this exact ID in your Firebase project or deliberately update native package/namespace before registering.

## Run

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
npm --prefix firebase ci
firebase emulators:exec --only firestore,storage --project demo-hobbytracker-full "npm --prefix firebase run test:all"
```

On CI use `CI=true`, `FLUTTER_SUPPRESS_ANALYTICS=true`, and `METADATA_SERVER_DETECTION=none` for the Firebase CLI to avoid metadata probing. Linux root containers may require `TAR_OPTIONS=--no-same-owner` for Flutter SDK archive extraction.

Configure your own Firebase project (`flutterfire configure --platforms=android`), providers/SHA and rules before `flutter run`. No credentials/config are invented. Code still shows a setup gate until native default Firebase options exist. Optional intentional crash test: debug build with `--dart-define=ENABLE_CRASH_TEST=true`, then type CRASH and confirm in Profile demo area.

## Evidence and architecture

- [Architecture](docs/architecture.md), [Data model](docs/data-model.md), [Analytics plan](docs/analytics-plan.md), [Review](docs/code-review.md).
- `evidence/full/`: actual local logs. `test/goldens/`: rendered test UI, not Android/cloud evidence.
- `e2e_test/`: inspected/pinned ARTEMIS SDK interface, 17 cases with 3 requested runs each plus opt-in Pro exploration. Not executed on a device here.
- `reference/`: unchanged original Lab2 materials and three requirements PDFs. Final web/admin/AI is outside current Lab3 scope.
- Flutter 3.47.9 / Dart 3.13.7. All plugin pins in pubspec.yaml and pubspec.lock. Node 24.22.1, Java 17, Firebase CLI 14.22.0 / emulator versions in logs. Native Gradle/plugin compatibility is not yet verified because Android SDK is missing.

AI disclosure: Codex implemented and reviewed source/tests/docs. Fixtures are confined to test/emulator paths. No Git history, PR review service, deployment, cloud success, final demo video or teacher approval is fabricated.
