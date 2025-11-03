# app/backend/services/gemini_service.py
import os
import json
import logging
from typing import Dict, Any
from dotenv import load_dotenv
import google.generativeai as genai

from schemas.scheduling_schema import ParsedIntentList, Intent

load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# 사용 가능한 실제 모델 (사용자 환경에서 list_models로 확인됨)
# 예: models/gemini-2.5-flash  또는 models/gemini-flash-latest
_MODEL_NAME = os.getenv("GEMINI_MODEL", "models/gemini-2.5-flash")
_model = genai.GenerativeModel(_MODEL_NAME)

_PROMPT = """
당신은 '과외 선생님 개인 비서 AI' 입니다.
사용자의 한국어 명령에는 여러 의도가 동시에 포함될 수 있습니다.
반드시 아래 JSON 스키마로만 출력하세요. 한국어 값을 사용하되, key는 영어로 고정합니다.

출력 스키마(JSON ONLY):
{
  "intents": [
    {
      "type": "스케줄 확인" | "스케줄 변경" | "메시지 전송" | "이메일 전송",
      "student": "학생 이름 또는 null",
      "channel": "카카오톡|이메일|문자 등 또는 null",
      "message": "보낼 메시지 초안 또는 null",
      "time_pref": "원하는 시간대(예: 다음주 저녁) 또는 null"
    }
  ]
}

주의:
- 반드시 위 JSON 형식만 출력(설명, 코드블럭, 다른 텍스트 금지)
- 값은 한국어, key는 영어
- 명령에 의도가 1개면 배열에 1개만 포함
- 명령에서 추론 가능한 값만 넣고, 없으면 null
"""

def _clean_json_text(text: str) -> str:
    t = text.strip()
    t = t.replace("```json", "").replace("```", "").strip()
    return t

def parse_command(command: str) -> ParsedIntentList:
    """
    LLM에게서 복합 의도 배열을 추출하여 ParsedIntentList로 반환.
    실패 시 안전한 기본값 반환.
    """
    try:
        prompt = _PROMPT + f'\n\n사용자 명령: "{command}"\n'
        resp = _model.generate_content(prompt)
        raw = _clean_json_text(resp.text or "")

        data: Dict[str, Any] = json.loads(raw)
        intents_data = data.get("intents", [])
        intents = [Intent(**i) for i in intents_data if isinstance(i, dict)]
        if not intents:
            intents = [Intent(type="스케줄 확인")]  # 안전 기본값

        return ParsedIntentList(intents=intents)

    except Exception as e:
        logging.error(f"[Gemini] parse_command error: {e}")
        # 오류 시 안전 기본값
        return ParsedIntentList(intents=[Intent(type="스케줄 확인")])
