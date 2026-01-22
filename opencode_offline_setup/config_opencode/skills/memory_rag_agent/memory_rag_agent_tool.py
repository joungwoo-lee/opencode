import os
from pathlib import Path

def load_env_file():
    # 스크립트 파일과 같은 위치의 .env 찾기
    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                if line.strip() and not line.startswith("#"):
                    key, value = line.strip().split("=", 1)
                    os.environ[key] = value.strip('"').strip("'")

load_env_file() # 함수 정의들보다 위에서 호출

# --- 여기서부터 기존 코드 시작 ---

# 사용할 도구 함수

import os, subprocess, json, tempfile, shlex
from typing import Any, Dict, List, Optional
from urllib.parse import urlparse

DEBUG = os.getenv("llmmiddleware_debug") == "1"

BASE_URL = os.getenv("RAG_BASE_URL", "http://localhost:9380").rstrip("/")
API_KEY  = os.getenv("RAG_API_KEY", "ragflow-key")
DATASET_IDS = [x.strip() for x in os.getenv("RAG_DATASET_IDS").split(",") if x.strip()]

if not API_KEY:
    raise RuntimeError("RAG_API_KEY 환경변수가 설정되지 않았습니다.")

# ✅ 하드코딩된 추가 no-proxy 목록
NO_PROXY_EXTRA_STATIC = [
    "localhost",
    "127.0.0.1",
]

def _flatten_to_dict_list(obj: Any) -> List[Dict[str, Any]]:
    result: List[Dict[str, Any]] = []
    def _walk(x: Any):
        if x is None:
            return
        if isinstance(x, dict):
            result.append(x)
        elif isinstance(x, (list, tuple)):
            for v in x:
                _walk(v)
        else:
            result.append({"content": str(x)})
    _walk(obj)
    return result

def retriever_access(
    query: str,
    top_n: int = 12,
    metadata_condition: Optional[Dict[str, Any]] = None,
    tool_context=None,
) -> Dict[str, Any]:
    if not query or not query.strip():
        raise ValueError("query는 필수입니다.")
    top_n = max(1, min(50, int(top_n)))

    user_id = "default"
    if tool_context and hasattr(tool_context, 'session') and hasattr(tool_context.session, 'user_id'):
        user_id = tool_context.session.user_id or "default"

    # 유저 아이디에서 안전하지 않은 문자 제거
    import re
    user_id = re.sub(r'[^\w\-]', '_', str(user_id))

    combined_dataset_ids = DATASET_IDS + [user_id.strip()]

    payload = {
        "question": query.strip(),
        "query": query.strip(),
        "dataset_ids": combined_dataset_ids,
        "keyword": True,
        "vector_similarity_weight": 0.0,
        "similarity_threshold": 0.0,
        "top_k": 200,
        "page": 1,
        "page_size": 100,
        "rerank_id": None,
        "metadata_condition": None,
    }

    url = f"{BASE_URL}/api/v1/retrieval"
    hdr_auth = f"Authorization: Bearer {API_KEY}"
    hdr_ct   = "Content-Type: application/json"

    body_str = json.dumps(payload, ensure_ascii=False)
    with tempfile.NamedTemporaryFile(mode="w+", encoding="utf-8", delete=False) as tf:
        tf.write(body_str)
        tf.flush()
        data_file = tf.name

    cmd = [
        "curl", "-sS",
        "-X", "POST", url,
        "-H", hdr_auth,
        "-H", hdr_ct,
        "--data-binary", f"@{data_file}",
    ]

    # === 프록시 / 노프록시 환경 구성 ===
    env = os.environ.copy()
    base_no_proxy = env.get("NO_PROXY") or env.get("no_proxy") or ""
    merged_list = [x.strip() for x in base_no_proxy.split(",") if x.strip()]

    # ✅ BASE_URL의 호스트를 자동 추가
    try:
        parsed = urlparse(BASE_URL)
        if parsed.hostname:
            merged_list.append(parsed.hostname)
    except Exception:
        pass

    # ✅ 하드코딩된 추가 no-proxy도 병합
    merged_list.extend(NO_PROXY_EXTRA_STATIC)

    merged = ",".join(sorted(set(merged_list)))
    env["NO_PROXY"] = merged
    env["no_proxy"] = merged
    # ===================================

    if DEBUG:
        print("\n=== [실행할 curl 명령] ===")
        print(" ".join(shlex.quote(c) for c in cmd))
        print("=========================\n")
        print("=== [요청 바디(JSON)] ===")
        print(body_str)
        print("=========================\n")
        print("=== [적용되는 프록시 환경] ===")
        for key in ("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY"):
            if env.get(key) or env.get(key.lower()):
                print(f"{key}={env.get(key) or env.get(key.lower())}")
        print("=========================\n")

    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, env=env, timeout=60)
    except subprocess.TimeoutExpired:
        return {
            "query": query,
            "contexts": [{
                "text": "RAGFlow 리트리벌 API 호출이 1분 타임아웃을 초과했습니다. 네트워크 상태나 서버 응답을 확인해주세요.",
                "source": {
                    "dataset_id": None,
                    "document_id": None,
                    "document_name": None,
                    "position": None,
                    "chunk_id": None,
                    "similarity": 0.0,
                    "vector_similarity": 0.0,
                    "term_similarity": 0.0,
                }
            }],
            "citations": []
        }

    if DEBUG:
        print("=== [curl STDOUT] ===")
        print(proc.stdout or "")
        print("=====================\n")

        print("=== [curl STDERR] ===")
        print(proc.stderr or "")
        print("=====================\n")

    try:
        resp = json.loads(proc.stdout or "{}")
    except json.JSONDecodeError:
        return {"query": query, "raw_output": (proc.stdout or "")}

    # API 키 에러 또는 인증 에러 처리
    # FastAPI HTTPException은 {"detail": "에러메시지"} 형태로 응답
    if "detail" in resp:
        error_message = resp.get("detail", "알 수 없는 API 에러가 발생했습니다.")
        return {
            "query": query,
            "contexts": [{
                "text": f"[API 에러] {error_message}",
                "source": {
                    "dataset_id": None,
                    "document_id": None,
                    "document_name": None,
                    "position": None,
                    "chunk_id": None,
                    "similarity": 0.0,
                    "vector_similarity": 0.0,
                    "term_similarity": 0.0,
                }
            }],
            "citations": [],
            "error": True,
            "error_message": error_message
        }
    
    # code가 0이 아닌 경우 에러 처리 (RAGFlow 스타일 에러 응답)
    if resp.get("code") and resp.get("code") != 0:
        error_message = resp.get("message", "API 요청이 실패했습니다.")
        return {
            "query": query,
            "contexts": [{
                "text": f"[API 에러] {error_message}",
                "source": {
                    "dataset_id": None,
                    "document_id": None,
                    "document_name": None,
                    "position": None,
                    "chunk_id": None,
                    "similarity": 0.0,
                    "vector_similarity": 0.0,
                    "term_similarity": 0.0,
                }
            }],
            "citations": [],
            "error": True,
            "error_message": error_message
        }

    data = resp.get("data") or {}
    items_any = data.get("items") or data.get("chunks") or data or []
    items: List[Dict[str, Any]] = _flatten_to_dict_list(items_any)

    selected = items[:top_n]

    contexts, citations = [], []
    for c in selected:
        doc_name = (c.get("document_name") or c.get("name")) if isinstance(c, dict) else None
        pos = c.get("position") if isinstance(c, dict) else None
        if pos is None and isinstance(c, dict) and isinstance(c.get("positions"), list) and c["positions"]:
            pos = c["positions"][0]
        text = c.get("content", "") if isinstance(c, dict) else str(c)

        def _f(x):
            try:
                return float(x)
            except Exception:
                return 0.0

        contexts.append({
            "text": text,
            "source": {
                "dataset_id": c.get("dataset_id") if isinstance(c, dict) else None,
                "document_id": c.get("document_id") if isinstance(c, dict) else None,
                "document_name": doc_name,
                "position": pos,
                "chunk_id": c.get("id") if isinstance(c, dict) else None,
                "similarity": _f(c.get("similarity") if isinstance(c, dict) else 0),
                "vector_similarity": _f(c.get("vector_similarity") if isinstance(c, dict) else 0),
                "term_similarity": _f(c.get("term_similarity") if isinstance(c, dict) else 0),
            }
        })
        citations.append({
            "document_name": doc_name,
            "position": pos,
            "score": _f(c.get("similarity") if isinstance(c, dict) else 0),
            "chunk_id": c.get("id") if isinstance(c, dict) else None,
        })

    return {"query": query, "contexts": contexts, "citations": citations}



# --- [OpenCode 연동을 위한 CLI 진입점] ---
import argparse, sys
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="RAGFlow Retrieval Tool for OpenCode")
    parser.add_argument("--query", type=str, required=True, help="검색 질의")
    parser.add_argument("--top_n", type=int, default=12, help="반환 결과 개수")
    
    args = parser.parse_args()

    try:
        # 환경 변수 체크 (RuntimeError 방지)
        if not os.getenv("RAG_API_KEY"):
            print(json.dumps({"error": "RAG_API_KEY 환경변수가 설정되지 않았습니다."}, ensure_ascii=False))
            sys.exit(1)

        # 함수 실행
        result = retriever_access(query=args.query, top_n=args.top_n)
        
        # OpenCode가 읽을 수 있도록 결과를 JSON 문자열로 출력
        # print(json.dumps(result, ensure_ascii=False, indent=2))
        print(json.dumps(result, ensure_ascii=False))
        
    except Exception as e:
        print(json.dumps({"error": str(e)}, ensure_ascii=False))
        sys.exit(1)