@echo off
setlocal EnableDelayedExpansion

:: Save the current directory
set "INITIAL_DIR=%CD%"

set "APP_NAME=mc_rcon_client"

:: Read version from pubspec.yaml
for /f "tokens=2" %%a in ('findstr "version: " pubspec.yaml') do set "VERSION=%%a"

if "!VERSION!" == "" (
    echo Version not found in pubspec.yaml
    goto end
)

echo Building !APP_NAME! version !VERSION! for Android

:: Run Flutter build for Android APK
call flutter build apk

:: Check if Flutter build was successful
if not !ERRORLEVEL! == 0 (
    echo Flutter build failed
    goto end
)

:: Define the APK path (modify as needed depending on your build flavor, e.g., release or debug)
set "APK_PATH=.\build\app\outputs\flutter-apk\app-release.apk"

:: Optionally, copy the APK to a designated directory (create if it does not exist)
set "OUTPUT_DIR=.\build\app"

copy "!APK_PATH!" "!OUTPUT_DIR!\!APP_NAME!-!VERSION!-android.apk"

if not !ERRORLEVEL! == 0 (
    echo Failed to copy APK
    goto end
)

echo APK for !APP_NAME!-!VERSION! is ready in !OUTPUT_DIR!

:end
:: Return to the initial directory
cd /d "%INITIAL_DIR%"
