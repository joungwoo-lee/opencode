@echo off
setlocal

REM Colors (not supported in standard batch, skipping)

REM 1. Check Bun
where bun >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Bun is not installed. Please install Bun first.
    exit /b 1
)

REM 2. Setup Directories
set "SCRIPT_DIR=%~dp0"
REM SCRIPT_DIR ends with opencode_offline_setup\, so we need parent dir
pushd "%SCRIPT_DIR%.."
set "WORKSPACE_DIR=%CD%"
popd
set "OPENCODE_PKG_DIR=%WORKSPACE_DIR%\packages\opencode"

if not exist "%OPENCODE_PKG_DIR%" (
    echo Error: Cannot find packages\opencode directory.
    exit /b 1
)

REM 3. Install dependencies
echo Installing dependencies...
cd /d "%WORKSPACE_DIR%"
call bun install
if %errorlevel% neq 0 (
    echo Error during bun install
    exit /b %errorlevel%
)

REM 4. Build
echo Building opencode...
cd /d "%OPENCODE_PKG_DIR%"
call bun run script/build.ts --single
if %errorlevel% neq 0 (
    echo Error during build
    exit /b %errorlevel%
)

REM 5. Install Binary
set "INSTALL_DIR=%USERPROFILE%\.opencode\bin"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Find the build directory
REM We prefer opencode-windows-x64 over opencode-windows-x64-baseline if both exist
set "BUILD_DIR=%OPENCODE_PKG_DIR%\dist\opencode-windows-x64"

if not exist "%BUILD_DIR%" (
    REM Try baseline or any other match
    for /d %%D in (dist\opencode-windows-x64*) do (
        set "BUILD_DIR=%%D"
        goto :FoundDir
    )
)
:FoundDir

if "%BUILD_DIR%"=="" (
    echo Error: Build directory not found in dist
    exit /b 1
)

if not exist "%BUILD_DIR%\bin\opencode.exe" (
    echo Error: Binary not found at %BUILD_DIR%\bin\opencode.exe
    exit /b 1
)

echo Installing binary from %BUILD_DIR%\bin\opencode.exe to %INSTALL_DIR%...
copy /Y "%BUILD_DIR%\bin\opencode.exe" "%INSTALL_DIR%\opencode.exe" >nul

REM 6. Add to PATH
REM Check if already in PATH
echo %PATH% | findstr /C:"%INSTALL_DIR%" >nul
if %errorlevel% equ 0 (
    echo PATH already configured.
) else (
    echo Adding %INSTALL_DIR% to User PATH...
    REM Use PowerShell to modify user environment variable persistently
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
