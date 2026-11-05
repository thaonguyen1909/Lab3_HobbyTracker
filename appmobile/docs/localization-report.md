# Anh / Việt — Localization implementation, 03/11/2026

PHASE: 06 | App language and full app-owned UI copy
STATUS: PARTIAL — requested language feature implemented/tested/build installed; remaining Lab3 cloud/native service acceptance is not claimed.

## User-visible behavior

Settings → Language / Cài đặt → Ngôn ngữ offers English and Vietnamese. Selecting a language immediately updates the current page and all app-owned labels, loading/error/validation/success messages, confirmation sheets, navigation and theme labels. Date/time pickers and formatted dates use Flutter's matching Material/Cupertino localization. English remains the default for a fresh install; existing selected language is restored before showing app pages to avoid an English flash.

Language is an application preference on this device, stored at SharedPreferences key app_language. It works without Firebase/network and persists on relaunch/sign-out. It is not synced between devices. No Firestore field/schema/Rules change or deployment is necessary.

User-authored hobby/group/event names, descriptions, posts, comments, messages, notes, usernames and URLs are ordinary Text, not translation keys. Brand names (Hobby Tracker, Google, Spotify, YouTube, Cốc Cốc, Firebase, etc.) and required diagnostic identifiers such as CRASH remain unchanged. Operating-system/Google account screens are outside app localization and follow the device/provider language. Remote notification content supplied by a sender is not machine-translated.

## Implementation

- lib/l10n/app_strings.dart: app localization delegate, localized UI text and parameterized message lookup, preserving user parameters literally.
- lib/l10n/messages.dart: English/Vietnamese catalog, including aliases for existing Vietnamese domain errors. No external translation API and no user content upload. Dynamic error codes/counts are preserved.
- lib/l10n/language_controller.dart: injected persistence, asynchronous restore and safe save/rollback. Invalid codes are rejected; failure leaves the previous language selected and allows retry.
- App installs English/Vietnamese GlobalMaterial/Widgets/Cupertino delegates and locale; Settings adds a seventh detail category without changing the four bottom destinations or authentication guards.
- Shared widgets/features translate at presentation boundaries. Firestore names/priorities/theme identifiers remain unchanged.
- App-generated local reminders/generic notification titles and newly generated PDF reports use the selected language; language changes trigger reminder resync. Existing exported PDF files and received sender content retain their original content.
- New dependencies: flutter_localizations from the installed Flutter SDK; intl pinned 0.20.3 (compatible with this SDK), for locale-aware date formatting. No competing state manager or paid service.

## Checks actually run

| Gate | Result | Evidence |
|---|---|---|
| flutter pub get | PASS, added SDK localization and intl | docs/evidence/06/localization/pub-get.log |
| dart format --output=none --set-exit-if-changed . | PASS, 61 files, zero changes | format-check.log |
| flutter analyze --no-pub | PASS, No issues found | analyze-final.log |
| flutter test --no-pub --reporter expanded | PASS, 96/96 | tests-final.log |
| New locale tests | PASS 15 cases: restore/write failure/retry, same route, sign-out retention, both languages at 360/412 across screens, user content, validation/forms, date picker, 200% text and PDF generation | test/localization_test.dart |
| flutter build apk --debug --no-pub | PASS | android-build-final.log |
| adb install -r + launch | PASS, original account data retained | install.log; tool output |
| Native UI smoke | English Home/Settings/Language and Vietnamese My Hobbies/Home observed on Pixel 9; Home remained Vietnamese after process restart | screenshots in tool outputs; android-vietnamese-hobbies.xml; android-live-language-page.xml |
| Raw native snapshot interpretation | Captured live XML was the English Language page after concurrent user navigation, not a Vietnamese Home relaunch snapshot; file named accordingly | native-check.json |
| Cloud account isolation / ARTEMIS / delivered FCM + local reminders / PDF upload | NOT RUN this turn. Code locale updates do not prove delivered notification or cloud acceptance | unchanged Lab3 manual gates |
| git status/diff | unavailable because workspace has no .git | git-diff-check.log; no fabricated diff/history |

Earlier failing logs are retained: old UI tests expected mixed Vietnamese strings while the baseline is now fully English; those expectations were updated to English without removing service/security assertions. Additional locale tests verify the Vietnamese path independently. Initial localization tests also caught fixture/name collisions and brand-name detection in coverage checks; final tests include populated group data and preserve user-authored content.

## Scope and traceability

DX23: user explicitly requested a Language category and coherent English/Vietnamese copy; this extends the Figma baseline without changing the three product flows. Native layout was checked at current emulator viewport; fixture-based widget tests cover 360/412 and selected large-text screens. No claim of pixel parity/WCAG certification or every vendor/OS dialog being controlled by this app.

Changed-file inventory: docs/evidence/06/localization/changed-files.json. Original reference artifacts and Firebase config remain untouched. The cleanup from the previous task removed only a dead library and generated caches, and the 96 tests/build here also corroborate that it did not break the app. Rebuilding naturally regenerates build/cache files.

OPEN DECISIONS / RISKS: system/provider screens follow device settings; language choice is device-local. Broader Storage billing/service and cloud/ARTEMIS evidence remain open, not silently marked PASS.
COMMIT/PR/DEPLOY: NOT CREATED.
READY FOR HUMAN REVIEW: YES.
NEXT PHASE: NOT STARTED.
