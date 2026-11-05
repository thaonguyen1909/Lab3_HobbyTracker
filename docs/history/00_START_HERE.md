> Cập nhật giao diện Figma 03/11/2026: đọc `docs/figma-ui-report.md` trước. Quyền Figma đã được giải quyết; các ghi chú cũ nói Figma BLOCKED là lịch sử. Các gate Android/Firebase/ARTEMIS vẫn chưa được thay bằng PASS.

# Start here — Hobby Tracker all-phase integration

User scope: complete all Lab3 phases 00–08 in a single pass, without per-phase permission pauses. Source now spans that scope. **Overall PARTIAL, not 100% accepted.**

1. Open this folder containing pubspec.yaml.
2. Read README.md and docs/full-implementation-report.md (supersede historical notes).
3. Run the single combined checklist at docs/full-manual-checklist.md.
4. Local evidence: 63 Flutter tests, 35 rules tests, clean analyze. No Android APK/cloud/ARTEMIS proof yet.
5. Android template exists: application ID vn.prm393.hobbytracker. Add your Firebase config/providers/SHA; do not regenerate native project over custom manifest/Gradle settings.
6. No production deployment, billing, Git push/commits or Figma mutation occurred.
