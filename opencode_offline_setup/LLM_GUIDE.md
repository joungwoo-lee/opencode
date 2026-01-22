# OpenCode Custom Agent & Tool Creation Guide for LLMs

This document is a guideline for Large Language Models (LLMs) to generate Custom Agents and Tools for the OpenCode platform. When a user asks to "create a new agent" or "add a custom tool," follow these instructions to generate the necessary files.

## 1. Overview & Directory Structure

OpenCode extends its capabilities through **Agents** (defined in Markdown) and **Tools** (implemented via MCP servers).

When generating code, assume the following standard directory structure for the user's configuration:

```
~/.config/opencode/
├── agent/
│   └── {agent_name}/
│       ├── {agent_name}.md      # Agent Definition
│       ├── mcp_server.py        # Custom Tool Logic (Python MCP)
│       └── README.md            # Instructions
└── opencode.json                # Registration & Permissions
```

---

## 2. Step-by-Step Generation Guide

### Step 1: Agent Definition (`{agent_name}.md`)

Create a Markdown file with YAML Frontmatter. This file defines the agent's identity, behavior, and permissions.

**File Path:** `~/.config/opencode/agent/{agent_name}/{agent_name}.md`

**Format:**
```markdown
---
name: {agent-id}
description: "{Trigger description: When should the orchestrator call this agent?}"
mode: primary
permission:
  {tool_name}: allow
  read: allow
---

{System Prompt: Define persona, tone, and instructions here.}
```

**Key Rules:**
- **name**: Lowercase, kebab-case (e.g., `code-reviewer`, `weather-bot`).
- **description**: **CRITICAL**. This natural language description determines *when* the agent is called. Be specific (e.g., "Use this agent when the user asks to review Python code for security issues").
- **permission**: List all tools this agent needs. Standard tools include `read`, `edit`, `websearch`. Custom tools defined in Step 2 must be explicitly allowed here.
- **model**: Do NOT specify a model unless requested. Let it inherit the system default.

### Step 2: Custom Tool Implementation (`mcp_server.py`)

If the agent needs capabilities not provided by default (e.g., API calls, complex logic), generate a Python script using the Model Context Protocol (MCP).

**File Path:** `~/.config/opencode/agent/{agent_name}/mcp_server.py`

**Template:**
```python
import os
from mcp.server.fastmcp import FastMCP

# Initialize Server
mcp = FastMCP("{Agent Name} Tools")

@mcp.tool()
def {tool_name}(arg1: str, arg2: int) -> str:
    """
    {Docstring is MANDATORY. It becomes the tool description for the LLM.}
    Args:
        arg1: Description of arg1
    """
    # Implementation logic
    return "Result string"

if __name__ == "__main__":
    mcp.run()
```

**Key Rules:**
- Use `mcp` library (install via `pip install mcp`).
- Use type hints (`str`, `int`, etc.) for all arguments.
- Write clear docstrings. The agent uses these to understand how to use the tool.

### Step 3: Configuration (`opencode.json`)

To activate the tool and agent, they must be registered in the global configuration file.

**Template:**
```json
{
  "mcp": {
    "{agent-id}-server": {
      "type": "local",
      "command": ["python", "{env:HOME}/.config/opencode/agent/{agent_name}/mcp_server.py"],
      "enabled": true
    }
  },
  "agent": {
    "{agent-id}": {
      "permission": {
        "{tool_name}": "allow"
      }
    }
  }
}
```

---

## 3. Example Generation

**User Request:**
"Make a 'weather-bot' agent that can check the weather using a Python script."

**LLM Output:**

#### 1. Agent Definition (`weather-bot.md`)
```markdown
---
name: weather-bot
description: "Use this agent when the user asks for current weather information."
mode: primary
permission:
  get_weather: allow
---

You are a helpful weather assistant. When a user asks for weather, use the `get_weather` tool.
Always answer politely and include emojis.
```

#### 2. Tool Implementation (`mcp_server.py`)
```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Weather Tools")

@mcp.tool()
def get_weather(city: str) -> str:
    """
    Get the current weather for a specific city.
    """
    # In a real scenario, call an external API here.
    return f"The weather in {city} is Sunny, 25°C."

if __name__ == "__main__":
    mcp.run()
```

#### 3. Config Snippet (`opencode.json`)
```json
{
  "mcp": {
    "weather-server": {
      "type": "local",
      "command": ["python", "{env:HOME}/.config/opencode/agent/weather-bot/mcp_server.py"],
      "enabled": true
    }
  },
  "agent": {
    "weather-bot": {
      "permission": {
        "get_weather": "allow"
      }
    }
  }
}
```
