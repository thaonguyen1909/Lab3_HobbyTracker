# Run from your Flutter project root on Windows PowerShell.
# Requires Flutter, Firebase CLI and Firebase project permissions.
param([string]$Org)
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Install Flutter first.' }
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
  throw 'Install Firebase CLI: npm install -g firebase-tools; then firebase login.'
}
if (-not (Test-Path 'android')) {
  if ([string]::IsNullOrWhiteSpace($Org)) {
    throw 'Android folder missing. Re-run: powershell -ExecutionPolicy Bypass -File scripts/setup_phase02_windows.ps1 -Org "com.yourcompany" (choose your real org; DO NOT reuse com.example).'
  }
  if ($Org -match '^com[.]example($|[.])') { throw 'Choose your own unique Android organization ID; com.example is temporary.' }
  $temp = Join-Path ([System.IO.Path]::GetTempPath()) ('hobby-phase02-' + [guid]::NewGuid())
  New-Item -ItemType Directory -Path $temp | Out-Null
  $hadDefaultTest = Test-Path 'test/widget_test.dart'
  try {
    foreach ($item in @('pubspec.yaml', 'lib/main.dart')) {
      Copy-Item $item (Join-Path $temp ((Split-Path $item -Leaf))) -Force
    }
    flutter create --platforms=android --project-name=hobby_tracker --org=$Org .
    if ($LASTEXITCODE -ne 0) { throw 'flutter create failed' }
    Copy-Item (Join-Path $temp 'pubspec.yaml') 'pubspec.yaml' -Force
    Copy-Item (Join-Path $temp 'main.dart') 'lib/main.dart' -Force
    if (-not $hadDefaultTest -and (Test-Path 'test/widget_test.dart')) {
      Remove-Item 'test/widget_test.dart' -Force # remove generated MyApp template test
    }
  } finally {
    Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
# Existing Phase01 apps may still have the com.example package.
$gradleFiles = Get-ChildItem 'android/app' -Filter '*.gradle*' -ErrorAction SilentlyContinue
foreach ($gradleFile in $gradleFiles) {
  if (Select-String -Path $gradleFile.FullName -Pattern 'com[.]example' -Quiet) {
    throw 'Existing Android applicationId/namespace still uses com.example. Fix the package namespace before registering Firebase. See scripts/setup_phase02_windows.md.'
  }
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
dart pub global activate flutterfire_cli
if ($LASTEXITCODE -ne 0) { throw 'FlutterFire CLI install failed' }
# If flutterfire is not in PATH, add %LOCALAPPDATA%\Pub\Cache\bin to PATH.
flutterfire configure --platforms=android
if ($LASTEXITCODE -ne 0) { throw 'FlutterFire configuration failed' }
Write-Host 'Next: enable Google and Email/Password in Firebase Authentication; add Android SHA-1/SHA-256.'
Write-Host 'Next: create Cloud Firestore; REVIEW rules, then manually run firebase deploy --project YOUR_FIREBASE_PROJECT_ID --only firestore:rules.'
Write-Host 'Next: flutter analyze; flutter test; flutter run.'
Write-Warning 'DO NOT publish API secrets, service accounts, or test-account passwords.'
