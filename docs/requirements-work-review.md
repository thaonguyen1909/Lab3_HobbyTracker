# Đối chiếu 3 tài liệu trong ZIP — 03/11/2026

Đã trích xuất văn bản của cả 3 PDF được giao và đọc các tiêu chí liên quan, đối chiếu với source, AGENTS, roadmap và handoff. Các bản PDF/HTML/PPTX gốc được giữ nguyên; báo cáo cũ chỉ là lịch sử, không tự chứng minh runtime.

| Nguồn | Phạm vi / tác động | Hiện trạng |
|---|---|---|
| PRM393_Lab3_Requirements.pdf, mục 3–6 | Lab2 screens/flows/design system; MVVM + Provider/Riverpod; Google Sign-In, auth routing, logout, cancel; service boundary; private Firestore data | Phase02 được kiểm tra trong đợt này. Các flow nghiệp vụ vẫn chưa làm. Cần Android + Console evidence trước PASS. |
| Cùng tài liệu, mục 6–9 | Sáu dịch vụ Firebase; tạo file và upload Cloud Storage theo UID; ≥7 analytics events; ARTEMIS ≥10 ca, mỗi ca 3 lượt, native/error, exploratory; AI review | Thuộc các phase tiếp theo; unit/widget/rules tests hiện tại không thay ARTEMIS hoặc Console evidence. |
| PRM393_Lab3_Preparation_Guide.pdf, trang 2–7 | Flutter/Android/Firebase/SHA, test account; MVVM; Google cancel/logout/guard và bằng chứng | Work chuẩn bị công cụ và tests được phép; chủ dự án cấu hình Firebase/Android thật. |
| Guide, trang 8–25 | Storage, FCM, Analytics, Crashlytics, RC, ARTEMIS, review/report | Không tự bật dịch vụ trả phí hay ghi chúng là hoàn thành. |
| PRM393_Final_Assignment_Requirements.pdf, mục 3–9 | Mobile + web admin/shared package, roles, cross-role flow, App Check, AI Logic | Là Final, nằm ngoài Phase02/Lab3 hiện tại; chưa triển khai. |
| Final, mục 4 so với Lab3 mục 3/6 | Final loại Cloud Storage và dùng file local + metadata; Lab3 yêu cầu upload cloud | Không lấy Final để bỏ yêu cầu Storage của Lab3. Chủ dự án/giảng viên cần chốt nếu muốn đổi rubric; D02 vẫn OPEN. |

## Các gap chính tìm thấy

- ZIP thiếu native Android folder, Firebase project configuration, dependency lock và evidence runtime Phase02 tại thời điểm nhận.
- Static checks cũ không kiểm tra kiểu Dart, resolve SDK, behavior adapter hoặc rules thực; không dùng chúng làm tiêu chí PASS duy nhất.
- `asyncMap` trước đây xếp hàng auth events sau profile I/O: sign-out có thể phải chờ và kết quả của identity cũ có thể xuất hiện muộn. Đã thay bằng identity stream độc lập và FutureProvider profile gate, có tests.
- Register S02 trong Specification/handoff có trường tên; source chỉ có email/password/confirmation. Đã bổ sung tên, validation và lưu profile; đối chiếu visual với Figma vẫn cần quyền truy cập.
- Những màn Hobbies/Home/Community phần lớn là placeholder có nhãn rõ; hiện diện route không đồng nghĩa hoàn tất màn hình.
- D01/D05 về Figma và provenance còn mở; không sửa nguồn gốc hoặc duyệt thay giảng viên.

Nguồn SDK tham khảo bổ sung (không thay rubric): https://firebase.google.com/docs/auth/flutter/start và https://docs.flutter.dev/install/archive . Firebase `userChanges()` được dùng để cập nhật profile/provider sau liên kết, cùng auth changes.
