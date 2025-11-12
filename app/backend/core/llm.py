# app/core/llm.py
import os
from openai import OpenAI
from app.backend.core.config import settings
import json

# === 프록시 환경 변수 강제 제거 ===
for key in list(os.environ.keys()):
    if key.lower() in ["http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY"]:
        del os.environ[key]

# === OpenAI 클라이언트 생성 (지연 초기화) ===
_llm_client: OpenAI | None = None

def get_llm_client() -> OpenAI:
    """OpenAI LLM 클라이언트를 지연 초기화"""
    global _llm_client
    if _llm_client is None:
        api_key = settings.OPENAI_API_KEY or os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY가 설정되지 않았습니다. 환경변수 또는 .env 파일에 설정하세요.")
        _llm_client = OpenAI(api_key=api_key)
    return _llm_client

# app/core/llm.py
def call_llm(messages: list, response_format=None):
    # 디버깅: messages를 안전하게 출력
    safe_messages = []
    for msg in messages:
        if 'content' in msg and isinstance(msg['content'], str) and len(msg['content']) > 500:
            safe_messages.append({**msg, "content": msg['content'][:500] + "...[truncated]"})
        else:
            safe_messages.append(msg.copy())

    kwargs = {
        "model": settings.OPENAI_MODEL,
        "messages": messages,
        "temperature": 0.0,
    }
    if response_format:
        kwargs["response_format"] = response_format

    try:
        client = get_llm_client()
        response = client.chat.completions.create(**kwargs)
        content = response.choices[0].message.content.strip()
        return content
    except Exception as e:
        print(f"[LLM ERROR] {e}")
        return "죄송해요, 다시 말씀해 주세요."