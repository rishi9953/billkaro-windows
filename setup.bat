@echo off
REM Nano setup script - BillKaro Windows
REM Usage: setup.bat

cd /d "%~dp0"

echo Setting up BillKaro...

where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Flutter not found in PATH. Install Flutter and try again.
    exit /b 1
)

echo Running flutter pub get...
flutter pub get

if not exist .env if exist .env.example (
    copy .env.example .env
    echo Created .env from .env.example
)

echo Setup complete. Run: flutter run -d windows
