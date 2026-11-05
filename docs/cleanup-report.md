# Repository cleanup — 03/11/2026

PHASE: 08 | Repository hygiene
STATUS: PARTIAL — Flutter-generated junk and confirmed dead Dart file removed; some additional metadata deletion was rejected by automatic approval review.
SCOPE: No feature changes. App/test import+export graph scan found one unreachable Dart library: lib/core/state/load_state.dart. rg also found no usages of its LoadState/LoadViewState types outside that file. Removed it and its obsolete scaffold is no longer compiled. Historical changed-file manifests are retained as history, not edited to hide the deletion.

CHANGED FILES: deleted lib/core/state/load_state.dart; .gitignore now excludes /android/.kotlin/; docs/cleanup-report.md; docs/evidence/08/cleanup/.
DESIGN TRACEABILITY: no screens/flows/theme changes.

## Actual cleanup

- flutter clean removed build intermediates, .dart_tool caches and generated Flutter plugin metadata.
- Preserved current APK at build/app/outputs/flutter-apk/app-debug.apk by moving it outside build during cleaning, then restoring. SHA256 matches before cleaning; 223,593,333 bytes. App installed on emulator was not cleared or uninstalled.
- Measured removed items: 2,384,576,210 bytes (~2.22 GiB), 4,623 generated files; see results.json. This excludes the preserved APK and excludes retained cache targets.
- flutter pub get --offline recreated required package metadata. No dependency version change was reported.
- Preserved source, fonts/SVGs, Firebase JSON, lockfiles, Android wrapper/configuration, docs/requirements/reference/design/handoff/planning documents, screenshots, all evidence and tests.
- firebase/node_modules is still required by the Rules tests; retained. Android .gradle/.kotlin, generated iml, root Firestore debug log and empty scaffold/staging directories also remain. Two explicit PowerShell removal calls were rejected before execution as “blocked by policy”; no detailed reason was supplied. Used supported flutter clean instead of bypassing that review. plan.json records candidate targets, NOT a claim that all targets were removed; results.json identifies actual removals/retained targets.

ACCEPTANCE GATES:
  [PASS] flutter test --no-pub --reporter expanded after deleting dead source — 81/81, tests.log.
  [PASS] flutter analyze --no-pub after source deletion — analyze.log.
  [PASS] dart format --output=none --set-exit-if-changed . — format.log, 57 files/zero changes.
  [PASS] flutter clean — flutter-clean.log.
  [PASS] flutter pub get --offline — pub-get.log.
  [PASS] flutter analyze --no-pub after clean/recovery — analyze-after-clean.log.
  [PASS] preserved APK SHA256 — plan.json/results.json.
  [NOT RUN] New APK build after cleanup: no reachable code changed; rebuilding would recreate the removed intermediates. Latest already-built APK retained unchanged.
  [NOT RUN] Rules suite this turn: no Firebase/security changes; previous results not counted as a fresh run.

COMMANDS ACTUALLY RUN: git status --short (no .git, unavailable); import graph/rg scans; dart format; flutter analyze (before and after clean); flutter test (81 pass); flutter clean; flutter pub get --offline; APK SHA256 and target existence checks. Logs in docs/evidence/08/cleanup/.
SECURITY & DATA CHECK: no credentials printed, no account data or remote operations; cleanup paths limited to this workspace. References/assets/evidence were not treated as junk.
OPEN DECISIONS / RISKS: additional PowerShell cleanup blocked; retained small metadata and required Node dependencies. Broader cloud/ARTEMIS gates unchanged.
COMMIT/PR/DEPLOY: NOT CREATED.
READY FOR HUMAN REVIEW: YES.
NEXT PHASE: NOT STARTED.
