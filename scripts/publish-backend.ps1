# Publishes VagonTest.Api as a self-contained single-file Windows exe
# and copies it into the Tauri src-tauri/binaries/ folder with the
# target-triple suffix that Tauri's sidecar mechanism expects.

$ErrorActionPreference = "Stop"

$repoRoot       = Split-Path -Parent $PSScriptRoot
$apiProject     = Join-Path $repoRoot "backend\src\VagonTest.Api\VagonTest.Api.csproj"
$publishDir     = Join-Path $repoRoot "backend\publish\Api"
$sidecarDir     = Join-Path $repoRoot "frontend\src-tauri\binaries"
$sidecarTarget  = "x86_64-pc-windows-msvc"     # current Windows host triple
$sidecarBaseName = "vagontest-backend"
$sidecarFinalName = "$sidecarBaseName-$sidecarTarget.exe"

Write-Host "==> dotnet publish $apiProject" -ForegroundColor Cyan
dotnet publish $apiProject `
    -c Release `
    -r win-x64 `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -o $publishDir

$publishedExe = Join-Path $publishDir "VagonTest.Api.exe"
if (-not (Test-Path $publishedExe)) {
    throw "Published exe not found at $publishedExe"
}

if (-not (Test-Path $sidecarDir)) {
    New-Item -ItemType Directory -Path $sidecarDir -Force | Out-Null
}

$destination = Join-Path $sidecarDir $sidecarFinalName
Copy-Item $publishedExe $destination -Force

$sizeMB = [math]::Round((Get-Item $destination).Length / 1MB, 1)
Write-Host ""
Write-Host "==> Sidecar ready: $destination ($sizeMB MB)" -ForegroundColor Green
