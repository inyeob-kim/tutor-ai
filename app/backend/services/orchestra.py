# app/services/orchestra.py
from sqlalchemy.orm import Session
from models import User, Student, Schedule
from schemas.command import ActionPlan
from datetime import datetime, time
from core.config import LOCAL_TZ
from datetime import datetime, time, timedelta, date 

def execute_action_plan(db: Session, user_id: str, plan: ActionPlan):

    # 1. 선생님 존재 확인
    teacher = db.query(User).filter(User.id == int(user_id)).first()
    if not teacher:
        return {"error": "선생님 정보를 찾을 수 없음", "action": plan.action}

    # 2. 액션 분기
    if plan.action == "schedule_create":
        return _create_schedule(db, teacher, plan)
    
    elif plan.action == "schedule_update": # TODO
        return {"status": "planned", "message": "수업 변경은 추후 구현"}
    
    elif plan.action == "schedule_cancel": # TODO
        return {"status": "planned", "message": "수업 취소는 추후 구현"}
    
    elif plan.action == "schedule_list":
        return _list_schedules(db, teacher)
    
    elif plan.action == "session_add":
        return _add_sessions(db, teacher, plan)
    
    elif plan.action == "session_use":
        return _use_session(db, teacher, plan)
    
    else:
        return {"error": "지원하지 않는 액션"}

# ————————————————————————
# 내부 함수들
# ————————————————————————

def _create_schedule(db: Session, teacher, plan: ActionPlan):
    params = plan.params

    # 1. 학생 찾기
    student = db.query(Student).filter(
        Student.user_id == teacher.id,
        Student.name == params["student_name"]
    ).first()

    if not student:
        return {"error": f"'{params['student_name']}' 학생이 등록되어 있지 않습니다."}

    # 2. 회차 체크
    if student.remaining_sessions < 1:
        return {"error": f"{student.name} 학생의 회차가 부족합니다. (잔여: 0)"}

    # 시간 계산
    start_time = datetime.strptime(params["start_time"], "%H:%M").time()
    end_time = (
        datetime.combine(datetime.today(), start_time) + 
        timedelta(minutes=params["duration_minutes"])
    ).time()

    # 날짜 변환: str → date
    schedule_date = datetime.strptime(params["date"], "%Y-%m-%d").date()

    # 중복 체크
    conflict = db.query(Schedule).filter(
        Schedule.user_id == teacher.id,
        Schedule.date == schedule_date,
        Schedule.status == "confirmed",
        Schedule.start_time < end_time,
        Schedule.end_time > start_time
    ).first()

    if conflict:
        return {"error": f"{schedule_date} {start_time} ~ {end_time} 이미 수업 있음"}

    # 저장
    schedule = Schedule(
        user_id=teacher.id,
        student_id=student.id,
        date=schedule_date,           # ← date 객체!
        start_time=start_time,
        end_time=end_time,
        duration_minutes=params["duration_minutes"],
        status="confirmed"
    )
    db.add(schedule)
    db.commit()
    db.refresh(schedule)

    # 회차 차감
    student.used_sessions += 1
    db.commit()

    return {
        "status": "created",
        "schedule_id": schedule.id,
        "message": f"{student.name} 수업이 {schedule_date} {start_time}에 등록되었습니다.",
        "remaining_sessions": student.remaining_sessions
    }

def _list_schedules(db: Session, teacher):
    schedules = db.query(Schedule).filter(
        Schedule.user_id == teacher.id,
        Schedule.status == "confirmed"
    ).order_by(Schedule.date, Schedule.start_time).all()

    result = []
    for s in schedules:
        result.append({
            "date": str(s.date),
            "time": f"{s.start_time.strftime('%H:%M')} ~ {s.end_time.strftime('%H:%M')}",
            "student": s.student.name,
            "duration": s.duration_minutes
        })
    return {"schedules": result or "이번 주 수업 없음"}

def _add_sessions(db: Session, teacher, plan: ActionPlan):
    student_name = plan.params["student_name"]
    count = plan.params.get("session_count", 1)

    student = db.query(Student).filter(
        Student.user_id == teacher.id,
        Student.name == student_name
    ).first()

    if not student:
        return {"error": "학생 없음"}

    student.total_sessions += count
    db.commit()

    return {
        "status": "session_added",
        "student": student_name,
        "added": count,
        "total": student.total_sessions,
        "remaining": student.remaining_sessions
    }

def _use_session(db: Session, teacher, plan: ActionPlan):
    # 수업 끝난 후 수동 차감용
    student_name = plan.params["student_name"]
    student = db.query(Student).filter(
        Student.user_id == teacher.id,
        Student.name == student_name
    ).first()
    if not student or student.remaining_sessions <= 0:
        return {"error": "회차 부족 또는 학생 없음"}

    student.used_sessions += 1
    db.commit()
    return {"status": "session_used", "remaining": student.remaining_sessions}