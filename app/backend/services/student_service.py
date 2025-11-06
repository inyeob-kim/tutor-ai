# app/services/student_service.py
from sqlalchemy.orm import Session
from models import Student
from typing import Dict

def add_sessions(db: Session, teacher_id: int, student_name: str, count: int = 1) -> Dict:
    student = _get_student(db, teacher_id, student_name)
    if not student:
        return {"error": f"'{student_name}' 학생이 없습니다."}

    student.total_sessions += count
    db.commit()

    return {
        "status": "session_added",
        "student": student_name,
        "added": count,
        "total": student.total_sessions,
        "remaining": student.remaining_sessions
    }

def use_session(db: Session, teacher_id: int, student_name: str) -> Dict:
    student = _get_student(db, teacher_id, student_name)
    if not student or student.remaining_sessions <= 0:
        return {"error": "회차 부족 또는 학생 없음"}

    student.used_sessions += 1
    db.commit()
    return {"status": "session_used", "remaining": student.remaining_sessions}

def _get_student(db: Session, teacher_id: int, name: str):
    return db.query(Student).filter(
        Student.user_id == teacher_id,
        Student.name == name
    ).first()