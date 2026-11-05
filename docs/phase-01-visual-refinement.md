# Phase 01 — Light design system, navigation and component refinement

Date: 2026-11-03
Status: **SOURCE UPDATED / STATIC PASS / FLUTTER RUNTIME NOT VERIFIED**.

## Why the user's screenshot looked unlike the design

The first Phase 01 used a stock Material 3 `NavigationBar` and reused `FeatureLandingScreen` (a developer placeholder) for most routes. It also set cards to the same background color as the screen. None of that is evidence of pixel parity with Lab 2 Figma.

The owner supplied four emulator screenshots of the **previous build**, archived at `docs/evidence/01/previous-build-screenshots/`. They prove the earlier app opened but do not prove this revised code compiles or renders.

## Authoritative available baseline

- `docs/design/DESIGN.md` and `docs/design/handoff/flutter-handoff.md`
- `docs/requirements/reference/Prototype.html` — CSS `:root`, `.top`, `.nav`, `.card`, `.btn`, `.input`, `.empty`, `.hero`.
- Figma file `5JiJtLyXN6DEpC1LycQPBb`: **not accessible for fresh inspection** (the connector still reports no Editor permission). Exact current Figma visual parity is therefore **BLOCKED**, not PASS.

## Changed

| Requirement | Files | Observable change |
|---|---|---|
| Token map | `lib/theme/tokens.dart`, `lib/theme/hobby_theme.dart` | Light primary `#087F72`, ink `#213D36`, page `#F7FAF7`, white card surface, mint soft `#E7F5ED`, border `#D8E9DF`; named spacing/radius/header/nav dimensions; theme styles |
| C04 nav | `lib/widgets/app_navigation_bar.dart` | Flat white 4-tab nav, mint 46×34 selection under 20px icons, 76px bar, 48dp+ targets, key/semantics unchanged; icon for My Hobbies uses a heart per prototype |
| C05 header | `lib/widgets/hobby_app_bar.dart` | Branded top-level `hobby.` header, separate back/secondary-title variant, neutral header (no invented authenticated user) |
| C01 buttons | `lib/widgets/hobby_button.dart` | Primary/secondary/outline/danger, 48dp minimum, disabled & busy states; danger is a border variant matching `.btn.danger` |
| C02 inputs | `lib/widgets/hobby_text_field.dart` | External label; outlined 48dp input; actual password visibility; error retains draft |
| C03 cards | `lib/widgets/hobby_card.dart` | White surface, subtle border/shadow; focus/pressed states |
| C06 dialog | `lib/widgets/hobby_dialog.dart` | Cancel/confirm, busy submit protection, destructive option |
| C07–09 async | `lib/widgets/async_states.dart` | Loading text/spinner, empty action, error message/retry, theme semantics |
| C10 checkbox | `lib/widgets/hobby_checkbox.dart` | Label tap + 48dp checkbox hit target, selected/disabled |
| Page margin | `lib/features/shell/screens/feature_landing_screen.dart` | 20dp baseline page margin for the current *explicit placeholders* |

**Deliberate non-changes:** phase-specific Home/Hyper/Hobbies/Community/Settings content is still labelled placeholder. Real feature screens and Firestore belong to Phase 02–06. The Phase 01 scope is shell, shared design system, navigation and components; it is not an end-to-end Figma rebuild.

## Verification (do not confuse test source with test execution)

- `python scripts/verify_phase01_design.py`: **PASS**, 21/21 deterministic source/token/layout checks; output in `docs/evidence/01/visual-foundation-static.json`.
- `python scripts/verify_phase01_static.py`: **PASS**, source/import/route checks; 20 Dart source files, 4 test files.
- Light contrast checks (selected token pairs): primary/white 4.90:1; primaryDark/soft 5.39:1; muted/background 5.27:1; ink/white 11.76:1; danger/white 6.74:1. These checks do **not** prove all states/themes satisfy WCAG.
- `test/phase01_visual_foundation_test.dart`: **TESTS AUTHORED, NOT RUN**. Covers 360/412 widths, 4 tabs, branded header, tokens, password field, buttons and dialog states.
- `flutter analyze`, `flutter test`, Android rendering, fresh screenshots and Figma comparison: **NOT RUN / BLOCKED** (Flutter SDK/device and Figma access not present here).
- `python scripts/verify_phase00.py` exits nonzero as expected: three historical HTML hashes not verified. Do **not** overwrite or silently clear them.

## Reproduce on owner's Windows environment

From the folder containing `pubspec.yaml`:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\bootstrap_android.ps1
flutter analyze
flutter test
flutter run
```

The owner should verify Home / Community / My Hobbies / Settings under 360dp and 412dp and capture fresh screenshots of the **revised** build. If any command fails, collect complete output and fix before marking Phase 01 PASS. Direct Figma comparison requires Editor permission or approved screenshots/exports of the current Figma frames.

## Phase 01 acceptance

Current status = **PARTIAL — polish source delivered; not yet eligible for full PASS**.
