import json
from core.llm import call_llm
from schemas.command import ActionPlan
from pydantic import ValidationError
from datetime import datetime
from core.config import LOCAL_TZ

# app/services/intent_extractor.py

SYSTEM_PROMPT = """
        You are a tutoring schedule assistant. 
        Respond **ONLY** with valid JSON — nothing else.

        CRITICAL RULES:
        1. NO explanations, NO markdown, NO ```json, NO extra text
        2. Output **exactly** this JSON structure:
        {
            "action": "...",
            "params": { ... }
        }
        3. The value of "action" **MUST BE ONE OF THESE EXACT STRINGS ONLY**:
        - schedule_create
        - schedule_update
        - schedule_cancel
        - schedule_list
        - session_use
        - session_add
        4. **DO NOT invent new action names** — even if the user says "add", "new", "book", etc.
        → Always use `schedule_create` for creating a new lesson
        → Always use `session_add` for adding session credits
        5. Date format: YYYY-MM-DD
        6. Time format: HH:MM (24-hour)

        EXAMPLES:
        {
        "action": "schedule_create",
        "params": {
            "student_name": "김철수",
            "date": "2025-11-06",
            "start_time": "15:00",
            "duration_minutes": 60
        }
        }

        {
        "action": "session_add",
        "params": {
            "student_name": "김철수",
            "session_count": 5
        }
        }

        **ANY DEVIATION FROM THESE RULES WILL BREAK THE SYSTEM.**
"""

def extract_intent(user_id: str, message: str) -> ActionPlan:
    
    current_time = datetime.now(LOCAL_TZ).strftime("%Y-%m-%d %H:%M KST")

    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {
            "role": "user",
            "content": f"[Current Time: {current_time}]\nMessage: {message}"
        }
    ]

    raw_json = call_llm(messages, response_format={"type": "json_object"})

    print("GPT response > raw_json = ", raw_json)
    
    try:
        data = json.loads(raw_json)
        return ActionPlan(**data)
    except (json.JSONDecodeError, ValidationError) as e:
        raise ValueError(f"LLM JSON 파싱 실패: {e}\n원본: {raw_json}")