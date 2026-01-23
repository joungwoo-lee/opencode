# OpenCode 오프라인 커스텀 에이전트 및 도구 제작 가이드

이 문서는 OpenCode 오프라인 설치 패키지에 포함될 자신만의 커스텀 에이전트(Agent)와 도구(Tool)를 만드는 방법을 단계별로 안내합니다.

## 최종 목표

이 가이드를 따라하면, "Jules"라는 이름을 입력했을 때 "Hello, Jules!"라고 인사하는 `greeter`라는 커스텀 에이전트를 만들고, 이를 오프라인 설치 패키지에 포함시켜 배포할 수 있게 됩니다.

## 1단계: 파일 구조 및 위치

오프라인 설치 패키지는 `opencode_offline_setup` 디렉터리를 기준으로 작동합니다. 커스텀 에이전트와 도구 파일들은 이 디렉터리 안의 `config_opencode`에 위치해야 합니다.

- **에이전트 위치:** `opencode_offline_setup/config_opencode/agents/`
- **도구 위치:** `opencode_offline_setup/config_opencode/tools/`

이 구조에 맞게 파일들을 생성하거나 이동시키십시오.

## 2단계: 커스텀 도구 만들기 (Python 스크립트 호출)

여기서는 `greet`라는 이름의 커스텀 도구를 만듭니다. 이 도구는 실제 로직을 담고 있는 Python 스크립트를 호출하는 방식으로 작동합니다.

### 2.1. Python 스크립트 작성

인사말을 생성하는 간단한 Python 스크립트를 작성합니다.

**파일: `opencode_offline_setup/config_opencode/tools/greet.py`**
```python
import sys

def greet():
    if len(sys.argv) > 1:
        name = sys.argv[1]
        print(f"Hello, {name}!")
    else:
        print("Hello, World!")

if __name__ == "__main__":
    greet()
```

### 2.2. 도구 정의 파일 작성 (TypeScript)

`greet.py` 스크립트를 호출하는 OpenCode 도구를 TypeScript로 정의합니다. 이 파일은 설치 후에도 `greet.py`를 안정적으로 찾을 수 있도록 동적 경로를 사용해야 합니다.

**파일: `opencode_offline_setup/config_opencode/tools/greet.ts`**
```typescript
import { tool } from "@opencode-ai/plugin";
import { join } from "node:path";

export default tool({
  description: "Greets the user by calling a Python script",
  args: {
    name: tool.schema.string().describe("The name to greet"),
  },
  async execute(args) {
    // 'import.meta.dir'을 사용하여 현재 파일의 디렉터리를 기준으로
    // 'greet.py'의 절대 경로를 동적으로 계산합니다.
    const pythonScriptPath = join(import.meta.dir, "greet.py");

    const result = await Bun.$`python3 ${pythonScriptPath} ${args.name}`.text();
    return result.trim();
  },
});
```

## 3단계: 커스텀 에이전트 만들기

다음으로, 위에서 만든 `greet` 도구를 사용할 수 있는 `greeter` 에이전트를 정의합니다.

**파일: `opencode_offline_setup/config_opencode/agents/greeter.md`**
```markdown
---
description: An agent that greets the user using a custom tool.
mode: primary
tools:
  greet: true
---

You are a friendly greeter agent. Your primary function is to greet users by their name.
When given a name, you MUST use the `greet` tool to generate the greeting.
```

- `tools: { greet: true }`: `greet` 도구를 이 에이전트가 사용할 수 있도록 허용합니다.

## 4단계: 설치 및 테스트

`opencode_offline_setup` 패키지에 포함된 에이전트와 도구는 `install.sh` (또는 `install.bat`) 스크립트를 통해 사용자의 시스템에 설치됩니다.

### 4.1. 설치 과정

`install.sh` 스크립트는 `config_opencode` 디렉터리의 모든 내용을 사용자의 전역 설정 폴더(`~/.config/opencode/`)로 복사합니다. 이 과정을 통해 우리가 추가한 `greeter` 에이전트와 `greet` 도구가 OpenCode CLI에서 인식될 수 있게 됩니다.

### 4.2. 실행 및 테스트

설치가 완료된 후, 터미널에서 아래 명령어를 실행하여 전역적으로 설치된 에이전트가 잘 작동하는지 테스트할 수 있습니다.

```bash
opencode run --agent greeter "Use the greet tool to greet 'Jules'"
```

**예상 결과:**
성공적으로 실행되면, 터미널에서 다음과 같은 결과를 확인할 수 있습니다.

```
I'll use the greet tool to greet Jules.

Hello, Jules! 👋
```

이 결과는 전역적으로 설치된 `greeter` 에이전트가 `greet` 도구를 호출했고, `greet` 도구는 `greet.py` 스크립트를 성공적으로 실행하여 최종 결과물을 만들어냈음을 의미합니다.
