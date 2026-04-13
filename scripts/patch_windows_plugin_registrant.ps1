# After `flutter pub get`, Flutter regenerates windows/flutter/generated_plugin_registrant.cc
# and re-enables WinRT Bluetooth plugins that can trigger MSVC debug abort().
# Run this from the repo root: powershell -ExecutionPolicy Bypass -File scripts/patch_windows_plugin_registrant.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root "windows\flutter\generated_plugin_registrant.cc"
if (-not (Test-Path $path)) { Write-Error "Missing $path" }

$c = Get-Content -Raw -Path $path

# Remove includes (idempotent)
$c = $c -replace '#include <flutter_blue_plus_winrt/flutter_blue_plus_plugin.h>\r?\n', ''
$c = $c -replace '#include <flutter_bluetooth_classic_serial/flutter_bluetooth_classic_plugin.h>\r?\n', ''
$c = $c -replace '#include <speech_to_text_windows/speech_to_text_windows.h>\r?\n', ''
$c = $c -replace '#include <universal_ble/universal_ble_plugin_c_api.h>\r?\n', ''

# Remove registration blocks
$c = $c -replace '  FlutterBluePlusPluginRegisterWithRegistrar\(\s*registry->GetRegistrarForPlugin\("FlutterBluePlusPlugin"\)\);\r?\n', ''
$c = $c -replace '  FlutterBluetoothClassicPluginRegisterWithRegistrar\(\s*registry->GetRegistrarForPlugin\("FlutterBluetoothClassicPlugin"\)\);\r?\n', ''
$c = $c -replace '  SpeechToTextWindowsRegisterWithRegistrar\(\s*registry->GetRegistrarForPlugin\("SpeechToTextWindows"\)\);\r?\n', ''
$c = $c -replace '  UniversalBlePluginCApiRegisterWithRegistrar\(\s*registry->GetRegistrarForPlugin\("UniversalBlePluginCApi"\)\);\r?\n', ''

if ($c -notmatch 'Billkaro: BLE/speech plugins not registered') {
  $c = $c -replace '(// clang-format off\r?\n)', "`$1`n// Billkaro: BLE/speech plugins not registered (see scripts/patch_windows_plugin_registrant.ps1)`n"
}

Set-Content -Path $path -Value $c -NoNewline
Write-Host "Patched $path"
