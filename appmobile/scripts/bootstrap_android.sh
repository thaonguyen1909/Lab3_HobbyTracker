#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo 'Install Flutter and add its bin/ to PATH' >&2; exit 1; }
flutter --version
flutter doctor -v
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
had_widget_test=0
[[ ! -f test/widget_test.dart ]] || had_widget_test=1
for f in pubspec.yaml lib/main.dart test/widget_test.dart; do
  if [[ -f "$f" ]]; then mkdir -p "$tmp/$(dirname "$f")"; cp "$f" "$tmp/$f"; fi
done
flutter create --platforms=android --project-name=hobby_tracker --org=com.example .
for f in pubspec.yaml lib/main.dart test/widget_test.dart; do
  [[ ! -f "$tmp/$f" ]] || cp "$tmp/$f" "$f"
done
if [[ $had_widget_test -eq 0 && -f test/widget_test.dart ]]; then rm test/widget_test.dart; fi
flutter pub get
flutter analyze
flutter test
flutter devices
echo 'Run: flutter run -d <device-id>'
echo 'Note: com.example is temporary; choose your real application ID before Phase 02.'
