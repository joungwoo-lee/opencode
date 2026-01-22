@echo off
setlocal
chcp 65001 >nul

:: 관리자 권한 확인
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo -------------------------------------------------------------------------------
    echo [안내] 본 설치 파일을 관리자 권한으로 실행하면 
    echo opencode 내에서 Ctrl + Shift + V로 붙여넣기를 할 수 있습니다.
    echo -------------------------------------------------------------------------------
    echo.
    echo 방법: 파일 우클릭 -^> '관리자 권한으로 실행' 클릭
    echo.
    pause
    exit /b
)

echo ---------------------------------------------------
echo [관리자 권한 확인됨] 설정을 시작합니다.
echo ---------------------------------------------------

echo.
echo 1. CMD 레지스트리 설정 (Ctrl+Shift+V 활성화)
:: InterceptCopyPaste: Ctrl+Shift+C/V 단축키 제어
reg add "HKEY_CURRENT_USER\Console" /v "InterceptCopyPaste" /t REG_DWORD /d 1 /f
:: QuickEdit: 마우스 우클릭으로 붙여넣기 가능하게 설정
reg add "HKEY_CURRENT_USER\Console" /v "QuickEdit" /t REG_DWORD /d 1 /f

echo.
echo 2. PowerShell PSReadLine 설정 (Ctrl+V 활성화)
:: PowerShell 내부의 단축키 핸들러를 Windows 표준으로 강제 설정
powershell -Command "Set-PSReadLineKeyHandler -Chord 'Ctrl+v' -Function Paste"
powershell -Command "Set-PSReadLineOption -EditMode Windows"

echo.
echo ---------------------------------------------------
echo 모든 설정이 완료되었습니다!
echo 터미널 창을 껐다가 다시 켜면 적용됩니다.
echo ---------------------------------------------------
pause