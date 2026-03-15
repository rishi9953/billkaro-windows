# Run this script from repo root during git filter-branch (tree filter).
# Replaces hardcoded Twilio secrets with placeholders so GitHub push protection accepts the push.
$path = "lib\app\modules\Whatsapp Marketing\twilioapi_service.dart"
if (Test-Path $path) {
  $content = Get-Content $path -Raw -Encoding UTF8
  $content = $content -replace 'ACc4c9d6cace00d8519b331a93d9d3fe22', 'YOUR_TWILIO_ACCOUNT_SID'
  $content = $content -replace 'da5897e3d05c48d6fcd199cb2e6e82da', 'YOUR_TWILIO_AUTH_TOKEN'
  Set-Content $path $content -NoNewline -Encoding UTF8
}
