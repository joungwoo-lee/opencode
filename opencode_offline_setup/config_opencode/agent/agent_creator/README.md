
# Agent Creator

이 에이전트는 사용자의 요구사항을 받아 새로운 커스텀 에이전트 설정 파일(.md)을 자동으로 생성해주는 역할을 합니다.

## 설치 및 설정 방법

### 1. 파일 복사

이 `agent_creator` 폴더 전체를 `~/.config/opencode/agent/` 경로로 복사합니다.

### 2. 패키지 설치

Python 환경에 `mcp` 패키지가 설치되어 있어야 합니다.

```bash
pip install mcp
```

### 3. opencode.json 설정 (필수)

`~/.config/opencode/opencode.json` 파일이 없다면 생성하고, 있다면 아래 내용을 병합(Merge)하여 넣어주세요.
이 설정이 없으면 에이전트 생성 툴이 동작하지 않습니다.

```json
{
  "mcp": {
    "agent-creator-server": {
      "type": "local",
      "command": [
        "python",
        "{env:HOME}/.config/opencode/agent/agent_creator/mcp_server.py"
      ],
      "enabled": true
    }
  },
  "agent": {
    "agent-creator": {
      "permission": {
        "generate_agent_config": "allow"
      }
    }
  }
}
```

## 사용 방법

설정이 완료되면 오픈코드 채팅창에서 다음과 같이 요청할 수 있습니다:

> "@agent-creator 파이썬 코드 리뷰를 전문으로 하는 에이전트를 만들어줘."

> "@agent-creator 이름은 'translator'로 하고, 번역을 전문으로 하는 에이전트를 생성해줘. 웹 검색 권한도 줘."
