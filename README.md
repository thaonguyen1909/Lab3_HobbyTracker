# Hobby Tracker

**Dự án PRM393 — Lab 3 | Ứng dụng quản lý và duy trì sở thích cá nhân**

Hobby Tracker giúp người dùng biến sở thích thành hoạt động thường xuyên: chọn việc muốn làm, sắp xếp thời gian, tập trung luyện tập và theo dõi kết quả. Dự án phát triển từ thiết kế UI/UX của Lab 2 thành ứng dụng Android bằng Flutter, sử dụng Firebase để đăng nhập và lưu trữ dữ liệu.

> **Trạng thái:** Đang chuẩn bị triển khai. Repository hiện có README, hướng dẫn AGENTS.md, roadmap và các prompt; các tính năng và công nghệ bên dưới là kế hoạch, chưa được tích hợp hoặc kiểm thử.

## Ứng dụng sẽ làm được gì?

| Nhóm tính năng | Người dùng có thể làm gì? |
| --- | --- |
| Tài khoản | Đăng nhập bằng Google, quản lý thông tin cá nhân và đăng xuất. |
| Sở thích cá nhân | Tạo và chỉnh sửa sở thích, chọn biểu tượng, màu sắc và trạng thái Active hoặc Interested. |
| Lịch luyện tập | Lên lịch cho từng sở thích và xem các hoạt động theo ngày. |
| Hyper Mode | Chạy bộ đếm thời gian, tạm dừng, tiếp tục, ghi chú và lưu kết quả buổi tập. |
| Lịch sử | Xem lại thời gian luyện tập và ghi chú đã lưu. |
| Cộng đồng | Chia sẻ bài viết, tham gia nhóm, trò chuyện và đăng ký hoạt động. |
| Cài đặt | Thay đổi giao diện, tùy chọn luyện tập và thông báo. |
| Báo cáo | Tạo và chia sẻ file PDF tổng hợp hoạt động. |

Bốn tab chính: **Home · Community · My Hobbies · Settings**.

Các nguyên tắc giữ từ thiết kế Lab 2:

- Người dùng tự tạo sở thích; cả Active và Interested đều có thể lập lịch và luyện tập.
- Đổi trạng thái sở thích không làm mất lịch hoặc lịch sử.
- Đăng ký tham gia sự kiện (RSVP) chỉ thêm vào lịch cá nhân khi người dùng bấm **Add to Home**.
- Một lần kết thúc buổi tập chỉ tạo một bản ghi kết quả.

## Công nghệ dự kiến sử dụng

### Ứng dụng và kiến trúc

| Công nghệ | Vai trò trong dự án |
| --- | --- |
| **Flutter + Dart** | Xây dựng giao diện và xử lý hoạt động của ứng dụng Android. |
| **Material Design + ThemeData** | Tạo các thành phần giao diện thống nhất và hỗ trợ 7 theme theo thiết kế Lab 2. |
| **Riverpod** | Quản lý trạng thái màn hình và cung cấp các dịch vụ cần dùng. |
| **go_router** | Điều hướng giữa các màn hình và kiểm soát đường dẫn cần đăng nhập. |
| **MVVM** | Tách giao diện (View), logic màn hình (ViewModel) và dữ liệu (Model) để dễ bảo trì. |
| **Repository/Service + dependency injection** | Tách phần truy cập Firebase khỏi giao diện và giúp thay thế dịch vụ khi kiểm thử. |

### Dữ liệu và các dịch vụ Firebase

| Công nghệ | Vai trò trong dự án |
| --- | --- |
| **Firebase Authentication + Google Sign-In** | Xác thực tài khoản bằng Google. |
| **Cloud Firestore** | Lưu sở thích, lịch, lịch sử luyện tập và dữ liệu cộng đồng; cập nhật dữ liệu theo thời gian thực. |
| **Firestore Security Rules** | Kiểm soát quyền đọc/ghi, bảo vệ dữ liệu riêng và giới hạn truy cập trò chuyện theo thành viên. |
| **Firebase Cloud Messaging (FCM)** | Nhận thông báo trên thiết bị; cần cấu hình nguồn gửi và kiểm thử thực tế. |
| **Firebase Analytics** | Ghi nhận các sự kiện sử dụng để đánh giá những luồng chức năng chính. |
| **Firebase Crashlytics** | Theo dõi lỗi và sự cố khi ứng dụng chạy. |
| **Firebase Remote Config** | Điều chỉnh một số tùy chọn hoạt động mà không cần phát hành lại ứng dụng. |
| **Cloud Storage for Firebase — bắt buộc Lab 3** | Tải báo cáo theo UID, hiển thị tiến độ/URL, giới hạn quyền bằng Rules và cung cấp bằng chứng. Điều kiện hạ tầng/chi phí còn phải chốt; chưa có upload thì yêu cầu này chưa hoàn thành. |

Phần xuất PDF sẽ tách khỏi phần tải lên cloud để vẫn có thể tạo và chia sẻ báo cáo trên thiết bị. Xác minh điều kiện dịch vụ trước khi cấu hình; local PDF không thay thế upload Lab 3.

### Công cụ phát triển và kiểm thử

| Công cụ | Mục đích |
| --- | --- |
| **Git** | Quản lý phiên bản và theo dõi từng đợt triển khai. |
| **Android SDK + Android Emulator/thiết bị thật** | Build, chạy và kiểm tra ứng dụng Android. |
| **Flutter DevTools + flutter analyze** | Kiểm tra lỗi mã nguồn và hỗ trợ phân tích ứng dụng. |
| **flutter test** | Kiểm thử logic và các thành phần giao diện quan trọng. |
| **Firebase Emulator Suite** | Kiểm thử dữ liệu và Security Rules trong môi trường phát triển. |
| **Google ARTEMIS — bắt buộc Lab 3** | Kiểm thử các luồng người dùng từ đầu đến cuối và thu thập bằng chứng. |

Phiên bản Flutter, Dart và các thư viện sẽ được ghi cụ thể khi khởi tạo mã nguồn và kiểm tra tính tương thích.

## Cách tổ chức ứng dụng

Luồng xử lý dự kiến:

```text
Người dùng thao tác
        ↓
View — hiển thị giao diện
        ↓
ViewModel — xử lý logic và trạng thái
        ↓
Repository / Service — đọc, ghi dữ liệu
        ↓
Firebase
```

Màn hình gọi ViewModel; phần truy cập Firebase nằm trong Repository/Service. Các màn hình tải dữ liệu cần có trạng thái đang tải, có dữ liệu, chưa có dữ liệu và lỗi kèm thao tác thử lại.

## Lộ trình triển khai

1. Đối chiếu thiết kế Lab 2 và yêu cầu Lab 3, chốt các điểm còn thiếu.
2. Khởi tạo Flutter, giao diện chung, điều hướng và kiến trúc.
3. Tích hợp đăng nhập Google và bảo vệ dữ liệu người dùng.
4. Hoàn thiện sở thích, lịch luyện tập, Hyper Mode và lịch sử.
5. Triển khai cộng đồng, cài đặt và các theme.
6. Bổ sung báo cáo PDF, thông báo và các dịch vụ theo dõi ứng dụng.
7. Kiểm thử, sửa lỗi và chuẩn bị bằng chứng nộp Lab 3.

## Phạm vi triển khai hiện tại

Chỉ thực hiện Lab 3 theo phase 00–08 trong `prompts/`. Web quản trị, Staff/Admin, duyệt RSVP liên vai trò và Gemini trong app thuộc kế hoạch tham khảo tại `planning/final/roadmap.md`, chưa triển khai trong Lab 3. AI code review và ARTEMIS vẫn là yêu cầu Lab 3.

## Chạy dự án

Chưa có mã nguồn Flutter nên hiện chưa có bước cài đặt hoặc chạy ứng dụng. Hướng dẫn thiết lập, phiên bản công cụ và lệnh kiểm thử sẽ được bổ sung khi khởi tạo app.
