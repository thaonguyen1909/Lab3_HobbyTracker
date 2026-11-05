# Nguồn thiết kế và yêu cầu

7 file tham chiếu Lab 2/Lab 3 được đóng gói từ đợt chuẩn bị trước. `source-manifest.json` ghi **hash/kích thước kỳ vọng theo hồ sơ cũ**; kiểm tra lại ngày 03/11/2026 thấy **4/7 khớp, 3/7 HTML không khớp**. Không đủ căn cứ để khẳng định 7 bản sao nguyên byte so với đường dẫn gốc. Xem `../evidence/00/source-integrity.json` (kết quả), `archive-manifest.json` (hash byte hiện có) và `../docs/source-provenance.md` (cách xử lý). **Giữ nguyên byte tất cả nguồn đã có**.

- Specification.html: quy tắc màn hình/flow/token và giới hạn prototype.
- Prototype.html: HTML chạy offline; authentication/chat/data là mô phỏng.
- DesignArchive.html: thư viện thị giác; before/after có phần tái dựng, không phải ảnh lịch sử gốc.
- Hai PPTX: rationale thiết kế; nghiên cứu 9 người là mô phỏng bằng AI.
- PDF Lab 3 (18 trang): yêu cầu/rubric chính; tên file có Patrol nhưng nội dung yêu cầu ARTEMIS.
- Preparation Guide (25 trang): checklist tích hợp và evidence.

Figma trực tiếp: https://www.figma.com/design/5JiJtLyXN6DEpC1LycQPBb/Untitled?node-id=0-1
Đã đọc 6 trang bằng Figma MCP ngày 02/11/2026; xem evidence/00 và docs/figma-html-comparison.md. Không có bản .fig offline hoặc lịch sử phê duyệt giảng viên trong bộ nguồn.

Nguồn yêu cầu Lab 3 được ưu tiên cho tiêu chí nộp; thiết kế Figma và HTML phải đối chiếu, không tự chọn bên thắng khi có khác biệt. Các đề xuất ở docs/design và handoff chưa thay đổi nguồn gốc.

- **Bổ sung từ tệp người dùng gửi ngày 03/11/2026:** `PRM393 - Final Assignment One Complete System on Firebase.pdf` — dùng riêng để đối chiếu kế hoạch **Final**, không thay yêu cầu Lab 3. Đây là nguồn thứ tám ở `reference/`; `source-manifest.json` vẫn ghi riêng 7 tệp nguồn trước đó.
