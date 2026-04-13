# Manual uninstall helper - use when the normal uninstaller fails with internal error
# Run as Administrator: Right-click -> Run with PowerShell (or open PowerShell as Admin and run .\uninstall_manual.ps1)

$AppName = "BillKaro"
$AppId = "{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"

Write-Host "Removing $AppName..." -ForegroundColor Yellow

# Possible install locations
$paths = @(
    "$env:ProgramFiles\$AppName",
    "${env:ProgramFiles(x86)}\$AppName",
    "C:\$AppName"
)

foreach ($path in $paths) {
    if (Test-Path $path) {
        Write-Host "Removing folder: $path" -ForegroundColor Cyan
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Remove uninstaller registry entry (64-bit and 32-bit view)
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$AppId",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$AppId"
)
foreach ($reg in $regPaths) {
    if (Test-Path $reg) {
        Write-Host "Removing registry: $reg" -ForegroundColor Cyan
        Remove-Item -Path $reg -Force -ErrorAction SilentlyContinue
    }
}

# Start Menu shortcut
$startMenu = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$AppName"
if (Test-Path $startMenu) {
    Remove-Item -Path $startMenu -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed Start Menu shortcut" -ForegroundColor Cyan
}

Write-Host "Done. $AppName has been removed." -ForegroundColor Green
