@echo off
setlocal enabledelayedexpansion

echo ===========================================
echo Installing Opencode for Windows...
echo ===========================================

set "SCRIPT_DIR=%~dp0"
set "SOURCE_BIN=%SCRIPT_DIR%opencode-windows-x64.exe"
set "TARGET_DIR=%USERPROFILE%\opencode\bin"

:: 1. 소스 파일 존재 확인
if not exist "%SOURCE_BIN%" (
    echo [ERROR] Source binary not found: "%SOURCE_BIN%"
    goto :END
)

:: 2. 폴더 생성 및 파일 복사
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
echo Copying binary...
copy /Y "%SOURCE_BIN%" "%TARGET_DIR%\opencode.exe"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to copy file.
    goto :END
)

echo Binary installed to: %TARGET_DIR%

:: 3. PATH 환경 변수 추가 (가장 안전한 방식으로 변경)
echo Updating User PATH...
set "PS_CMD=$p=[Environment]::GetEnvironmentVariable('Path','User'); if($p -notlike '*%TARGET_DIR%*'){ [Environment]::SetEnvironmentVariable('Path',$p+';%TARGET_DIR%','User'); 'Added' } else { 'Already' }"

for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "%PS_CMD%"`) do set "RESULT=%%a"

if "%RESULT%"=="Added" (
    echo Successfully added to PATH.
) else (
    echo Directory already exists in PATH.
)

:: 4. 설정 파일 복사
echo.
set "CONFIG_SOURCE=%SCRIPT_DIR%config_opencode"
set "CONFIG_DEST=%USERPROFILE%\.config\opencode"

if exist "%CONFIG_SOURCE%" (
    if not exist "%CONFIG_DEST%" mkdir "%CONFIG_DEST%"
    xcopy /E /I /Y "%CONFIG_SOURCE%" "%CONFIG_DEST%"
    echo Configuration files copied.
)

echo.
echo ===========================================
echo Installation complete!
echo ===========================================

:END
echo.
echo Press any key to exit...
pause