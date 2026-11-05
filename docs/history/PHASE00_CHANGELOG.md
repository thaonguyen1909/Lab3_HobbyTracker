# Phase 00 — thay đổi trong bản ZIP rà soát 03/11/2026

**Kết quả:** `PARTIAL / REVIEW READY` (**không** đánh dấu đã hoàn thành Phase 00). Thực hiện yêu cầu rà soát, chỉnh sửa lỗi tài liệu có thể sửa, chuẩn bị minh chứng và checklist; **không** triển khai Flutter, sửa Figma hay tự xác nhận giảng viên.

## Những chỉnh sửa thực hiện được

1. **Sửa kết luận bằng chứng sai:** `evidence/00/document-validation.json` không còn ghi 7 source `PASS` mặc dù 3 HTML lệch SHA-256. Bản cũ lưu riêng để truy vết; có bảng expected/actual (`evidence/00/source-integrity.json`).
2. **Bảo tồn nguồn:** giữ nguyên byte 7 tệp HTML/PPTX/PDF so với ZIP bạn gửi; thêm `evidence/00/zip-baseline.json` làm baseline kiểm chứng và `reference/archive-manifest.json` ghi hash thực tế. Không viết đè hash kỳ vọng tại `reference/source-manifest.json`.
3. **Sửa các thông tin mâu thuẫn:** `docs/gap-review.md`, `docs/phase-00-review.md`, `docs/open-decisions.md` (mở lại D05), `docs/implementation-roadmap.md`, `docs/figma-html-comparison.md`, `reference/README.md` và `README.md` được cập nhật status và mức bằng chứng.
4. **Bổ sung bản PDF Final:** đã sao chép nguyên byte file Final Assignment mà người dùng gửi vào `reference/`; đủ 8 PDF/HTML/PPTX tham chiếu cho các prompt Final **sau này**. Không bắt đầu các phase Final.
5. **Có checklist nghiệm thu thủ công** `docs/phase-00-handoff-checklist.md`, giải thích sự khác biệt và nguồn gốc tại `docs/source-provenance.md`.
6. **Thêm script kiểm tra tĩnh** `scripts/verify_phase00.py`, tạo lại source-integrity, archive-manifest và document-validation.
7. **Kiểm tra slide:** slide 1 của tài liệu 12 slide ghi PRM323; đây là nguồn tham khảo nên không sửa trực tiếp, cần đổi trên bản slide nộp riêng khi phù hợp.

## Những điều không thể sửa/không được tự giả định

- 3 HTML cần người giữ bản gốc đối chiếu để chốt vì sao lệch expected hash; chỉ có bản trong ZIP, không có original Windows path.
- Figma read-only cập nhật ngày 03/11 bị báo thiếu Editor access; chưa thể kiểm 3 flow Figma/recovery và approval hiện thời; snapshot JSON từ 02/11 chỉ là lịch sử.
- Cần nhóm/giảng viên review handoff, 3 flow tương tác, mô tả thay đổi Figma, kiểm tra chính thức Lab 2.
- App Flutter/Firebase/ARTEMIS chưa có; không có build, test E2E hay console evidence để đánh giá.

## Tái chạy

```bash
cd Lab3_HobbyTracker-main
python scripts/verify_phase00.py
```

Script chỉ dùng Python chuẩn. **Exit 1 là kết quả integrity FAIL đã biết (4/7 MATCH), không phải kết luận script chạy lỗi**. Exit 2 chỉ khi có lỗi kiểm tra cấu trúc/links. Đọc JSON do script sinh ra; không tự coi kết quả đếm dòng là phần mềm đã chạy.

## Trạng thái kiểm chứng lại

- 7 file tham chiếu gốc: **7/7 giữ nguyên byte so với ZIP đầu vào**.
- Source manifest kỳ vọng: **4/7 MATCH, 3/7 MISMATCH**.
- Mapping: **15 screen + 15 handoff**, **3 flows**, **10 component families**, **7 themes**.
- Test plan: **23 case**, tất cả **NOT RUN**; rubric: **20 rows (trọng số 10 điểm)**.
- Markdown local links: **0 broken** ở lần audit mới.
- Figma hiện tại: **BLOCKED / NOT REVERIFIED**.
- Phase 00: **PARTIAL**; Phase 01–08: **NOT STARTED**.

Không có `.git` trong ZIP nên không tạo hoặc bịa commit, PR hoặc lịch sử review. Không thêm bằng chứng giả.
