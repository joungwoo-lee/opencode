# Opencode Offline Setup

이 폴더는 인터넷 연결이 없는 폐쇄망 환경에서 `opencode`를 설치하고 사용하기 위한 스크립트를 포함하고 있습니다.

## 1. 소스 코드를 이용한 설치 (Build from Source)

인터넷이 연결된 외부망에서 전체 소스 코드를 가져온 후, 내부망에서 직접 빌드하여 설치하는 방법입니다. **Node.js**와 **Bun**이 설치되어 있어야 합니다.

* **Linux/macOS**: `install-from-source.sh` 실행
* **Windows**: `install-from-source.bat` 실행

## 2. 바이너리 파일을 이용한 설치 (Install from Binary)

외부망에서 미리 빌드된 실행 파일(`opencode` 또는 `opencode.exe`)을 가져와서 설치하는 방법입니다.

1. 외부망에서 빌드하여 실행 파일을 생성합니다.
2. 실행 파일을 이 폴더(`opencode_offline_setup`)로 복사합니다.
3. 다음 스크립트를 실행합니다:
    * **Linux/macOS**: `install-binary.sh`
    * **Windows**: `install-binary.bat`

## 3. 완전 폐쇄망 번들 (Full Offline Bundle)

의존성(LSP 서버, 파서 등)까지 모두 포함된 완전한 오프라인 번들을 생성하려면, 외부망에서 다음 명령어를 실행하세요:

```bash
bun run packages/opencode/script/bundle-offline.ts
```

생성된 `dist/offline` 폴더를 폐쇄망으로 가져가서 `install.sh`를 실행하면 됩니다.
