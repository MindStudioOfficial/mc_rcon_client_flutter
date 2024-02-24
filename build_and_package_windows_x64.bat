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

echo Building !APP_NAME! version !VERSION!

:: Run Flutter build for Windows
call flutter build windows --release

:: Check if Flutter build was successful
if not !ERRORLEVEL! == 0 (
    echo Flutter build failed
    goto end
)

:: Use PowerShell to compress the Release directory into a .zip file
PowerShell -Command "Compress-Archive -Path '.\build\windows\x64\runner\Release\*' -DestinationPath '.\build\windows\x64\!APP_NAME!-!VERSION!-windows-x64.zip'"

if not !ERRORLEVEL! == 0 (
    echo Failed to create zip archive
    goto end
)

echo Distribution !APP_NAME!-!VERSION!.zip is ready in build\windows\x64

:end
:: Return to the initial directory
cd /d "%INITIAL_DIR%"
