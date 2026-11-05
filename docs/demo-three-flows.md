# Kịch bản demo 3 flow Hobby Tracker

Thời lượng dự kiến: 7–9 phút, chưa bao gồm phần trình bày sáu dịch vụ Firebase và evidence kiểm thử của toàn bộ Lab 3. Tài liệu là kịch bản đối chiếu Specification và source hiện tại; kết quả bên dưới là điều cần quan sát khi diễn tập, chưa phải kết quả đã chạy trên hai tài khoản thật.

Nhãn nút dùng tiếng Anh theo giao diện hiện tại; nếu chọn Tiếng Việt trong Settings/Language, dùng nhãn tương ứng.

## Chuẩn bị trước buổi demo

- Hai tài khoản thật trong cùng Firebase project: A là người trình bày, B là bạn cùng nhóm. Dùng hai thiết bị Android nếu muốn minh họa nhận tin trực tiếp; một điện thoại đổi tài khoản chỉ chứng minh đọc lại tin sau đăng nhập.
- Đăng nhập thử cả A và B trước. Google cần được kiểm tra lại sau khi đăng ký đúng SHA-1 và tải lại google-services.json. Có thể diễn tập bằng email/password nếu đã bật provider này; ghi đúng phương thức thực tế, Google vẫn là tiêu chí riêng cần kiểm chứng của Lab 3.
- Kiểm tra A lưu được hobby, B tạo được nhóm/hoạt động và hai tài khoản truy cập Community được với Rules hiện có. Nếu lỗi permission-denied, kiểm tra quyền/Rules đúng dự án, không mở quyền toàn bộ để demo.
- Trên A và B: Settings → Profile đặt tên dễ nhận diện, ví dụ `Thao Demo A` và `Ban Demo B`; Settings → Privacy & Safety bật `Show my profile in People`, chọn `Everyone with an account`, chờ lưu xong.
- Trên B, chuẩn bị nhóm `Guitar Lab3 Demo`, chủ đề `Music`, mô tả `Cùng luyện guitar 15 phút mỗi ngày`; chuẩn bị hoạt động `Guitar Meetup Demo`, chủ đề `Music`, thời điểm ngày mai lúc 19:00. Đây là dữ liệu nhập thật qua app để thử nghiệm.
- Chọn Light và một ngôn ngữ thống nhất. A bắt đầu với tên hobby dưới đây chưa tồn tại. Nếu đã diễn tập, dùng hậu tố mới như `02` cho hobby, nhóm và hoạt động; không cần xóa dữ liệu cũ.
- Bật sẵn app trên cả hai máy, kiểm tra mạng, chạy thử toàn bộ một lượt. Lấy ảnh/quay từ lần chạy thật nếu cần bằng chứng.

## Dữ liệu dùng xuyên suốt

| Mục | Nội dung nhập |
|---|---|
| Hobby của A | `Guitar Demo 01` |
| Mô tả | `Luyện chuyển hợp âm C–G–Am–F mỗi ngày.` |
| Icon / màu / priority | Icon Music, màu Mint, Interested |
| Buổi luyện tập | `Luyện chuyển hợp âm` |
| Ngày / giờ / thời lượng kế hoạch | Hôm nay, chọn giờ phù hợp buổi demo, 15 phút |
| Ghi chú Hyper | `Đã luyện C–G–Am–F; cần chuyển hợp âm G nhanh hơn.` |
| Tin nhắn A → B | `Chào bạn, tối mai mình cùng luyện guitar nhé?` |
| Tin nhắn B → A | `Được nhé, hẹn bạn lúc 19:00!` |
| Tin nhắn nhóm | `Mình vừa hoàn thành một buổi luyện guitar.` |

Thời lượng kế hoạch 15 phút khác với thời gian Hyper thực chạy; không cần chờ đủ 15 phút để Finish.

## Flow 1 — Tự tạo và quản lý hobby, khoảng 2 phút

Đường đi: Login → My Hobbies → + Create → Create Hobby → Hobby Detail.

| Bước | Thao tác của A | Kết quả cần quan sát |
|---|---|---|
| 1 | Đăng nhập bằng phương thức đã kiểm tra, vào My Hobbies, bấm `+ Create`. | Form tạo hobby mở. |
| 2 | Để trống tên/priority và bấm `Create Hobby`. | Hiện validation, form vẫn mở. |
| 3 | Nhập tên/mô tả trong bảng, chọn icon Music và màu Mint; chưa chọn priority, bấm lưu. | Báo thiếu priority, giữ nội dung đã nhập. |
| 4 | Chọn `Interested`, bấm `Create Hobby`. | Form đóng; collection có đúng tên, icon, màu, priority đã chọn. |
| 5 | Thử tạo tiếp hobby cùng tên `Guitar Demo 01`, chọn priority rồi lưu. | Báo trùng tên; hobby cũ không bị ghi đè. Bấm `Cancel` để đóng form. |
| 6 | Mở Hobby Detail. | Hiện đúng mô tả và priority; có Edit, Hyper Mode và Schedule. |

Lời nói gợi ý: “Người dùng tự tạo sở thích và chọn mức độ quan tâm. Hệ thống kiểm tra tên trống, thiếu priority và tên trùng, đồng thời giữ thông tin để người dùng sửa.”

Điểm chốt: hobby vẫn để Interested khi chuyển sang flow 2, để chứng minh Interested vẫn được lên lịch và luyện tập.

## Flow 2 — Lập kế hoạch, luyện tập và xem lịch sử, khoảng 2–3 phút

Đường đi: Home → + Schedule → Start → Hyper Mode → Finish → Activity history.

| Bước | Thao tác của A | Kết quả cần quan sát |
|---|---|---|
| 1 | Vào Home, chọn hôm nay, bấm `+ Schedule`; chọn `Guitar Demo 01`, nhập tên buổi luyện, chọn ngày/giờ và 15 phút, bấm lưu. | Lịch xuất hiện đúng ngày, tên và giờ dù hobby đang Interested. |
| 2 | Vào My Hobbies, đổi priority của hobby sang `Active`, quay lại Home. | Lịch vừa tạo vẫn còn. |
| 3 | Bấm `Start` ngay trên lịch vừa tạo. | Hyper Mode gắn đúng hobby và buổi luyện tập. |
| 4 | Nếu timer chưa chạy, bấm `Start / Resume`; để chạy khoảng 10 giây, bấm `Pause`, đợi 5 giây. | Timer đứng yên khi pause. Nếu bật Auto-start, timer có thể đã chạy khi mở màn hình. |
| 5 | Bấm `Start / Resume`, nhập ghi chú trong bảng; tiếp tục cho tổng thời gian chạy đạt khoảng 65 giây. | Ghi chú giữ nguyên, thời gian chỉ tăng khi đang chạy. |
| 6 | Bấm `Finish & save activity`, đợi lưu xong; bấm `View activity history`. | Home history có một bản ghi mới, đúng hobby, thời lượng thực và ghi chú; lịch liên kết thể hiện hoàn thành. |
| 7 | Đóng rồi mở lại app, vào Home. | Bản ghi vẫn còn và không bị tạo thêm chỉ vì mở lại app. |

Lời nói gợi ý: “Interested và Active đều có thể lên lịch. Đổi priority không làm mất lịch. Hyper Mode tính thời gian luyện thực tế, loại trừ thời gian tạm dừng và lưu ghi chú vào lịch sử khi hoàn thành.”

Không bấm Reset trong phiên dùng để chứng minh thời lượng; có thể trình bày Reset trong một phiên phụ nếu còn thời gian. Khi kiểm tra history, đối chiếu số bản ghi trước/sau để phân biệt các phiên diễn tập cũ.

## Flow 3 — Kết nối cộng đồng và tham gia hoạt động, khoảng 3 phút

Đường đi chính: Community → Groups / People → Join / Chat → Conversation → Send.

| Bước | Thao tác | Kết quả cần quan sát |
|---|---|---|
| 1 | A vào Community → Groups, tìm `Guitar Lab3 Demo` do B chuẩn bị, bấm `Join group`. | Tham gia thành công và mở chat nhóm; các lần sau có `Open group chat`. |
| 2 | A gửi tin nhắn nhóm trong bảng; B mở cùng nhóm. | B đọc được đúng tin A vừa gửi. |
| 3 | A vào Community → People, tìm `Ban Demo B`, bấm `Chat`, gửi lời mời luyện guitar. | Conversation hiển thị tin đã gửi. |
| 4 | B mở Community → Chats, chọn cuộc trò chuyện với A và gửi lời đáp. | A nhận được lời đáp của B; nếu hai máy cùng mở, quan sát cập nhật trên màn hình. |
| 5 | A mở Community → Activities, chọn `Guitar Meetup Demo`, bấm `RSVP`. | Trạng thái đã tham gia, có nút `Add to Home`. |
| 6 | A về Home, chọn đúng ngày mai. | Chưa có lịch mang tên hoạt động chỉ do bấm RSVP. |
| 7 | A quay lại Activities, bấm `Add to Home`, chọn `Guitar Demo 01`; về Home và chọn ngày mai. | Có lịch hoạt động đúng ngày/giờ đã chọn, gắn hobby của A. |

Lời nói gợi ý: “Hai tài khoản có thể tham gia nhóm và trao đổi tin thật. RSVP chỉ xác nhận tham gia hoạt động; lịch cá nhân chỉ được thêm khi người dùng chủ động chọn Add to Home.”

Nếu People trống hoặc hiện `Private` / `Enable chat`, kiểm tra lại hai tùy chọn privacy của cả A và B. Nếu Community hiển thị tạm nghỉ, kiểm tra cấu hình `community_enabled` với người phụ trách trước buổi demo. Nếu chỉ có một máy, A gửi → Settings/Sign Out và xác nhận → đăng nhập B → mở Chats và trả lời; ghi rõ đây là demo luân phiên tài khoản.

## Nhịp trình bày và ảnh nên giữ

| Mốc dự kiến | Nội dung | Ảnh / bằng chứng từ lần chạy thật |
|---|---|---|
| 0:00–0:30 | Giới thiệu: tạo sở thích, luyện đều, kết nối bạn bè. | Màn hình mở đầu, phương thức đăng nhập thực tế. |
| 0:30–2:30 | Flow 1. | Validation và hobby đã tạo. |
| 2:30–5:00 | Flow 2. | Lịch, timer pause và history có ghi chú. |
| 5:00–8:00 | Flow 3. | Tin nhắn trên A/B; Home trước và sau Add to Home cùng ngày. |
| 8:00–8:30 | Nêu kết quả quan sát và phần chưa kiểm chứng. | Liên kết evidence thực tế nếu đã lưu. |

Checklist tự đánh dấu sau khi diễn tập:

- [ ] Đăng nhập thật; ghi lại Google hay email/password đã dùng.
- [ ] Flow 1: validation, tạo hobby và chặn trùng tên hoạt động đúng.
- [ ] Flow 2: Interested lên lịch được; đổi priority giữ lịch; pause đúng; Finish tạo một history record có notes và dữ liệu còn sau mở lại app.
- [ ] Flow 3: tài khoản B thực sự đọc và trả lời; RSVP chưa thêm lịch; Add to Home mới thêm lịch.
- [ ] Ghi lại lỗi/blocker còn gặp; không đánh dấu đạt chỉ từ source hoặc unit/widget tests.

Nguồn đối chiếu: `requirements/reference/Specification.html` mục 04 (3 task flows) và interaction invariants; `full-manual-checklist.md`; source các màn hình Hobbies/Practice/Community/Settings. Kịch bản toàn bộ Lab 3: [demo-recording-script.md](demo-recording-script.md).
