# app/services/intent_extractor.py
import json
from core.llm import call_llm
from schemas.command import ActionPlan
from core.redis import get_conversation, save_conversation, clear_conversation

SYSTEM_PROMPT = """
        You are a tutoring schedule assistant. 
        Respond **ONLY** with valid JSON **OR** a natural Korean question.

        CRITICAL RULES:
        1. NO explanations, NO markdown, NO ```json
        2. Output **exactly one of**:
        - If ALL info ready → JSON with "action", "params", and "ai_response"
        - If missing → ONLY ONE natural Korean question

        **JSON FORMAT (when action is ready)**:
        {{
            "action": "...",
            "params": {{ ... }},
            "ai_response": "친절하고 자연스러운 확인 메시지"
        }}

        ACTIONS & REQUIRED:
        - schedule_create: student_name, date, start_time, duration_minutes
        - schedule_update: student_name + date + start_time
        - schedule_cancel: same
        - schedule_list: **NO INFO NEEDED**
        - session_add: student_name, session_count
        - session_use: student_name

        **CONVERSATION HISTORY**:
        {history_contents}

        **RULES**:
        - Use entire history
        - "내일" → tomorrow (YYYY-MM-DD)
        - "오후 1시" → "13:00", "1시간반" → 90
        - **NEVER ask for known info**
        - **ai_response must include**:
        - What was done (등록/변경/취소/조회)
        - Key details (학생, 날짜, 시간)
        - Next steps (수정/추가/확인)
        - Friendly tone

        EXAMPLES (ai_response):
        - "이환주 학생 수업을 내일 오후 1시부터 1시간 30분으로 등록했어요! 구글 캘린더에도 자동 추가했어요. 변경이나 취소 필요하면 말씀해 주세요!"
        - "현재 등록된 수업이 3개 있어요. 내일 이환주 학생 오후 1시 수업 포함이에요. 더 추가할까요?"
        - "수업이 취소되었어요. 다른 시간으로 다시 잡을까요?"

        EXAMPLES (JSON):
        {{
            "action": "schedule_create",
            "params": {{
                "student_name": "이환주",
                "date": "2025-11-07",
                "start_time": "13:00",
                "duration_minutes": 90
            }},
            "ai_response": "이환주 학생 수업, 11월 7일 오후 1시부터 1시간 30분으로 등록했어요!"
        }}
        {{
            "action": "schedule_list",
            "params": {{}},
            "ai_response": "현재 등록된 수업 목록을 불러왔어요."
        }}

        EXAMPLES (자연어 질문):
        누구 수업이에요?
        몇 시에 시작하나요?
        몇 시간 수업할까요?
"""

def extract_intent_with_history(session_id: str, message: str) -> dict:
    print(f"\n[SESSION] {session_id}")
    print(f"[USER] {message}")

    history = get_conversation(session_id) or []
    print(f"[HISTORY] {len(history)} messages")

    # 사용자 메시지 추가 + 즉시 저장
    history.append({"role": "user", "content": message})
    save_conversation(session_id, history)

    # 히스토리 content만
    history_contents = "\n".join([msg["content"] for msg in history[-10:]])
    print(f"[HISTORY CONTENTS]\n{history_contents}")

    # LLM 호출
    prompt = SYSTEM_PROMPT.format(history_contents=history_contents)
    messages = [{"role": "system", "content": prompt}, {"role": "user", "content": message}]
    raw_response = call_llm(messages).strip()
    print(f"[LLM RAW] {raw_response}")

    # === 자연어 질문 ===
    if not raw_response.startswith("{"):
        question = raw_response.strip().strip('"')
        if question:
            history.append({"role": "ai", "content": question})
            save_conversation(session_id, history)
            return {"response": question}

    # === JSON 파싱 ===
    try:
        data = json.loads(raw_response)
        print(f"[PARSED] {data}")

        # action 필수
        if "action" not in data:
            fallback = "정보가 부족해요. 다시 말씀해 주세요."
            history.append({"role": "ai", "content": fallback})
            save_conversation(session_id, history)
            return {"response": fallback}

        # ai_response 필수
        ai_response = data.get("ai_response", "처리 완료!")
        if not ai_response:
            ai_response = "처리 완료!"

        # ActionPlan 생성 (action + params만)
        plan = ActionPlan(action=data["action"], params=data.get("params", {}))

        # history에 ai_response 저장
        history.append({"role": "ai", "content": ai_response})
        save_conversation(session_id, history)

        # 성공 시 히스토리 초기화
        clear_conversation(session_id)

        return {
            "action": plan.dict(),
            "ai_response": ai_response
        }

    except Exception as e:
        print(f"[ERROR] {e}")
        fallback = "죄송해요, 다시 말씀해 주세요."
        history.append({"role": "ai", "content": fallback})
        save_conversation(session_id, history)
        return {"response": fallback}