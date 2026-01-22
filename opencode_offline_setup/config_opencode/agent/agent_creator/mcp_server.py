import os
import sys
from typing import List
from mcp.server.fastmcp import FastMCP

# MCP 서버 초기화
mcp = FastMCP("Agent Config Generator")

# 에이전트 파일이 저장될 경로
# 사용자가 .config/opencode 폴더를 사용한다고 가정합니다.
AGENT_DIR = os.path.expanduser("~/.config/opencode/agent")

def ensure_directory():
    """에이전트 설정 디렉토리가 없으면 생성합니다."""
    if not os.path.exists(AGENT_DIR):
        os.makedirs(AGENT_DIR)

@mcp.tool()
def generate_agent_config(
    name: str,
    description: str,
    prompt: str,
    permissions: List[str] = ["read"]
) -> str:
    """
    OpenCode 에이전트 설정 파일(.md)을 생성합니다.
    
    Args:
        name: 에이전트 이름 (파일로 저장될 영문 ID, 예: 'code-reviewer')
        description: 에이전트의 역할과 사용 시점에 대한 설명
        prompt: 에이전트의 시스템 프롬프트 본문
        permissions: 허용할 툴 권한 목록 (예: ['read', 'websearch'])
    """
    
    # 1. 디렉토리 확인
    ensure_directory()
    
    # 2. 파일명 안전성 검사
    safe_name = "".join(c for c in name if c.isalnum() or c in ('-', '_')).lower()
    if not safe_name:
        return "Error: 유효하지 않은 에이전트 이름입니다."
        
    file_path = os.path.join(AGENT_DIR, f"{safe_name}.md")
    
    # 3. 권한 설정 블록 생성
    perm_block = ""
    for perm in permissions:
        perm_block += f"  {perm}: allow\n"
        
    # 4. 마크다운 내용 구성
    # Frontmatter 포맷을 준수하여 작성합니다.
    content = f"""---
name: {safe_name}
description: "{description}"
mode: primary
permission:
{perm_block}---

{prompt}
"""

    # 5. 파일 쓰기
    try:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        return f"Successfully created agent config at: {file_path}\n\nContent:\n{content}"
    except Exception as e:
        return f"Error creating file: {str(e)}"

if __name__ == "__main__":
    # MCP 서버 실행
    mcp.run()
