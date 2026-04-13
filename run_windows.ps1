# Run BillKaro on Windows
# Usage: .\run_windows.ps1

Set-Location $PSScriptRoot
flutter pub get
powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\scripts\patch_windows_plugin_registrant.ps1"
flutter run -d windows
