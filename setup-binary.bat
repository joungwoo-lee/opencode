@echo off
setlocal

REM 1. Locate Binary
set "SCRIPT_DIR=%~dp0"
set "BINARY_NAME=opencode.exe"
set "BINARY_PATH=%SCRIPT_DIR%%BINARY_NAME%"

if not exist "%BINARY_PATH%" (
    echo Error: '%BINARY_NAME%' file not found in current directory.
    echo Please place the built '%BINARY_NAME%' binary in the same folder as this script.
    pause
    exit /b 1
)

REM 2. Install
set "INSTALL_DIR=%USERPROFILE%\.opencode\bin"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo Installing binary...
copy /Y "%BINARY_PATH%" "%INSTALL_DIR%\%BINARY_NAME%" >nul

REM 3. Add to PATH
echo %PATH% | findstr /C:"%INSTALL_DIR%" >nul
if %errorlevel% equ 0 (
    echo PATH already configured.
) else (
    echo Adding %INSTALL_DIR% to User PATH...
    powershell -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';%INSTALL_DIR%', 'User')"
    if %errorlevel% neq 0 (
        echo Failed to update PATH automatically. Please add %INSTALL_DIR% to your PATH manually.
    ) else (
        echo PATH updated successfully.
    )
)

echo.
echo Installation successful!
echo You may need to restart your terminal or log off and on again to use 'opencode'.
echo.
pause
