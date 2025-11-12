# app/services/response_generator.py
from app.backend.schemas.command import ActionPlan
from typing import Dict

def generate_friendly_response(plan: ActionPlan, exec_result: Dict) -> str:
    """액션 실행 결과를 바탕으로 친절한 응답 생성"""
    action = plan.action
    params = plan.params
    
    if action == "schedule_create":
        if "status" in exec_result and exec_result["status"] == "created":
            student_name = params.get("student_name", "")
            date = params.get("date", "")
            start_time = params.get("start_time", "")
            return f"{student_name} 학생 수업을 {date} {start_time}에 등록했어요!"
        return exec_result.get("error", "수업 등록 중 오류가 발생했어요.")
    
    elif action == "schedule_list":
        schedules = exec_result.get("schedules", [])
        if isinstance(schedules, list) and schedules:
            return f"현재 등록된 수업이 {len(schedules)}개 있어요."
        return "등록된 수업이 없어요."
    
    elif action == "session_add":
        if "status" in exec_result:
            student_name = params.get("student_name", "")
            count = params.get("session_count", 1)
            return f"{student_name} 학생에게 {count}회차를 추가했어요."
        return exec_result.get("error", "회차 추가 중 오류가 발생했어요.")
    
    elif action == "session_use":
        if "status" in exec_result:
            student_name = params.get("student_name", "")
            return f"{student_name} 학생의 회차를 사용했어요."
        return exec_result.get("error", "회차 사용 중 오류가 발생했어요.")
    
    return "처리 완료!"

