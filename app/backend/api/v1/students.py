from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from ...db.database import get_session
from ...db.models import Student

router = APIRouter(prefix="/students", tags=["students"])

@router.get("/list")
async def list_students(
    q: str | None = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_session),
):
    stmt = select(Student)
    if q:
        stmt = stmt.where(Student.name.ilike(f"%{q}%"))
    stmt = stmt.order_by(Student.name).limit(size).offset((page-1)*size)
    rows = (await db.execute(stmt)).scalars().all()
    return {"items": [{
        "student_id": s.student_id,
        "name": s.name,
        "phone": s.phone,
        "parent_phone": s.parent_phone,
        "school": s.school,
        "grade": s.grade,
        "subject": s.subject,
        "start_date": s.start_date,
        "lesson_day": s.lesson_day,
        "lesson_time": s.lesson_time,
        "hourly_rate": s.hourly_rate,
        "notes": s.notes,
        "is_active": s.is_active,
        "created_at": s.created_at,
        "updated_at": s.updated_at,
    } for s in rows], "page": page, "size": size}
