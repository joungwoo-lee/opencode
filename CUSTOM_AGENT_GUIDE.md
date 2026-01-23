# OpenCode 커스텀 에이전트 및 도구 제작 가이드

이 문서는 OpenCode 프로젝트에서 자신만의 커스텀 에이전트(Agent)와 도구(Tool)를 만드는 방법을 단계별로 안내합니다.

## 최종 목표

이 가이드를 따라하면, "Jules"라는 이름을 입력했을 때 "Hello, Jules!"라고 인사하는 `greeter`라는 커스텀 에이전트를 만들게 됩니다. 이 과정에서 커스텀 도구를 정의하고, 에이전트가 해당 도구를 사용하도록 설정하는 방법을 배우게 됩니다.

## 1단계: 프로젝트 구조 설정

먼저, 커스텀 에이전트와 도구를 저장할 디렉터리를 생성해야 합니다. OpenCode는 프로젝트 루트의 `.opencode` 디렉터리에서 관련 설정 파일을 자동으로 인식합니다.

터미널에서 아래 명령어를 실행하여 필요한 디렉터리를 생성하세요.

```bash
mkdir -p .opencode/agents .opencode/tools
```

- **`.opencode/agents/`**: 커스텀 에이전트 정의 파일(`.md`)을 저장하는 곳입니다.
- **`.opencode/tools/`**: 커스텀 도구 정의 파일(`.ts`, `.js`)을 저장하는 곳입니다.

## 2단계: 커스텀 도구 만들기

이제 `greeter` 에이전트가 사용할 간단한 도구를 만들어 보겠습니다. 이 도구는 이름을 인자로 받아 인사말을 반환하는 역할을 합니다.

`.opencode/tools/` 디렉터리 안에 `hello.ts`라는 이름으로 아래와 같이 TypeScript 파일을 생성하세요.

**파일: `.opencode/tools/hello.ts`**
```typescript
import { tool } from "@opencode-ai/plugin";

export default tool({
  description: "Greets the user",
  args: {
    name: tool.schema.string().describe("The name to greet"),
  },
  async execute(args) {
    return `Hello, ${args.name}!`;
  },
});
```

- `description`: LLM(거대 언어 모델)이 이 도구의 역할을 이해하는 데 사용됩니다.
- `args`: 도구가 받을 인자를 [Zod](https://zod.dev/) 스키마 형식으로 정의합니다. 여기서는 `name`이라는 문자열 인자를 받도록 설정했습니다.
- `execute`: 도구의 실제 로직이 실행되는 부분입니다. 입력받은 `name`을 사용하여 인사말 문자열을 반환합니다.

## 3단계: 커스텀 에이전트 만들기

다음으로, 위에서 만든 `hello` 도구를 사용할 수 있는 `greeter` 에이전트를 정의합니다.

`.opencode/agents/` 디렉터리 안에 `greeter.md`라는 이름으로 아래와 같이 마크다운 파일을 생성하세요.

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

- **머리말 (Frontmatter):**
    - `description`: 에이전트의 역할에 대한 설명입니다.
    - `mode: primary`: 이 에이전트가 CLI에서 직접 호출할 수 있는 주 에이전트(primary agent)임을 의미합니다. 만약 다른 에이전트에 의해서만 호출되게 하려면 `subagent`로 설정합니다.
    - `tools: { hello: true }`: `hello`라는 이름의 도구를 이 에이전트가 사용할 수 있도록 허용합니다.
- **본문 (Body):**
    - 이 부분은 LLM에게 전달되는 시스템 프롬프트(System Prompt)입니다. 에이전트의 역할과 행동 지침을 명확하게 정의하는 것이 중요합니다. 여기서는 `hello` 도구를 **반드시** 사용해야 한다고 명시하여 LLM이 도구를 호출하도록 유도했습니다.

## 4단계: 테스트 및 실행

이제 새로 만든 에이전트와 도구가 잘 작동하는지 테스트해볼 차례입니다.

**의존성 설치:**
만약 아직 프로젝트 의존성을 설치하지 않았다면, 프로젝트 루트에서 아래 명령어를 실행하세요.
```bash
bun install
```

**에이전트 실행:**
아래 명령어를 사용하여 `greeter` 에이전트를 실행하고, `hello` 도구를 사용해 'Jules'에게 인사하도록 요청합니다.

```bash
bun run --cwd packages/opencode --conditions=browser src/index.ts run --agent greeter "Use the hello tool to greet 'Jules'"
```

**예상 결과:**
성공적으로 실행되면, 터미널에서 다음과 같은 결과를 확인할 수 있습니다.

```
I'll use the hello tool to greet Jules.

Hello, Jules! 👋
```

이 결과는 `greeter` 에이전트가 우리의 지시를 이해하고, `hello` 도구를 정확히 호출하여 원하는 결과물을 만들어냈음을 의미합니다.

축하합니다! 이제 여러분은 OpenCode에서 자신만의 커스텀 에이전트와 도구를 만들 수 있게 되었습니다. 이 가이드를 바탕으로 더 복잡하고 유용한 기능들을 구현해 보세요.
