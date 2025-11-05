# app/core/llm.py
import os
from openai import OpenAI
from core.config import settings

# === 프록시 환경 변수 강제 제거 (모든 형태) ===
for key in list(os.environ.keys()):
    if key.lower() in ["http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY"]:
        del os.environ[key]

# === OpenAI 클라이언트 생성 ===
client = OpenAI(
    api_key=settings.OPENAI_API_KEY,
)

def call_llm(messages: list, response_format=None):
    response = client.chat.completions.create(
        model=settings.OPENAI_MODEL,
        messages=messages,
        temperature=0.0,
        response_format=response_format,
    )
    return response.choices[0].message.content.strip()