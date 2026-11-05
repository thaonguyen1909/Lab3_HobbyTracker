# Kiểm chứng nguồn tham chiếu — Phase 00 (03/11/2026)

**Kết luận:** `docs/requirements/reference/source-manifest.json` chứa 7 giá trị SHA-256/kích thước kỳ vọng được ghi từ đợt chuẩn bị 02/11. Kiểm tra lại trên ZIP người dùng gửi cho thấy **4/7 khớp, 3/7 HTML không khớp**. Không thể suy ra nguyên nhân (bản gốc thay đổi, thao tác copy, normalization, manifest sai, v.v.) nếu không có byte từ đường dẫn Windows nguồn. **Không được coi 7 file này là “exact original copies”** cho đến khi người quản lý nguồn xác nhận.

- 7 file nguồn Lab 2/Lab 3 cũ: giữ nguyên byte trong `docs/requirements/reference/`; hash kỳ vọng ở `source-manifest.json` được **giữ nguyên** để có cơ sở đối chiếu.
- SHA-256/bytes thực có trong gói: `docs/requirements/reference/archive-manifest.json` (bao gồm cả PDF Final bổ sung từ tệp người dùng gửi).
- Kết quả từng file (expected/actual + MATCH/MISMATCH): `docs/evidence/00/source-integrity.json`.
- Lời khai kiểm chứng cũ ngày 02/11: `docs/evidence/00/document-validation-original-2026-11-02.json`; kết quả **mới**: `docs/evidence/00/document-validation.json`.
- Có thể chạy lại: `python scripts/verify_phase00.py` từ thư mục dự án. Python 3 standard library, không cần Firebase/Flutter. **Exit code 1 là kết quả kiểm tra nguồn chưa đạt** (3 HTML mismatch đã biết), không phải script bị lỗi; exit 2 báo sai lệch cấu trúc tài liệu.

## Hành động cần người có bản nguồn gốc

1. Mở 3 HTML gốc tại đường dẫn có trong `docs/requirements/reference/source-manifest.json`: `Specification.html`, `Prototype.html`, `DesignArchive.html`.
2. So hash/byte với **cả** manifest kỳ vọng và bản trong ZIP. Nếu bản ZIP sai, cung cấp đúng file gốc để thay và chạy lại script; không chỉnh nội dung HTML để ép hash.
3. Nếu nội dung mới được thay đổi có chủ đích, ghi người phê duyệt, ngày, lý do và lưu bản lịch sử; sau đó cập nhật manifest với hash được xác nhận kèm log thay đổi.
4. Đánh dấu D05/G12 RESOLVED chỉ khi kiểm chứng thực tế PASS hoặc đã có quyết định provenance minh bạch; không âm thầm chép giá trị actual vào expected rồi công bố PASS.

## PDF Final bổ sung

`PRM393 - Final Assignment One Complete System on Firebase.pdf` được **sao chép từ file đính kèm trong cuộc trò chuyện**, để đủ 8 tài liệu khi sau này lập kế hoạch Final; không là bằng chứng triển khai Final hoặc một trong 7 source gốc có đường dẫn Windows. Phạm vi thực thi hiện tại **chỉ Lab 3**.

## Slide deck tham chiếu

Bản slide `HobbyTracker_Design_Journey_12_Slides.pptx` (slide 1) đã kiểm tra trực tiếp văn bản slide và thấy mã **PRM323**, khác mã PRM393 trên đề môn. Vì đây là nguồn tham chiếu, **không sửa trực tiếp** (để bảo toàn nguyên bản/hash); nếu tái sử dụng cho bài nộp, chỉnh trên **bản sao** và xem lại tên môn với giảng viên.
