# Dev launcher: backend (dotnet watch) + Tauri dev in parallel.
# In debug builds the Tauri app does NOT spawn the bundled sidecar;
# it expects the backend to already be running on http://127.0.0.1:5050.

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$apiProj  = Join-Path $repoRoot "backend\src\VagonTest.Api\VagonTest.Api.csproj"
$frontend = Join-Path $repoRoot "frontend"

Write-Host "==> Starting backend (dotnet watch)..." -ForegroundColor Cyan
$backend = Start-Process -FilePath "dotnet" `
    -ArgumentList @("watch", "--project", "`"$apiProj`"", "run") `
    -WorkingDirectory $repoRoot `
    -PassThru -NoNewWindow

Write-Host "==> Starting frontend (tauri dev)..." -ForegroundColor Cyan
try {
    Push-Location $frontend
    npx tauri dev
} finally {
    Pop-Location
    if ($backend -and -not $backend.HasExited) {
        Write-Host ""
        Write-Host "==> Stopping backend (PID $($backend.Id))..." -ForegroundColor Yellow
        Stop-Process -Id $backend.Id -Force -ErrorAction SilentlyContinue
    }
}
