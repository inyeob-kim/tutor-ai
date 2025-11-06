# app/services/orchestra.py
from services.intent_extractor import extract_action_plan
from services.response_generator import generate_friendly_response
from services.schedule_service import create_schedule, list_schedules
from services.student_service import add_sessions, use_session
from schemas.command import ActionPlan

def process_command_with_redis(db, user_id, message, session_id):
    # 1. 의도 추출
    result = extract_action_plan(session_id, message)
    if "response" in result:
        return result  # 자연어 질문

    # 2. 액션 플랜
    plan = ActionPlan(**result["action"])

    # 3. DB 실행
    exec_result = _execute_action(db, int(user_id), plan)

    # 4. 친절한 응답 생성
    if "status" in exec_result:
        friendly = generate_friendly_response(plan, exec_result)
        return {**exec_result, "ai_response": friendly}

    return exec_result

# 내부 라우팅
def _execute_action(db, teacher_id: int, plan: ActionPlan):
    action = plan.action
    p = plan.params

    if action == "schedule_create":
        return create_schedule(db, teacher_id, p["student_name"], p["date"], p["start_time"], p["duration_minutes"])

    elif action == "schedule_list":
        return list_schedules(db, teacher_id)

    elif action == "session_add":
        return add_sessions(db, teacher_id, p["student_name"], p.get("session_count", 1))

    elif action == "session_use":
        return use_session(db, teacher_id, p["student_name"])

    else:
        return {"error": "지원하지 않는 액션"}