# Phân nhóm source và tài liệu — 03/11/2026

PHASE: 08 | Repository organization / GitHub preparation
STATUS: PARTIAL cho nghiệm thu Lab3 tổng thể; công việc sắp xếp thư mục đã hoàn tất và qua kiểm tra.

## Kết quả

- Source Flutter/Android/assets/Firebase và tests giữ nguyên vị trí ở root. Không tạo monorepo mobile/web/packages/core và không thay logic ứng dụng.
- Toàn bộ yêu cầu, prompts, thiết kế, handoff, evidence và hồ sơ nộp được gom vào docs/; xem docs/README.md.
- docs/requirements/reference/ giữ nguyên nội dung HTML/PPTX/PDF gốc. docs/requirements/AGENTS-original.md là bản lưu chỉ để truy vết; AGENTS.md ở root vẫn là hướng dẫn có hiệu lực, chỉ cập nhật đường dẫn.
- README.md ở root được viết gọn cho người clone repository: cấu trúc, chạy app, test, Firebase setup và upload GitHub. README cũ và changelog/manifest đã chuyển vào docs/history/.
- Các đường dẫn đang dùng trong hướng dẫn và scripts được cập nhật. Original reference files, planning archives, raw evidence và historical JSON manifests được giữ nguyên bytes. Bản đồ di chuyển: docs/history/reorganization-manifest.json.
- Bổ sung quy tắc ignore APK/AAB; bỏ ignore Gradle wrapper khỏi android/.gitignore để scripts/JAR/properties cần build được đưa vào Git.
- Root chỉ còn README.md và AGENTS.md là Markdown; các file app/config nằm ở vị trí chuẩn. Build/cache cục bộ có thể xuất hiện khi chạy Flutter nhưng được Git bỏ qua.

## Vị trí mới

| Trước | Sau |
|---|---|
| reference/ | docs/requirements/reference/ |
| prompts/ | docs/requirements/prompts/ |
| planning/ | docs/requirements/planning/ |
| design/ | docs/design/ |
| handoff/ | docs/design/handoff/ |
| evidence/ | docs/evidence/ |
| report/ | docs/submission/reports/ |
| slides/ | docs/submission/slides/ |
| 00_START_HERE.md, PHASE00/01/02_CHANGELOG.md, WORK_PACKAGE_SHA256.json | docs/history/ |
| firestore-debug.log, empty artifacts/ | docs/evidence/root-debuglogs/, docs/evidence/local-artifacts/ |

## Kiểm tra thực

- PASS: 239 tệp trong manifest đều có ở vị trí mới; 221 tệp reference/evidence/planning/binary-JSON được kiểm tra giữ nguyên SHA256.
- PASS: 433 file code/assets/test/Firebase được kiểm tra không đổi hash; không thay app logic.
- PASS: 96 Flutter tests; flutter analyze sạch; dart format check đạt; APK debug build thành công sau sắp xếp.
- PASS: Python audit scripts parse được và 6 đường dẫn đọc reference/design đã di chuyển đều tồn tại. Không chạy lại các audit phase cũ để ghi đè evidence lịch sử hoặc khẳng định các gate cũ đã PASS.
- PASS: Git ignore audit dùng Git metadata tạm ngoài workspace; source, pubspec.lock và 4 file Gradle wrapper không bị ignore. google-services.json, local.properties, .env, signing keystore, APK và node_modules bị ignore. Không tạo .git trong workspace.
- PASS: Các Markdown links đang dùng trong README/AGENTS/docs/e2e README tồn tại; archive gốc và raw evidence được loại khỏi rewrite/link-check để giữ tính truy vết.

Evidence mới: docs/evidence/08/reorganization/{integrity.json,script-paths.json,gitignore-check.json,format.log,analyze.log,tests.log,android-build.log,final-check.json}.

## GitHub

Có thể đưa toàn bộ source và docs/ vào cùng repo để không lẫn yêu cầu với code. Nếu chỉ upload code, các thư mục lib/, android/, assets/, firebase/, test/, e2e_test/, scripts/ và file cấu hình là phần ứng dụng; docs/ là phần tài liệu tách biệt. Flutter không cần docs/ để build; một số audit scripts cần docs/ nếu muốn chạy chúng.

Git add áp dụng .gitignore; upload thủ công qua web không tự bảo vệ bằng các ignore rules đó. Giữ cấu hình Firebase riêng, .env và keystore ngoài nội dung công khai. Chưa upload/push/commit/deploy; quyền chia sẻ và các gate Lab3 còn mở do owner quyết định.

DESIGN TRACEABILITY: Không đổi UI/flow; docs/design-traceability.md ghi nhận thay đổi vị trí tài liệu.
SECURITY & DATA CHECK: Không đọc/in secret; cấu hình local giữ nguyên, không đổi Rules hoặc dữ liệu cloud.
OPEN DECISIONS / RISKS: Broader two-account/cloud/ARTEMIS/Figma acceptance unchanged; historical manifests/logs retain their original recorded paths, mapped by the organization manifest.
COMMIT/PR/DEPLOY: NOT CREATED.
READY FOR HUMAN REVIEW: YES.
NEXT PHASE: NOT STARTED.
