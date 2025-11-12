from __future__ import annotations

from datetime import datetime, timedelta, date, time
from typing import Optional

from fastapi import APIRouter, Body, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import and_, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from ...db.database import get_session
from ...db.models import Schedule

router = APIRouter(prefix="/schedules", tags=["schedules"])


class ScheduleCreate(BaseModel):
    teacher_id: int = Field(..., description="교사 ID")
    student_id: int = Field(..., description="학생 ID")
    subject_id: int = Field(..., description="과목 ID")
    lesson_date: str = Field(..., pattern=r"^\d{4}-\d{2}-\d{2}$")
    start_time: str = Field(..., pattern=r"^\d{2}:\d{2}$")
    end_time: str = Field(..., pattern=r"^\d{2}:\d{2}$")
    status: str = Field(default="confirmed")
    notes: Optional[str] = None
    cancelled_at: Optional[str] = Field(None, description="ISO 포맷")
    cancelled_by: Optional[int] = None
    cancel_reason: Optional[str] = None


def _parse_time_window(payload: ScheduleCreate) -> tuple[date, time, time]:
    lesson_date = datetime.strptime(payload.lesson_date, "%Y-%m-%d").date()
    start_time = datetime.strptime(payload.start_time, "%H:%M").time()
    end_time = datetime.strptime(payload.end_time, "%H:%M").time()
    if start_time >= end_time:
        raise HTTPException(status_code=400, detail="End time must be after start time")
    return lesson_date, start_time, end_time


@router.post("", status_code=201)
async def create_schedule(
    payload: ScheduleCreate,
    db: AsyncSession = Depends(get_session),
):
    lesson_date, start_time_obj, end_time_obj = _parse_time_window(payload)
    start_time_str = start_time_obj.strftime("%H:%M")
    end_time_str = end_time_obj.strftime("%H:%M")

    # 충돌 확인
    conflict_count = (
        await db.execute(
            select(func.count())
            .select_from(Schedule)
            .where(
                and_(
                    Schedule.teacher_id == payload.teacher_id,
                    Schedule.lesson_date == lesson_date,
                    Schedule.start_time < end_time_str,
                    Schedule.end_time > start_time_str,
                )
            )
        )
    ).scalar_one()

    if conflict_count > 0:
        raise HTTPException(status_code=409, detail="Schedule conflict detected")

    if payload.cancelled_at:
        try:
            cancelled_at = datetime.fromisoformat(payload.cancelled_at)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid cancelled_at format, expected ISO format")
    else:
        cancelled_at = None

    schedule = Schedule(
        teacher_id=payload.teacher_id,
        student_id=payload.student_id,
        subject_id=payload.subject_id,
        lesson_date=lesson_date,
        start_time=start_time_str,
        end_time=end_time_str,
        notes=payload.notes,
        status=payload.status,
        cancelled_at=cancelled_at,
        cancelled_by=payload.cancelled_by,
        cancel_reason=payload.cancel_reason,
    )

    db.add(schedule)
    await db.commit()
    await db.refresh(schedule)

    return {
        "schedule_id": schedule.schedule_id,
        "teacher_id": schedule.teacher_id,
        "student_id": schedule.student_id,
        "subject_id": schedule.subject_id,
        "lesson_date": schedule.lesson_date,
        "start_time": schedule.start_time,
        "end_time": schedule.end_time,
        "status": schedule.status,
        "notes": schedule.notes,
        "cancelled_at": schedule.cancelled_at,
        "cancelled_by": schedule.cancelled_by,
        "cancel_reason": schedule.cancel_reason,
        "created_at": schedule.created_at,
        "updated_at": schedule.updated_at,
    }


@router.get("/list")
async def list_schedules(
    teacher_id: int | None = Query(None),
    student_id: int | None = Query(None),
    subject_id: int | None = Query(None),
    status: str | None = Query(None),
    date_from: str | None = Query(None),
    date_to: str | None = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=500),
    db: AsyncSession = Depends(get_session),
):
    stmt = select(Schedule)
    if teacher_id is not None:
        stmt = stmt.where(Schedule.teacher_id == teacher_id)
    if student_id is not None:
        stmt = stmt.where(Schedule.student_id == student_id)
    if subject_id is not None:
        stmt = stmt.where(Schedule.subject_id == subject_id)
    if status:
        stmt = stmt.where(Schedule.status == status)
    if date_from:
        try:
            date_from_obj = datetime.strptime(date_from, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date_from format, expected YYYY-MM-DD")
        stmt = stmt.where(Schedule.lesson_date >= date_from_obj)
    if date_to:
        try:
            date_to_obj = datetime.strptime(date_to, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date_to format, expected YYYY-MM-DD")
        stmt = stmt.where(Schedule.lesson_date <= date_to_obj)

    stmt = stmt.order_by(Schedule.lesson_date.desc(), Schedule.start_time.desc()).limit(size).offset((page - 1) * size)
    rows = (await db.execute(stmt)).scalars().all()
    return {
        "items": [
            {
                "schedule_id": s.schedule_id,
                "teacher_id": s.teacher_id,
                "student_id": s.student_id,
                "subject_id": s.subject_id,
                "lesson_date": s.lesson_date,
                "start_time": s.start_time,
                "end_time": s.end_time,
                "status": s.status,
                "notes": s.notes,
                "cancelled_at": s.cancelled_at,
                "cancelled_by": s.cancelled_by,
                "cancel_reason": s.cancel_reason,
                "created_at": s.created_at,
                "updated_at": s.updated_at,
            }
            for s in rows
        ],
        "page": page,
        "size": size,
    }


@router.get("/{schedule_id}")
async def get_schedule(schedule_id: int, db: AsyncSession = Depends(get_session)):
    s = await db.get(Schedule, schedule_id)
    if not s:
        raise HTTPException(status_code=404, detail="Schedule not found")
    return {
        "schedule_id": s.schedule_id,
        "teacher_id": s.teacher_id,
        "student_id": s.student_id,
        "subject_id": s.subject_id,
        "lesson_date": s.lesson_date,
        "start_time": s.start_time,
        "end_time": s.end_time,
        "status": s.status,
        "notes": s.notes,
        "cancelled_at": s.cancelled_at,
        "cancelled_by": s.cancelled_by,
        "cancel_reason": s.cancel_reason,
        "created_at": s.created_at,
        "updated_at": s.updated_at,
    }


@router.post("/check-conflict")
async def check_conflict(
    teacher_id: int = Body(...),
    lesson_date: str = Body(...),
    start_time: str = Body(...),
    end_time: str = Body(...),
    db: AsyncSession = Depends(get_session),
):
    lesson_date_obj = datetime.strptime(lesson_date, "%Y-%m-%d").date()
    start_time_obj = datetime.strptime(start_time, "%H:%M").time()
    end_time_obj = datetime.strptime(end_time, "%H:%M").time()
    start_time_str = start_time_obj.strftime("%H:%M")
    end_time_str = end_time_obj.strftime("%H:%M")

    count = (
        await db.execute(
            select(func.count()).select_from(Schedule).where(
                and_(
                    Schedule.teacher_id == teacher_id,
                    Schedule.lesson_date == lesson_date_obj,
                    Schedule.start_time < end_time_str,
                    Schedule.end_time > start_time_str,
                )
            )
        )
    ).scalar_one()
    return {"conflict": count > 0, "count": count}


@router.post("/bulk-generate")
async def bulk_generate(
    teacher_id: int,
    student_id: int,
    subject_id: int,
    weekday: int,
    start_time: str,
    end_time: str,
    date_from: str,
    date_to: str,
    status: str = "confirmed",
    notes: str | None = None,
    db: AsyncSession = Depends(get_session),
):
    def parse_date(s: str):
        return datetime.strptime(s, "%Y-%m-%d").date()

    def parse_time(s: str):
        return datetime.strptime(s, "%H:%M").time()

    df = parse_date(date_from)
    dt = parse_date(date_to)
    st = parse_time(start_time)
    et = parse_time(end_time)
    st_str = st.strftime("%H:%M")
    et_str = et.strftime("%H:%M")

    cur = df
    while cur.weekday() != weekday:
        cur = cur + timedelta(days=1)

    created = 0
    while cur <= dt:
        exists = (
            await db.execute(
                select(func.count())
                .select_from(Schedule)
                .where(
                    (Schedule.teacher_id == teacher_id)
                    & (Schedule.lesson_date == cur)
                    & (Schedule.start_time < et_str)
                    & (Schedule.end_time > st_str)
                )
            )
        ).scalar_one()
        if not exists:
            db.add(
                Schedule(
                    teacher_id=teacher_id,
                    student_id=student_id,
                    subject_id=subject_id,
                    lesson_date=cur,
                    start_time=st_str,
                    end_time=et_str,
                    status=status,
                    notes=notes,
                )
            )
            created += 1
        cur = cur + timedelta(days=7)
    await db.commit()
    return {"created": created}
