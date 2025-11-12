from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ...db.database import get_session
from ...db.models import Teacher

router = APIRouter(prefix="/teachers", tags=["teachers"])


@router.get("/list")
async def list_teachers(
    q: str | None = Query(None),
    subject_id: str | None = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_session),
):
    stmt = select(Teacher)
    if q:
        like = f"%{q}%"
        stmt = stmt.where((Teacher.name.ilike(like)) | (Teacher.phone.ilike(like)))
    if subject_id is not None:
        stmt = stmt.where(Teacher.subject_id == subject_id)
    stmt = stmt.order_by(Teacher.created_at.desc()).limit(size).offset((page - 1) * size)
    rows = (await db.execute(stmt)).scalars().all()
    return {
        "items": [
            {
                "teacher_id": t.teacher_id,
                "name": t.name,
                "phone": t.phone,
                "email": t.email,
                "subject_id": t.subject_id,
                "bank_name": t.bank_name,
                "account_number": t.account_number,
                "tax_type": t.tax_type,
                "hourly_rate_min": t.hourly_rate_min,
                "hourly_rate_max": t.hourly_rate_max,
                "available_days": t.available_days,
                "available_time": t.available_time,
                "vacation_start": t.vacation_start,
                "vacation_end": t.vacation_end,
                "total_students": t.total_students,
                "monthly_income": t.monthly_income,
                "notes": t.notes,
                "created_at": t.created_at,
                "updated_at": t.updated_at,
            }
            for t in rows
        ],
        "page": page,
        "size": size,
    }


@router.get("/{teacher_id}")
async def get_teacher(teacher_id: int, db: AsyncSession = Depends(get_session)):
    teacher = await db.get(Teacher, teacher_id)
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return {
        "teacher_id": teacher.teacher_id,
        "name": teacher.name,
        "phone": teacher.phone,
        "email": teacher.email,
        "subject_id": teacher.subject_id,
        "bank_name": teacher.bank_name,
        "account_number": teacher.account_number,
        "tax_type": teacher.tax_type,
        "hourly_rate_min": teacher.hourly_rate_min,
        "hourly_rate_max": teacher.hourly_rate_max,
        "available_days": teacher.available_days,
        "available_time": teacher.available_time,
        "vacation_start": teacher.vacation_start,
        "vacation_end": teacher.vacation_end,
        "total_students": teacher.total_students,
        "monthly_income": teacher.monthly_income,
        "notes": teacher.notes,
        "created_at": teacher.created_at,
        "updated_at": teacher.updated_at,
    }
