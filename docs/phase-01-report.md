# Phase 01 — Flutter foundation implementation report

**Date:** 03/11/2026
**Baseline:** ZIP `HobbyTracker_Phase00_Reviewed_2026-11-03.zip`
**Scope:** Phase 01 ONLY, per `docs/requirements/prompts/01-shell-theme.md`
**Status:** CODE UPDATED / STATIC PASS / NEW BUILD NOT RUN — previous Phase 01 app launched in owner screenshots; do not mark refined version PASS before Flutter verification.

## Implemented (source-level)

- Flutter project manifest, startup, ProviderScope and MaterialApp.router.
- `go_router` four branches Home · Community · My Hobbies · Settings; 15 handoff navigation destinations and six `/settings/:section` variants.
- Reusable 10 component families C01–C10. Light visual refinement for tokens, navigation, brand header, button/input/card/dialog states is recorded in [phase-01-visual-refinement.md](phase-01-visual-refinement.md).
- Tokenized Light ThemeData/ColorScheme/TextTheme/spacing/radius/elevation, ThemeExtension; 7 variant names with preliminary palettes (other 6 do not meet full Phase 06 visual acceptance).
- `FeatureShellViewModel` injected through Riverpod, `FeatureCatalogService` interface with local DESIGN METADATA (not fake user data).
- `LoadViewState<T>` for explicit loading/empty/data/error; real data VMs begin in future phases.
- Widget tests for theme/component targets and navigation; architecture diagrams / Service–ViewModel mapping.
- Windows and Bash bootstrap scripts to generate Android directory using user's Flutter SDK.

## Verification matrix

| Check | Result | Explanation |
|---|---|---|
| ZIP consistency/file paths/15 routes in source | PASS (static script) | `python scripts/verify_phase01_static.py` |
| YAML project metadata and source references | PASS (static script) | Does not replace Dart compiler |
| `flutter doctor -v` | NOT RUN | Flutter CLI absent from author environment |
| `flutter pub get` | NOT RUN | Flutter CLI / pub network absent |
| `flutter analyze` | NOT RUN | Requires SDK, dependency resolution |
| `flutter test` | NOT RUN | Requires SDK, dependency resolution |
| Previous Android launch | OBSERVED | Four user-provided screenshots in `docs/evidence/01/previous-build-screenshots/`, from the earlier build |
| Refined Android launch / navigate and back / screenshots 360 & 412 dp | NOT RUN | Requires rebuilding on user device |
| CSS Light token + navigation source agreement | PASS (static) | `python scripts/verify_phase01_design.py`; 21/21 checks; not Figma pixel proof |
| Figma latest Live parity and Lab 2 approval | BLOCKED | No Editor access in prior Figma connector attempt; approval/evidence unavailable |
| Phase 00 three HTML provenance mismatches | OPEN | Original files retained; owner must verify |

## DoD / owner verification before PASS

1. Run `powershell -ExecutionPolicy Bypass -File scripts/bootstrap_android.ps1` in the project root (Windows) to generate Android platform, resolve dependencies, run analyze/test and enumerate devices.
2. If tests pass, `flutter run -d <device-id>`. Check 4 tabs, 15 routes, Back, invalid Settings section, component states.
3. Capture 360dp / 412dp screenshots, check touch targets ≥48dp, body text ≥14sp, no overflow, layout and Figma baseline.
4. Record the Flutter/Dart versions, Android emulator/device and output in `docs/evidence/01/` and this report. Commit Android folder and `pubspec.lock` once generated.
5. Get final acceptance of outstanding Phase 00 D01/D05 with owner/lecturer; do not mark original Phase00 PASS by inference.

## Next phase (not implemented)

Phase 02 Firebase project/auth (Google + email/password) with session state/route guard/error handling. No Firebase dependencies or SDK calls have been added in Phase 01.
