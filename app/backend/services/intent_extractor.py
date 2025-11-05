import json
from core.llm import call_llm
from schemas.command import ActionPlan
from pydantic import ValidationError
from datetime import datetime
from core.config import LOCAL_TZ
from core.redis import get_conversation, save_conversation
import re
from datetime import datetime, timedelta

# app/services/intent_extractor.py

SYSTEM_PROMPT = """
You are a tutoring schedule assistant. 
Respond **ONLY** with valid JSON.

CRITICAL RULES:
1. NO explanations, NO markdown
2. Output **exactly**:
   - If ALL required info available: {"action": "...", "params": { ... }}
   - If missing: {"question": "한 가지만 물어봐"}
   - If schedule_list → output immediately even if no info

ACTIONS & REQUIRED INFO:
- schedule_create: student_name, date, start_time, duration_minutes → 4개 필요
- schedule_update: student_name + date + start_time → 3개 필요
- schedule_cancel: same as update
- schedule_list: **NO INFO REQUIRED** → "이번 주", "오늘", "내일" 있어도 OK
- session_add: student_name, session_count → 2개 필요
- session_use: student_name → 1개 필요

**CURRENT STATE**:
{state_summary}

**RULES**:
- If action is schedule_list → output {"action": "schedule_list", "params": {}} immediately
- If action is schedule_create → check 4 fields
- NEVER ask for info if schedule_list

EXAMPLES:
{"action": "schedule_list", "params": {}}
{"action": "schedule_create", "params": {"student_name": "김철수", ...}}
{"question": "누구 수업이에요?"}
"""


def extract_name(text: str) -> str | None:
    match = re.search(r"([가-힣]{2,3})\s*(학생|수업|과외)", text)
    return match.group(1) if match else None

def extract_date(text: str, current: datetime) -> str | None:
    today = current.date()
    if "내일" in text: return (today + timedelta(days=1)).strftime("%Y-%m-%d")
    if "모레" in text: return (today + timedelta(days=2)).strftime("%Y-%m-%d")
    if "오늘" in text: return today.strftime("%Y-%m-%d")
    return None

def extract_time(text: str) -> str | None:
    match = re.search(r"(\d{1,2})\s*(시|시반)", text)
    if not match: return None
    hour = int(match.group(1))
    return f"{hour:02d}:30" if "시반" in text else f"{hour:02d}:00"

def extract_duration(text: str) -> int | None:
    match = re.search(r"(\d+)\s*(시간|시|분)", text)
    if not match: return None
    val = int(match.group(1))
    return val * 60 if "시간" in text or "시" in text else val

def extract_info_from_history(history):
    collected = {}
    for msg in history:
        text = msg["content"].lower()
        # 이름, 날짜, 시간, 시간 추출 (기존 함수)
        # → schedule_list에는 영향 없음
    return collected

def extract_intent_with_history(session_id: str, message: str) -> dict:
    history = get_conversation(session_id)
    history.append({"role": "user", "content": message})
    
    # 상태 추출
    collected = extract_info_from_history(history)
    state_summary = format_state(collected)
    prompt = SYSTEM_PROMPT.format(state_summary=state_summary)
    
    messages = [
        {"role": "system", "content": prompt},
        {"role": "user", "content": message}
    ]
    
    raw = call_llm(messages, response_format={"type": "json_object"})
    data = json.loads(raw)
    
    # 조회 명령 → 바로 실행
    if data.get("action") == "schedule_list":
        from core.redis import clear_conversation
        clear_conversation(session_id)
        plan = ActionPlan(action="schedule_list", params={})
        return {"type": "action", "plan": plan}
    
    # 등록/변경 → 정보 체크
    if data.get("action") == "schedule_create":
        required = ["student_name", "date", "start_time", "duration_minutes"]
        missing = [k for k in required if not collected.get(k)]
        if missing:
            question = f"{missing[0]} 알려주세요."  # 예: "누구 수업이에요?"
            save_conversation(session_id, history)
            return {"type": "question", "question": question}
    
    # 성공 → 실행
    plan = ActionPlan(**data)
    clear_conversation(session_id)
    return {"type": "action", "plan": plan}