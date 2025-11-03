import json
import logging

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
)

def safe_json_loads(text: str, fallback=None):
    """Gemini JSON 응답이 깨졌을 때 복구용"""
    try:
        # markdown JSON fence 제거
        cleaned = text.replace("```json", "").replace("```", "").strip()
        return json.loads(cleaned)
    except Exception as e:
        logging.error(f"JSON Parsing failed: {e} / raw={text}")
        return fallback
