$ErrorActionPreference = 'Stop'
if (-not $env:FUNCTIONS_DISCOVERY_TIMEOUT) { $env:FUNCTIONS_DISCOVERY_TIMEOUT = '60' }
$momentRepo = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $momentRepo
try {
    # Parse in PowerShell to avoid native argument quote loss in Windows PowerShell 5.1.
    $momentNodeVersion = & node --version
    if ($LASTEXITCODE -ne 0 -or $momentNodeVersion -notmatch '^v22\.') {
        throw 'Use Node 22 in PATH to match the Functions runtime before running this suite.'
    }
    if (-not (Test-Path 'functions/node_modules') -or -not (Test-Path 'firebase/node_modules')) {
        throw 'Install locked dependencies first: npm.cmd --prefix functions ci; npm.cmd --prefix firebase ci'
    }
    & npm.cmd --prefix functions run build
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    # demo-* project ID prevents accidental access to a real Firebase project.
    & firebase.cmd emulators:exec --project demo-hobbytracker-moments --only auth,firestore,storage,functions --non-interactive 'npm.cmd --prefix functions run test:emulators'
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
