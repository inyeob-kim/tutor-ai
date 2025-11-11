from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ...db.database import get_session
from ...db.models import Schedule

router = APIRouter(prefix="/schedules", tags=["schedules"])


@router.get("/list")
async def list_schedules(
    teacher_id: int | None = Query(None),
    date_from: str | None = Query(None),
    date_to: str | None = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=500),
    db: AsyncSession = Depends(get_session),
):
    stmt = select(Schedule)
    if teacher_id:
        stmt = stmt.where(Schedule.teacher_id == teacher_id)
    if date_from:
        stmt = stmt.where(Schedule.lesson_date >= date_from)
    if date_to:
        stmt = stmt.where(Schedule.lesson_date <= date_to)
    stmt = stmt.order_by(Schedule.lesson_date.desc(), Schedule.start_time.desc()).limit(size).offset((page - 1) * size)
    rows = (await db.execute(stmt)).scalars().all()
    return {
        "items": [
            {
                "schedule_id": s.schedule_id,
                "teacher_id": s.teacher_id,
                "lesson_date": s.lesson_date,
                "start_time": s.start_time,
                "end_time": s.end_time,
                "student_id": s.student_id,
                "schedule_type": s.schedule_type,
                "title": s.title,
                "notes": s.notes,
                "color": s.color,
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
        "lesson_date": s.lesson_date,
        "start_time": s.start_time,
        "end_time": s.end_time,
        "student_id": s.student_id,
        "schedule_type": s.schedule_type,
        "title": s.title,
        "notes": s.notes,
        "color": s.color,
        "created_at": s.created_at,
        "updated_at": s.updated_at,
    }


@router.post("/check-conflict")
async def check_conflict(
    teacher_id: int,
    lesson_date: str,
    start_time: str,
    end_time: str,
    db: AsyncSession = Depends(get_session),
):
    from sqlalchemy import and_, func
    count = (await db.execute(
        select(func.count()).select_from(Schedule).where(
            and_(
                Schedule.teacher_id == teacher_id,
                Schedule.lesson_date == lesson_date,
                Schedule.start_time < end_time,
                Schedule.end_time > start_time,
            )
        )
    )).scalar_one()
    return {"conflict": count > 0, "count": count}


@router.post("/bulk-generate")
async def bulk_generate(
    teacher_id: int,
    weekday: int,
    start_time: str,
    end_time: str,
    date_from: str,
    date_to: str,
    schedule_type: str = "lesson",
    title: str | None = None,
    color: str = "#3788D8",
    db: AsyncSession = Depends(get_session),
):
    from datetime import datetime, timedelta
    def parse_date(s: str):
        return datetime.strptime(s, "%Y-%m-%d").date()
    def parse_time(s: str):
        return datetime.strptime(s, "%H:%M").time()
    df = parse_date(date_from)
    dt = parse_date(date_to)
    st = parse_time(start_time)
    et = parse_time(end_time)
    cur = df
    while cur.weekday() != weekday:
        cur = cur + timedelta(days=1)
    created = 0
    while cur <= dt:
        exists = (await db.execute(
            select(func.count()).select_from(Schedule).where(
                (Schedule.teacher_id == teacher_id) &
                (Schedule.lesson_date == cur) &
                (Schedule.start_time < et) &
                (Schedule.end_time > st)
            )
        )).scalar_one()
        if not exists:
            db.add(Schedule(
                teacher_id=teacher_id,
                lesson_date=cur,
                start_time=st,
                end_time=et,
                schedule_type=schedule_type,
                title=title,
                color=color,
            ))
            created += 1
        cur = cur + timedelta(days=7)
    await db.commit()
    return {"created": created}
