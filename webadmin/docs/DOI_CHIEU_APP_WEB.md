# Đối chiếu app và web admin — 06/11/2026

## Kết luận

Web có nhiều màn hình nhưng chưa đồng bộ chức năng đầy đủ với app hiện tại. Cùng project Firebase không có nghĩa mọi chức năng đã tích hợp. Nên giữ chức năng quản trị dữ liệu chung, bổ sung quản trị Khoảnh khắc/quyền, và tạm ẩn các module không có luồng tiêu thụ trên app thay vì xóa dữ liệu.

Audit source của app tại ../Lab3_HobbyTracker-main và webadmin, cùng kiểm tra số lượng dữ liệu cloud bằng credential backend. Không deploy, không ghi dữ liệu thử hoặc xem tin nhắn/ghi chú riêng tư.

## Ma trận chức năng

| Chức năng | App hiện tại | Web hiện tại | Đánh giá và đề xuất |
|---|---|---|---|
| Đăng nhập/tài khoản | Firebase Auth + hồ sơ users, profiles công khai | Auth users, khóa/mở, reset theo provider, hạn chế, nhân sự riêng | Giữ. Cần đồng bộ tên hồ sơ trong users với tên Auth; Auth.displayName có thể khác tên tự đặt trong app. Không dùng users.role để cấp admin |
| Sở thích | users/uid/hobbies, HobbyNames chống trùng | Đọc hobbies toàn người dùng, chi tiết/CSV | Phù hợp. Admin không cần tạo sở thích thay người dùng. Giữ ghi chú riêng tư bị che |
| Lịch/Hyper Mode/lịch sử | plans, history; timer trên thiết bị | Đọc và thống kê | Phù hợp cho quản trị. Không cần điều khiển timer từ web. Còn giới hạn tổng hợp 1.000 bản ghi |
| Bài viết/bình luận | posts và comments/likes | Tạo, ẩn/khôi phục, ghim, bình luận | Ẩn/khôi phục dùng bản gốc. Ghim mới lưu adminPostFlags; app chưa đọc cờ để ưu tiên feed. Nên tích hợp ghim hoặc tạm ẩn nút |
| Nhóm | groups/members/groupLinks, groupChats | CRUD nhóm/chuyển chủ/khóa/thành viên | Giữ. Cần cập nhật tên groupLinks khi sửa tên nhóm và hợp nhất rules khóa nhóm. Không tự thêm phê duyệt/duyệt nhóm nếu app không có flow |
| Khoảnh khắc 3 giờ | groups/gid/moments, momentUploads, outbox/inbox, Cloudinary + Node Render, hết hạn/retract | Chưa có module tương ứng | Thiếu quan trọng: cần quản trị metadata, báo cáo ảnh, ẩn/thu hồi có audit và gọi backend cleanup để không để lại ảnh Cloudinary mồ côi. Không đưa secret Cloudinary xuống frontend |
| Sự kiện/RSVP | events; users/uid/rsvps; Add to Home riêng | Nháp/xuất bản/hủy/RSVP | Giữ. App tự tạo event không có status, được web hiểu là published sau sửa lượt này. Fields location/endsAt/capacity/description web có nhưng app chưa dùng hết; capacity chưa enforce. RSVP count cần tính từ subcollection, không giả 0 khi chưa tính |
| Người dùng công khai | profiles.visible/allowMessages | Chưa có quản trị profile chuyên biệt | Bổ sung xem metadata hồ sơ công khai và liên kết account; không tự bỏ qua quyền riêng tư hoặc thay tùy chọn cá nhân |
| Hội thoại | directChats và groupChats/gid/messages | Chỉ directChats metadata | Thiếu metadata hội thoại nhóm; groupChats có thể chỉ có subcollection messages và không có parent document, không thể đếm collection cha để kết luận không có hội thoại. Không cần trang đọc toàn bộ tin nhắn riêng |
| Báo cáo vi phạm | Chưa có UI/caller mobileApi/reports | adminReports, phân công/xử lý/bằng chứng có audit | Có backend nhưng thiếu đầu vào app. Ưu tiên thêm nút báo cáo bài/bình luận/ảnh/tin nhắn; hiện whitelist chưa hỗ trợ Khoảnh khắc |
| Hỗ trợ | Chưa có UI/caller ticket | supportTickets và phản hồi | Có backend nhưng app chưa gửi/nhận ticket. Hoặc bổ sung form + inbox hỗ trợ app, hoặc tạm ẩn module. Không coi số ticket 0 là lỗi mất dữ liệu |
| Nội dung CMS | Không đọc appContent | Banner/FAQ/guide/terms/privacy/onboarding CRUD | Chưa tác động app. Nên tạm ẩn; chỉ giữ nếu có kế hoạch thêm màn hiển thị tương ứng |
| Cấu hình ứng dụng | Firebase Remote Config (community_enabled/feed_limit) | Ghi appConfig/current | Hai nguồn chưa nối nhau. Bridge còn nằm riêng và không khớp baseline. Chọn một nguồn chung, merge bridge theo source hiện tại và test mobile; không quảng bá bảo trì/min version đã có tác dụng |
| Thông báo | devices/preferences, thông báo cục bộ; Khoảnh khắc có inbox/cài đặt riêng | Campaign FCM và scheduler riêng | Gửi FCM đã có code nhưng live-local adapter cố ý không gửi; scheduler chưa được chứng minh deploy. Phải phân biệt nhắc giờ local, campaign, moment push. Cần delivered/opt-in test, không thêm giao diện giả gửi thành công |
| Tệp/PDF | Export và upload reports/uid/*.pdf | Metadata/tải link ký Storage | Cùng path nhưng live-local chưa có ADMIN_STORAGE_BUCKET. Cloudinary ảnh Khoảnh khắc không thuộc danh sách PDF này. Giữ có điều kiện; chưa cần xóa file hàng loạt |
| Vận hành | Moment cleanup/outbox chạy backend Render | Đọc adminJobs, nhãn dịch vụ | Không nối moment worker hoặc Crashlytics thật, retry chưa triển khai. Tạm ẩn trang job trống hoặc thay bằng health thực của các backend; không coi nhãn dịch vụ là health check |
| Vai trò/audit | Người dùng app không quản lý nhân sự | adminStaff/claims/adminAudit | Cần giữ dù không có màn tương ứng trên app: đây là chức năng quản trị hợp lệ |
| Theme/ngôn ngữ/Spotify | Preferences cá nhân và Spotify PKCE/App Remote | Theme không gian admin | Không cần thêm OAuth Spotify hoặc điều khiển nhạc vào admin; không ép theme cá nhân theo theme của admin |

## Khoảng trống bảo mật/dữ liệu cần ưu tiên

1. Rules web integration/firebase/firestore.rules thiếu các match momentUploads, momentGroupSettings, momentInbox, groups/gid/moments hiện có ở app/firebase/firestore.rules. Deploy đè nguyên bản web có thể chặn Khoảnh khắc. App rules hiện lại không có adminRestrictions/adminGroupFlags/appConfig. Chưa kiểm tra rules đã deploy trên cloud trong audit này; không khẳng định hạn chế/khóa nhóm đã enforce trên thiết bị.
2. MomentService backend hiện kiểm tra auth/membership, chưa thấy đọc adminRestrictions/adminGroupFlags; phải áp dụng chính sách khóa/hạn chế tại cả backend riêng, không chỉ Firestore SDK rules.
3. Sửa tên Auth không tự sửa users/displayName, profiles/displayName hoặc tên snapshot trong posts. Cần xác định nguồn tên chính thức; không đổi dữ liệu hàng loạt không có migration.
4. Group memberCount/event rsvpCount/likesCount/commentsCount không phải field bảo đảm do app duy trì; cần query count/aggregate, không suy rằng thiếu field = không có dữ liệu.
5. Chuyển chủ nhóm cần xử lý groupLinks/role-owner đúng nghiệp vụ; kiểm thử hai tài khoản sau thay đổi. Không tự xóa thành viên chủ cũ nếu chưa có quy tắc sản phẩm.

## Kiểm tra dữ liệu thật (chỉ đếm)

| Nguồn | Số lượng lúc audit |
|---|---:|
| posts | 4 |
| groups | 2 |
| events | 1 |
| profiles | 4 |
| directChats | 2 |
| hobbies (collection group) | 7 |
| plans (collection group) | 36 |
| history (collection group) | 2 |
| moments (collection group) | 6 |
| adminReports/supportTickets/appContent/adminCampaigns/adminJobs | Mỗi nguồn 0 |

Các số là snapshot tại thời điểm đọc; không phải bằng chứng tất cả flow đồng bộ. 6 moment documents không có nghĩa 6 ảnh còn hiển thị: còn expiry/status/cleanup. groupChats parent collection đếm 0 không loại trừ messages dưới các document cha không tồn tại.

## Nên giữ / ẩn / bổ sung

- Giữ: đăng nhập, người dùng/hồ sơ công khai, thống kê luyện tập, bài/bình luận, nhóm, sự kiện/RSVP, metadata hội thoại, vai trò, audit, cài đặt admin.
- Ưu tiên bổ sung: rules hợp nhất bảo toàn Khoảnh khắc; enforce hạn chế ở Node backend; quản trị Khoảnh khắc; tên/counts chung; báo cáo nội dung từ app; metadata group chat.
- Tạm ẩn hoặc hoàn thiện trước khi dùng: CMS, ticket hỗ trợ, cấu hình appConfig, adminJobs, gửi/đặt lịch campaign chưa deploy. Đề xuất, chưa xóa hoặc ẩn tự động vì yêu cầu lượt này là kiểm tra/đối chiếu.
- Không cần thêm vào admin: timer/Spotify cá nhân, sửa lịch và sở thích riêng tùy tiện, xem mọi tin nhắn, thay theme/ngôn ngữ của thành viên.
- Chỉ xóa source/module sau quyết định phạm vi; không xóa collections hoặc user data để làm sạch menu.

## Việc đã sửa cùng lượt kiểm tra trạng thái

Nút trên bảng, chi tiết, bulk và gateway preview dùng availableActions theo quyền + trạng thái. API kiểm tra lại các chuyển trạng thái chính và trả 409 nếu đã đổi. Flags khóa/hạn chế/ghim được trả rõ; trạng thái event cũ không có status được suy ra từ collection. Restore event/content về draft, không tự xuất bản lại. Không đổi trạng thái qua Edit để né nút chuyển trạng thái. Campaign sent/sending/failed/partial không hiện gửi lại; admin tự sửa quyền và Super Admin cuối được bảo vệ.

43 tests, TypeScript và build đạt. Chưa nghiệm thu toàn bộ lifecycle hai tài khoản cloud hoặc deploy rules/Functions. Audit không sửa source Flutter.
