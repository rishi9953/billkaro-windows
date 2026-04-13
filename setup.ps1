# Nano setup script - BillKaro Windows
# Usage: .\setup.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "Setting up BillKaro..." -ForegroundColor Cyan

# Check Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter not found in PATH. Install Flutter and try again." -ForegroundColor Red
    exit 1
}

# Dependencies
Write-Host "Running flutter pub get..." -ForegroundColor Yellow
flutter pub get

powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\scripts\patch_windows_plugin_registrant.ps1"

# .env from example if missing
if (-not (Test-Path ".env") -and (Test-Path ".env.example")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example" -ForegroundColor Green
}

Write-Host "Setup complete. Run: flutter run -d windows" -ForegroundColor Green
