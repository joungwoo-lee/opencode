# OpenCode 커스텀 에이전트 및 도구 제작 가이드

이 문서는 OpenCode 프로젝트에서 자신만의 커스텀 에이전트(Agent)와 도구(Tool)를 만드는 방법을 단계별로 안내합니다.

## 최종 목표

이 가이드를 따라하면, "Jules"라는 이름을 입력했을 때 "Hello, Jules!"라고 인사하는 `greeter`라는 커스텀 에이전트를 만들게 됩니다. 이 과정에서 **로컬 Python 스크립트를 호출하는** 커스텀 도구를 정의하고, 에이전트가 해당 도구를 사용하도록 설정하는 방법을 배우게 됩니다.

## 1단계: 프로젝트 구조 설정

먼저, 커스텀 에이전트와 도구를 저장할 디렉터리를 생성해야 합니다. OpenCode는 프로젝트 루트의 `.opencode` 디렉터리에서 관련 설정 파일을 자동으로 인식합니다.

터미널에서 아래 명령어를 실행하여 필요한 디렉터리를 생성하세요.

```bash
mkdir -p .opencode/agents .opencode/tools
```

- **`.opencode/agents/`**: 커스텀 에이전트 정의 파일(`.md`)을 저장하는 곳입니다.
- **`.opencode/tools/`**: 커스텀 도구 정의 파일(`.ts`, `.js`) 및 관련 스크립트(`.py` 등)를 저장하는 곳입니다.

## 2단계: 커스텀 도구 만들기 (Python 스크립트 호출)

OpenCode의 커스텀 도구는 TypeScript나 JavaScript로 정의되지만, 실제 로직은 Python, Shell 등 다른 언어로 작성된 스크립트를 호출하여 실행할 수 있습니다. 여기서는 Python 스크립트를 사용하는 방법을 보여줍니다.

### 2.1. Python 스크립트 작성

먼저, 인사말을 생성하는 간단한 Python 스크립트를 작성합니다.

`.opencode/tools/` 디렉터리 안에 `hello.py`라는 이름으로 아래와 같이 파일을 생성하세요.

**파일: `.opencode/tools/hello.py`**
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
이 스크립트는 커맨드 라인 인자로 이름을 받아 표준 출력으로 인사말을 출력합니다.

### 2.2. 도구 정의 파일 작성 (TypeScript)

다음으로, 위에서 만든 `hello.py` 스크립트를 호출하는 OpenCode 도구를 정의합니다.

`.opencode/tools/` 디렉터리 안에 `hello.ts`라는 이름으로 아래와 같이 TypeScript 파일을 생성하세요.

**파일: `.opencode/tools/hello.ts`**
```typescript
import { tool } from "@opencode-ai/plugin";

export default tool({
  description: "Greets the user by calling a Python script",
  args: {
    name: tool.schema.string().describe("The name to greet"),
  },
  async execute(args) {
    const result = await Bun.$`python3 .opencode/tools/hello.py ${args.name}`.text();
    return result.trim();
  },
});
```

- `description`: LLM이 이 도구의 역할을 이해하는 데 사용됩니다.
- `args`: 도구가 받을 인자를 정의합니다. `name`이라는 문자열 인자를 받습니다.
- `execute`: 도구의 실제 로직이 실행되는 부분입니다.
    - `Bun.$`: Bun 런타임의 강력한 기능으로, 셸 명령어를 안전하고 쉽게 실행할 수 있게 해줍니다.
    - `python3 .opencode/tools/hello.py ${args.name}`: `hello.py` 스크립트를 실행하면서 `name` 인자를 전달합니다.
    - `.text()`: 명령어의 표준 출력(stdout)을 텍스트로 가져옵니다.
    - `.trim()`: 결과 문자열의 양 끝에 있는 공백을 제거합니다.

## 3단계: 커스텀 에이전트 만들기

다음으로, 위에서 만든 `hello` 도구를 사용할 수 있는 `greeter` 에이전트를 정의합니다.

`.opencode/agents/` 디렉터리 안에 `greeter.md`라는 이름으로 아래와 같이 마크다운 파일을 생성하세요. (이전과 동일)

**파일: `.opencode/agents/greeter.md`**
```markdown
---
description: An agent that greets the user using a custom tool.
mode: primary
tools:
  hello: true
---

You are a friendly greeter agent. Your primary function is to greet users by their name.
When given a name, you MUST use the `hello` tool to generate the greeting.
```

- `mode: primary`: 이 에이전트를 CLI에서 직접 호출할 수 있게 합니다.
- `tools: { hello: true }`: `hello` 도구를 이 에이전트가 사용할 수 있도록 허용합니다.
- 본문 내용은 LLM에게 전달되는 시스템 프롬프트로, `hello` 도구를 사용하도록 명확히 지시합니다.

## 4단계: 테스트 및 실행

이제 새로 만든 에이전트와 도구가 잘 작동하는지 테스트해볼 차례입니다.

**의존성 설치:**
만약 아직 프로젝트 의존성을 설치하지 않았다면, 프로젝트 루트에서 아래 명령어를 실행하세요.
```bash
bun install
```

**에이전트 실행:**
아래 명령어를 사용하여 `greeter` 에이전트를 실행하고, 'Jules'에게 인사하도록 요청합니다.

```bash
bun run --cwd packages/opencode --conditions=browser src/index.ts run --agent greeter "Use the hello tool to greet 'Jules'"
```

**예상 결과:**
성공적으로 실행되면, 터미널에서 다음과 같은 결과를 확인할 수 있습니다.

```
I'll use the hello tool to greet Jules.

Hello, Jules! 👋
```

이 결과는 `greeter` 에이전트가 `hello` 도구를 호출했고, `hello` 도구는 다시 `hello.py` 스크립트를 성공적으로 실행하여 최종 결과물을 만들어냈음을 의미합니다.

축하합니다! 이제 여러분은 OpenCode에서 로컬 스크립트를 활용하는 강력한 커스텀 에이전트와 도구를 만들 수 있게 되었습니다.
