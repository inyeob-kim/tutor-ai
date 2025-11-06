# app/services/schedule_service.py
from sqlalchemy.orm import Session
from models import Schedule, Student
from datetime import datetime, time, timedelta
from typing import List, Dict

# ==============================
# CREATE
# ==============================
def create_schedule(
    db: Session,
    teacher_id: int,
    student_name: str,
    date_str: str,
    start_time_str: str,
    duration_minutes: int
) -> Dict:
    student = _get_student(db, teacher_id, student_name)
    if not student:
        return {"error": f"'{student_name}' 학생이 등록되어 있지 않습니다."}

    if student.remaining_sessions < 1:
        return {"error": f"{student.name} 학생의 회차가 부족합니다. (잔여: 0)"}

    start_time, end_time = _parse_time(start_time_str, duration_minutes)
    schedule_date = datetime.strptime(date_str, "%Y-%m-%d").date()

    if _has_conflict(db, teacher_id, schedule_date, start_time, end_time):
        return {"error": f"{schedule_date} {start_time} ~ {end_time} 이미 수업 있음"}

    schedule = Schedule(
        user_id=teacher_id,
        student_id=student.id,
        date=schedule_date,
        start_time=start_time,
        end_time=end_time,
        duration_minutes=duration_minutes,
        status="confirmed"
    )
    db.add(schedule)
    db.commit()
    db.refresh(schedule)

    student.used_sessions += 1
    db.commit()

    return {
        "status": "created",
        "schedule_id": schedule.id,
        "remaining_sessions": student.remaining_sessions
    }

# ==============================
# LIST
# ==============================
def list_schedules(db: Session, teacher_id: int) -> Dict:
    schedules = db.query(Schedule).filter(
        Schedule.user_id == teacher_id,
        Schedule.status == "confirmed"
    ).order_by(Schedule.date, Schedule.start_time).all()

    result = [
        {
            "date": str(s.date),
            "time": f"{s.start_time.strftime('%H:%M')} ~ {s.end_time.strftime('%H:%M')}",
            "student": s.student.name,
            "duration": s.duration_minutes
        }
        for s in schedules
    ]
    return {"schedules": result or "이번 주 수업 없음"}

# ==============================
# UPDATE (미구현 → 나중에 추가)
# ==============================
def update_schedule(): ...

# ==============================
# CANCEL
# ==============================
def cancel_schedule(): ...

# ==============================
# 내부 헬퍼 함수
# ==============================
def _get_student(db: Session, teacher_id: int, name: str) -> Student:
    return db.query(Student).filter(
        Student.user_id == teacher_id,
        Student.name == name
    ).first()

def _parse_time(start_str: str, duration: int):
    start = datetime.strptime(start_str, "%H:%M").time()
    end = (datetime.combine(datetime.today(), start) + timedelta(minutes=duration)).time()
    return start, end

def _has_conflict(db: Session, teacher_id: int, date, start, end):
    return db.query(Schedule).filter(
        Schedule.user_id == teacher_id,
        Schedule.date == date,
        Schedule.status == "confirmed",
        Schedule.start_time < end,
        Schedule.end_time > start
    ).first() is not None