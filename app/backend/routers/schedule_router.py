from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from app.backend.db.database import get_session
from app.backend.db.models import Schedule
from app.backend.schemas.schedule import (
    ScheduleCreate,
    ScheduleOut,
    ScheduleListResp,
    ScheduleUpdate,
)

router = APIRouter(prefix="/schedules", tags=["schedules"])


@router.post("", response_model=ScheduleOut, status_code=201)
async def create_schedule(payload: ScheduleCreate, session: AsyncSession = Depends(get_session)):
    data = payload.model_dump(exclude_unset=True)
    cols = set(Schedule.__table__.columns.keys())
    safe = {k: v for k, v in data.items() if k in cols}
    sched = Schedule(**safe)
    session.add(sched)
    try:
        await session.commit()
    except IntegrityError:
        await session.rollback()
        raise HTTPException(status_code=409, detail="Duplicated schedule for the teacher at the same time")
    await session.refresh(sched)
    return sched


@router.get("", response_model=ScheduleListResp)
async def list_schedules(
    teacher_id: int | None = Query(None),
    date_from: str | None = Query(None),
    date_to: str | None = Query(None),
    page: int = Query(1, ge=1),
    pageSize: int = Query(50, ge=1, le=500),
    session: AsyncSession = Depends(get_session),
):
    stmt = select(Schedule)
    cnt = select(func.count()).select_from(Schedule)

    if teacher_id:
        stmt = stmt.where(Schedule.teacher_id == teacher_id)
        cnt = cnt.where(Schedule.teacher_id == teacher_id)
    if date_from:
        stmt = stmt.where(Schedule.lesson_date >= date_from)
        cnt = cnt.where(Schedule.lesson_date >= date_from)
    if date_to:
        stmt = stmt.where(Schedule.lesson_date <= date_to)
        cnt = cnt.where(Schedule.lesson_date <= date_to)

    total = (await session.execute(cnt)).scalar_one()
    rows = (
        await session.execute(
            stmt.order_by(Schedule.lesson_date.desc(), Schedule.start_time.desc())
            .offset((page - 1) * pageSize)
            .limit(pageSize)
        )
    ).scalars().all()

    return ScheduleListResp(total=total, page=page, pageSize=pageSize, items=rows)


@router.get("/{schedule_id}", response_model=ScheduleOut)
async def get_schedule(schedule_id: int, session: AsyncSession = Depends(get_session)):
    obj = await session.get(Schedule, schedule_id)
    if not obj:
        raise HTTPException(404, "Schedule not found")
    return obj


@router.patch("/{schedule_id}", response_model=ScheduleOut)
async def update_schedule(
    schedule_id: int,
    payload: ScheduleUpdate,
    session: AsyncSession = Depends(get_session),
):
    obj = await session.get(Schedule, schedule_id)
    if not obj:
        raise HTTPException(404, "Schedule not found")

    data = payload.model_dump(exclude_unset=True)
    cols = set(Schedule.__table__.columns.keys())
    for k, v in data.items():
        if k in cols:
            setattr(obj, k, v)

    await session.commit()
    await session.refresh(obj)
    return obj


@router.post("/check-conflict")
async def check_conflict(
    teacher_id: int,
    lesson_date: str,
    start_time: str,
    end_time: str,
    session: AsyncSession = Depends(get_session),
):
    stmt = select(func.count()).select_from(Schedule).where(
        and_(
            Schedule.teacher_id == teacher_id,
            Schedule.lesson_date == lesson_date,
            Schedule.start_time < end_time,
            Schedule.end_time > start_time,
        )
    )
    count = (await session.execute(stmt)).scalar_one()
    return {"conflict": count > 0, "count": count}


@router.post("/bulk-generate")
async def bulk_generate(
    teacher_id: int,
    weekday: int,  # 0=Mon ... 6=Sun
    start_time: str,
    end_time: str,
    date_from: str,
    date_to: str,
    schedule_type: str = "lesson",
    title: str | None = None,
    color: str = "#3788D8",
    session: AsyncSession = Depends(get_session),
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

    # move df to first target weekday
    cur = df
    while cur.weekday() != weekday:
        cur = cur + timedelta(days=1)

    created = 0
    while cur <= dt:
        # skip if conflict
        dup = await session.execute(
            select(func.count())
            .select_from(Schedule)
            .where(
                and_(
                    Schedule.teacher_id == teacher_id,
                    Schedule.lesson_date == cur,
                    Schedule.start_time < et,
                    Schedule.end_time > st,
                )
            )
        )
        if dup.scalar_one() == 0:
            sched = Schedule(
                teacher_id=teacher_id,
                lesson_date=cur,
                start_time=st,
                end_time=et,
                schedule_type=schedule_type,
                title=title,
                color=color,
            )
            session.add(sched)
            created += 1
        cur = cur + timedelta(days=7)

    await session.commit()
    return {"created": created}


@router.delete("/{schedule_id}", status_code=204)
async def delete_schedule(schedule_id: int, session: AsyncSession = Depends(get_session)):
    obj = await session.get(Schedule, schedule_id)
    if not obj:
        raise HTTPException(404, "Schedule not found")
    await session.delete(obj)
    await session.commit()
    return None
