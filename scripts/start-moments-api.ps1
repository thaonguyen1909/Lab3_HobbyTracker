$ErrorActionPreference = 'Stop'
$momentRepo = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath (Join-Path $momentRepo 'functions')
try {
    $momentNodeVersion = & node --version
    if ($LASTEXITCODE -ne 0 -or $momentNodeVersion -notmatch '^v22\.') { throw 'Use Node 22 in PATH.' }
    if (-not (Test-Path '.env.local')) { throw 'Copy moments-server.env.example to .env.local and configure credentials locally first.' }
    & npm.cmd run build
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & npm.cmd run start:api
    exit $LASTEXITCODE
} finally { Pop-Location }
