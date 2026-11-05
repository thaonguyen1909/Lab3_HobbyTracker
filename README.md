# Hobby Tracker

**Lập lịch tập trung mới:** chọn nhanh sở thích, tự điền tên, thời lượng 15p/30p/1 giờ/2 giờ hoặc tùy chỉnh; lặp hằng ngày/tuần có ngày kết thúc. [Thiết kế và kết quả kiểm tra](docs/quick-schedule-update.md).

**Khoảnh khắc — kiến trúc mới 04/11/2026:** Firebase Auth/Firestore/FCM + backend Node.js riêng + Cloudinary. Thử qua USB theo [hướng dẫn hiện hành](docs/moments-cloudinary-run.md); trạng thái triển khai tại [báo cáo retest](docs/moments-retest-report.md). Các báo cáo Storage/Functions cũ là lịch sử.

Ứng dụng Android Flutter + Firebase cho PRM393 Lab 3. Kiến trúc MVVM/Riverpod, hỗ trợ English/Tiếng Việt và 7 giao diện màu.

## Source và tài liệu

```text
HobbyTracker/
├── lib/                  # Mã Flutter: màn hình, ViewModel, model, service
├── android/              # Cấu hình và mã Android
├── assets/               # Font và SVG dùng trong app
├── firebase/             # Rules, indexes và kiểm thử quyền
├── test/                 # Unit/widget tests và ảnh golden
├── e2e_test/             # Bộ kiểm thử ARTEMIS
├── scripts/              # Công cụ setup/audit
├── docs/                 # Toàn bộ tài liệu, yêu cầu, thiết kế, evidence
├── pubspec.yaml
├── pubspec.lock
├── firebase.json
├── analysis_options.yaml
├── AGENTS.md             # Quy tắc làm việc cho agent
└── README.md
```

Xem [mục lục tài liệu](docs/README.md). Các file yêu cầu gốc ở [docs/requirements/reference](docs/requirements/reference/); chúng được di chuyển nguyên nội dung, không chỉnh sửa.

## Chạy Android

```powershell
flutter pub get
flutter devices
flutter run -d <device-id>
```

Android application ID: `vn.prm393.hobbytracker`.

Máy mới cần tự cấu hình Firebase: đăng ký đúng package Android/SHA, bật Google và Email/Password Authentication, tạo Firestore và áp dụng Rules đã review. Đặt file `google-services.json` riêng của project tại `android/app/google-services.json`. File này đã được bỏ qua bởi Git. Không thay Rules bằng quyền mở cho tất cả người dùng.

## Kiểm tra

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Kiểm thử quyền trên emulator cục bộ:

```powershell
npm --prefix firebase ci
npx firebase-tools@14.22.0 emulators:exec --only firestore,storage --project demo-hobbytracker-full "npm --prefix firebase run test:all"
```

Dùng Java 21 cho bộ emulator đã pin. Lệnh trên chạy project `demo-`, không deploy Rules lên cloud.

## Tính năng và trạng thái

- Hobby tùy chỉnh; lịch luyện tập; Hyper Mode, ghi chú và lịch sử.
- Feed, nhóm, hoạt động/đăng ký tham gia, hồ sơ công khai và chat có phân quyền Firebase.
- Settings, ngôn ngữ Anh/Việt lưu trên thiết bị, 7 theme, xuất PDF và các adapter dịch vụ Firebase.
- Sau khi sắp xếp: 96 Flutter tests đạt, analyze sạch và APK debug build thành công. Logs: `docs/evidence/08/reorganization/`. Bản ngôn ngữ đã được cài trên Pixel 9 trước đó.
- Chưa nghiệm thu đầy đủ hai tài khoản cloud, delivered notifications, Storage upload/billing, Console evidence, ARTEMIS và Figma parity. Không coi code/test fixtures là bằng chứng cloud thành công.

[Báo cáo tích hợp](docs/full-implementation-report.md) · [Anh/Việt](docs/localization-report.md) · [Checklist còn thiếu](docs/full-manual-checklist.md).

## Mở rộng Khoảnh khắc 3 giờ

Đã có source đăng/xem ảnh theo nhóm, popup/inbox, Android notification worker và cleanup có retry. Bước 4 chạy đạt 145 test Flutter và 87 test backend/Rules/CLI trên local, analyze sạch, APK debug build được. Chưa deploy backend hoặc nghiệm thu push/ba giờ trên hai điện thoại thật.

[Báo cáo bước 4](docs/moments-cleanup-step4-report.md) · [Chạy local](docs/moments-local-run.md) · [Demo và nghiệm thu](docs/moments-demo-acceptance.md).

## Đưa lên GitHub

Có thể quản lý toàn bộ thư mục này trong một repository: source ở các thư mục chuẩn, tài liệu gói gọn trong `docs/`. Giữ `pubspec.lock`, Gradle wrapper và các file cấu hình source trong Git.

`.gitignore` loại build/cache, `node_modules`, Firebase config cục bộ, `.env`, khóa và keystore. Nếu upload bằng giao diện web, tự bỏ những file/thư mục này vì upload thủ công không áp dụng `.gitignore` như `git add`. Không cần upload APK/build để chạy source.

Chưa tạo commit/remote hoặc push GitHub trong phiên sắp xếp này.
