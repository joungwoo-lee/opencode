# Opencode Offline Setup

이 폴더는 인터넷 연결이 없는 폐쇄망 환경에서 Opencode CLI를 설치하기 위한 도구들을 포함하고 있습니다.

## 1. 빌드 (인터넷 연결 필요)

먼저 인터넷이 연결된 환경에서 빌드 스크립트를 실행하여 바이너리를 생성해야 합니다.

```bash
./build_offline.sh
```

이 스크립트가 성공적으로 완료되면 `dist` 폴더 안에 실행 파일들이 생성됩니다.

## 2. 이동

`opencode_offline_setup` 폴더 전체를 폐쇄망 환경으로 복사합니다.

## 3. 설치 (폐쇄망 환경)

### Linux

터미널을 열고 다음 명령어를 실행합니다:

```bash
chmod +x install.sh
sudo ./install.sh
```

설치가 완료되면 `opencode` 명령어를 사용할 수 있습니다.

### Windows

`install.bat` 파일을 관리자 권한으로 실행하거나 더블 클릭하여 실행합니다.

설치가 완료되면 새 터미널 창을 열고 `opencode` 명령어를 사용할 수 있습니다.
