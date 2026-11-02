# Source code review — 03/11/2026

This is an in-session Codex review with independently checked code/tests, not a CodeRabbit/Copilot PR review or a fabricated commit trail. External PR review and ≥3 separate fix commits remain Phase08 gates.

| ID | Category | File:line | Decision and evidence |
|---|---|---|---|
| CR01 | Correctness | lib/viewmodels/auth_view_model.dart:8 | Sequential profile asyncMap delayed logout. Accepted: independent identity/Future profile gate. Auth race regression tests pass. |
| CR02 | Security | firebase/firestore.rules:16 | Hobby duplicate reservation could be forged without a canonical cross-document rule. Accepted: nameKey equals lower name and atomic matching reservation, duplicate/forged-key emulator tests pass. |
| CR03 | Correctness | lib/viewmodels/hyper_view_model.dart:39 | Opening a hobby while draft load was pending could overwrite prior notes. Accepted: restoring state blocks selection; delayed-storage test passes. |
| CR04 | Correctness | lib/viewmodels/hyper_view_model.dart:88 | Idle periodic ticker outlived the route in tests. Accepted: ticker only while running, pause/reset/dispose cancel it. Full-route tests pass. |
| CR05 | Correctness | lib/firebase/firestore_hobby_repository.dart:540 | Message acknowledgement loss could cause immutable-doc retry failure. Accepted: transaction returns existing identical stable draft instead of overwriting; VM retry test and immutable-message rules cover behavior. |
| CR06 | UX | lib/features/community/screens/community_screens.dart:37 | Like/comment row overflowed 82px at 360dp and 30px at 412dp. Accepted: Wrap, rerender all routes at both widths passes. |
| CR07 | Security | lib/firebase/firebase_device_services.dart:43 | Initial signed-out boot could retain prior local owner. Accepted: explicit first initialization and clear prior owner; local guards remove late notification writes. Native lifecycle verification still required. |
| CR08 | Security | lib/firebase/firebase_auth_service.dart:118 | Account changes during picker must not link to old identity. Accepted: UID recheck and same-email rule. Adapter tests check auth boundary; real native linking remains NOT RUN. |
