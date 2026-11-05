# Run in the extracted project root. Requires Flutter SDK on Windows.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter not found. Add Flutter SDK bin to PATH, then run flutter doctor -v.'
}
flutter --version
flutter doctor -v
# flutter create can generate platform templates. Preserve authored Dart/project files.
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ('hobby-phase01-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $temp | Out-Null
$protected = @('pubspec.yaml','lib/main.dart','test/widget_test.dart')
$hadWidgetTest = Test-Path 'test/widget_test.dart'
try {
  foreach ($file in $protected) {
    if (Test-Path $file) {
      $dest = Join-Path $temp $file
      New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
      Copy-Item $file $dest -Force
    }
  }
  flutter create --platforms=android --project-name=hobby_tracker --org=com.example .
  if ($LASTEXITCODE -ne 0) { throw 'flutter create failed' }
  foreach ($file in $protected) {
    $backup = Join-Path $temp $file
    if (Test-Path $backup) { Copy-Item $backup $file -Force }
  }
  if (-not $hadWidgetTest -and (Test-Path 'test/widget_test.dart')) {
    Remove-Item 'test/widget_test.dart' -Force # remove default MyApp template test
  }
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
  flutter analyze
  if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed' }
  flutter test
  if ($LASTEXITCODE -ne 0) { throw 'flutter test failed' }
  flutter devices
  Write-Host 'Run: flutter run -d <device-id>'
  Write-Warning 'com.example is a temporary application ID. Choose the real org/package before Firebase Phase 02.'
} finally {
  Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
}
