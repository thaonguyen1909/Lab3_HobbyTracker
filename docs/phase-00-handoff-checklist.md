# Checklist nghiệm thu Phase 00 — người phụ trách xác nhận

**Trạng thái ngày 03/11/2026:** `PARTIAL / REVIEW READY`. Đã xử lý sai lệch trong tài liệu và đóng gói nguồn Final PDF, **chưa nghiệm thu** vì một số cổng chỉ có thể xác minh ngoài ZIP. Dấu `[ ]` chưa hoàn thành, không phải test fail đã chạy.

## 1. Có thể kiểm bằng ZIP mới

- [x] Có 15 route theo Specification (`S01–S15`) và 15 handoff entries theo kế hoạch (chưa là mã Dart).
- [x] Có 3 flows (`F01–F03`), 10 component families (`C01–C10`), 7 theme và 23 test plan (`TC01–TC23`, toàn bộ `NOT RUN`).
- [x] Có rubric Lab 3 và kế hoạch Firebase/ARTEMIS/code review, không tự gắn nhãn đạt runtime.
- [x] Đã chạy lại kiểm chứng nguồn và ghi **3 lỗi SHA-256 còn mở**, sửa kết quả `PASS` gây hiểu nhầm.
- [x] Đã bổ sung bản PDF Final được gửi riêng vào `docs/requirements/reference/`; không khởi chạy phases 09–13.
- [x] Có script `scripts/verify_phase00.py` để chạy kiểm tra tĩnh, sinh evidence và kiểm liên kết tài liệu.

## 2. Bắt buộc xác minh thủ công để PASS Phase 00

- [ ] **D05/G12 — Nguồn HTML:** người quản lý có bản gốc so ba file HTML với dữ liệu trên máy/nguồn lịch sử; phục hồi hoặc duyệt provenance bằng tài liệu có chữ ký/quyết định. Xem `docs/source-provenance.md`.
- [ ] **D01 — Figma truy cập:** cấp quyền Editor cho tài khoản Figma tích hợp, hoặc cung cấp bản export + ảnh/screens/video minh chứng phù hợp. Lần thử 03/11 bị báo không có edit access. Không tuyên bố đã kiểm Figma mới.
- [ ] **D01 — Prototype:** nối/kiểm thử 3 flow đầu-cuối với alternatives và error/recovery; xuất screenshot các interaction links và flow starting points. Snapshot cũ có `reactionNodeCount=0` và `flowStartingPoints=[]` cả 6 trang.
- [ ] **D01 — Lab 2 approval:** lưu xác nhận của giảng viên về 6 pages (01–06), prototype và DESIGN.md/handoff hoặc phương án HTML được chấp thuận.
- [ ] **Design review:** đối chiếu từng màn Figma Final UI với `S01–S15`, review `DX01–DX08`, components `C01–C10`, 4 tabs, 7 themes; không đồng nhất 15 routes với 23 Figma components.
- [ ] **D07, D08, D09:** chốt priority initial state, cách trình bày loading/empty/error/retry, và Firebase demo area trong Settings/Profile **trước khi triển khai UI có liên quan**; cập nhật Figma + `docs/design-traceability.md` nếu thay đổi so với Lab 2.
- [ ] **Người phụ trách** ghi người duyệt, ngày, quyết định, nguồn/bằng chứng cho mỗi mục; chuyển trạng thái review Phase00 sang PASS chỉ khi tất cả cổng Phase00 có căn cứ.

## 3. Có thể chốt ở các phase sau, không chặn tài liệu Phase00 nếu ghi rõ

- **D02:** Cloud Storage eligibility/billing/ngoại lệ từ giảng viên trước 07A; **không** tự bật trả phí, local PDF không miễn upload Lab 3.
- **D04/D12:** StudentID/tên repo và quyền truy cập bản nộp trước 08.
- **D10/D11:** chính sách quyền riêng tư/thông báo trước 05/06, chính sách timer khi background trước 04.
- **Runtime tests:** chỉ sau khi có Flutter/Firebase; hiện Flutter/ARTEMIS/Rules/Console/DebugView = `NOT RUN`.
- **Slide tham chiếu:** xác nhận/sửa mã PRM323 → PRM393 **trên bản sao khi làm slide nộp**, không sửa tài liệu nguồn.

## 4. Gate để bắt đầu Phase 01

Giảng viên/người phụ trách chấp nhận baseline Figma/HTML và thiết kế 3 flows; provenance HTML minh bạch; reviewer duyệt docs/design/handoff/traceability và ghi nhận các trạng thái OPEN sẽ giải quyết theo phase. Phase 01 chỉ bắt đầu khi được giao riêng. Không có nghĩa toàn bộ D02/D04/D10/D11 phải hoàn tất ngay.
