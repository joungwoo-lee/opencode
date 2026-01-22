@echo off
setlocal

echo Installing Opencode for Windows...

set "SCRIPT_DIR=%~dp0"
set "SOURCE_BIN=%SCRIPT_DIR%dist\opencode-windows-x64.exe"
set "TARGET_DIR=%USERPROFILE%\opencode\bin"

if not exist "%SOURCE_BIN%" (
    echo Error: Source binary not found at "%SOURCE_BIN%"
    echo Please make sure you have run the build_offline.sh script first and transferred the "dist" folder.
    pause
    exit /b 1
)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

echo Copying binary...
copy /Y "%SOURCE_BIN%" "%TARGET_DIR%\opencode.exe"

if %ERRORLEVEL% NEQ 0 (
    echo Error copying file.
    pause
    exit /b 1
)

echo.
echo Binary installed to: %TARGET_DIR%
echo.
echo Adding installation directory to User PATH...

:: PowerShell을 사용하여 PATH 환경 변수 업데이트 (중복 체크 포함)
powershell -Command "$userPath = [Environment]::GetEnvironmentVariable('Path', 'User'); if (-not $userPath.Contains('%TARGET_DIR%')) { [Environment]::SetEnvironmentVariable('Path', $userPath + ';%TARGET_DIR%', 'User'); Write-Host 'Added to PATH.' } else { Write-Host 'Already in PATH.' }"

echo.
echo Installation complete!
echo Please restart your terminal or command prompt to use the 'opencode' command.
pause
