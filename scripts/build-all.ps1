# Production build: publish backend as single-file exe (sidecar),
# then build the Tauri release bundle (installer + portable).

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$frontend = Join-Path $repoRoot "frontend"

Write-Host "==> Step 1/2: Publishing backend sidecar..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "publish-backend.ps1")

Write-Host ""
Write-Host "==> Step 2/2: Building Tauri release bundle..." -ForegroundColor Cyan
Push-Location $frontend
try {
    npx tauri build
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "==> Done. Installer / portable artifacts:" -ForegroundColor Green
$bundleDir = Join-Path $frontend "src-tauri\target\release\bundle"
if (Test-Path $bundleDir) {
    Get-ChildItem $bundleDir -Recurse -Include *.msi,*.exe |
        ForEach-Object { "  $($_.FullName)" }
} else {
    Write-Host "  (bundle dir not found - check tauri build output)" -ForegroundColor Yellow
}
