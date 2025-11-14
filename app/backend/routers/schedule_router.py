from __future__ import annotations

from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.encoders import jsonable_encoder
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


def _schedule_to_out(schedule: Schedule) -> ScheduleOut:
    data = jsonable_encoder(schedule)
    return ScheduleOut.model_validate(data)


@router.post("", response_model=ScheduleOut, status_code=201)
async def create_schedule(payload: ScheduleCreate, session: AsyncSession = Depends(get_session)):
    from datetime import datetime
    
    # 시간 파싱
    start_time_str = payload.start_time
    end_time_str = payload.end_time
    
    # 충돌 확인 (취소된 수업 제외)
    conflict_count = (
        await session.execute(
            select(func.count())
            .select_from(Schedule)
            .where(
                and_(
                    Schedule.teacher_id == payload.teacher_id,
                    Schedule.lesson_date == payload.lesson_date,
                    Schedule.status != "cancelled",  # 취소된 수업 제외
                    Schedule.start_time < end_time_str,
                    Schedule.end_time > start_time_str,
                )
            )
        )
    ).scalar_one()
    
    if conflict_count > 0:
        raise HTTPException(status_code=409, detail="해당 시간대에 이미 등록된 수업이 있습니다.")
    
    data = payload.model_dump(exclude_unset=True)
    sched = Schedule(**data)
    session.add(sched)
    try:
        await session.flush()
        await session.commit()
    except IntegrityError:
        await session.rollback()
        raise HTTPException(status_code=409, detail="Duplicated schedule for the teacher at the same time")
    await session.refresh(sched)
    return _schedule_to_out(sched)


@router.get("", response_model=ScheduleListResp)
async def list_schedules(
    teacher_id: int | None = Query(None),
    student_id: int | None = Query(None),
    subject_id: str | None = Query(None),
    status: str | None = Query(None),
    date_from: str | None = Query(None),
    date_to: str | None = Query(None),
    page: int = Query(1, ge=1),
    pageSize: int = Query(50, ge=1, le=500),
    session: AsyncSession = Depends(get_session),
):
    stmt = select(Schedule)
    cnt = select(func.count()).select_from(Schedule)

    if teacher_id is not None:
        stmt = stmt.where(Schedule.teacher_id == teacher_id)
        cnt = cnt.where(Schedule.teacher_id == teacher_id)
    if student_id is not None:
        stmt = stmt.where(Schedule.student_id == student_id)
        cnt = cnt.where(Schedule.student_id == student_id)
    if subject_id is not None:
        stmt = stmt.where(Schedule.subject_id == subject_id)
        cnt = cnt.where(Schedule.subject_id == subject_id)
    if status:
        stmt = stmt.where(Schedule.status == status)
        cnt = cnt.where(Schedule.status == status)
    if date_from:
        try:
            date_from_obj = datetime.strptime(date_from, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date_from format, expected YYYY-MM-DD")
        stmt = stmt.where(Schedule.lesson_date >= date_from_obj)
        cnt = cnt.where(Schedule.lesson_date >= date_from_obj)
    if date_to:
        try:
            date_to_obj = datetime.strptime(date_to, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date_to format, expected YYYY-MM-DD")
        stmt = stmt.where(Schedule.lesson_date <= date_to_obj)
        cnt = cnt.where(Schedule.lesson_date <= date_to_obj)

    total = (await session.execute(cnt)).scalar_one()
    rows = (
        await session.execute(
            stmt.order_by(Schedule.lesson_date.desc(), Schedule.start_time.desc())
            .offset((page - 1) * pageSize)
            .limit(pageSize)
        )
    ).scalars().all()

    items = [_schedule_to_out(row) for row in rows]
    return ScheduleListResp(total=total, page=page, pageSize=pageSize, items=items)


@router.get("/{schedule_id}", response_model=ScheduleOut)
async def get_schedule(schedule_id: int, session: AsyncSession = Depends(get_session)):
    obj = await session.get(Schedule, schedule_id)
    if not obj:
        raise HTTPException(404, "Schedule not found")
    return _schedule_to_out(obj)


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
    for k, v in data.items():
        setattr(obj, k, v)

    await session.commit()
    await session.refresh(obj)
    return _schedule_to_out(obj)


@router.post("/check-conflict")
async def check_conflict(
    teacher_id: int,
    lesson_date: str,
    start_time: str,
    end_time: str,
    session: AsyncSession = Depends(get_session),
):
    from datetime import datetime

    lesson_date_obj = datetime.strptime(lesson_date, "%Y-%m-%d").date()
    start_time_obj = datetime.strptime(start_time, "%H:%M").time()
    end_time_obj = datetime.strptime(end_time, "%H:%M").time()
    start_time_str = start_time_obj.strftime("%H:%M")
    end_time_str = end_time_obj.strftime("%H:%M")

    stmt = select(func.count()).select_from(Schedule).where(
        and_(
            Schedule.teacher_id == teacher_id,
            Schedule.lesson_date == lesson_date_obj,
            Schedule.status != "cancelled",  # 취소된 수업 제외
            Schedule.start_time < end_time_str,
            Schedule.end_time > start_time_str,
        )
    )
    count = (await session.execute(stmt)).scalar_one()
    return {"conflict": count > 0, "count": count}


@router.post("/bulk-generate")
async def bulk_generate(
    teacher_id: int,
    student_id: int,
    subject_id: str,
    weekday: int,  # 0=Mon ... 6=Sun
    start_time: str,
    end_time: str,
    date_from: str,
    date_to: str,
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
    st_str = st.strftime("%H:%M")
    et_str = et.strftime("%H:%M")

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
                    Schedule.start_time < et_str,
                    Schedule.end_time > st_str,
                )
            )
        )
        if dup.scalar_one() == 0:
            sched = Schedule(
                teacher_id=teacher_id,
                student_id=student_id,
                lesson_date=cur,
                start_time=st_str,
                end_time=et_str,
                subject_id=subject_id,
                status="confirmed",
            )
            session.add(sched)
            created += 1
        cur = cur + timedelta(days=7)

    await session.commit()
    return {"created": created}


@router.delete("/{schedule_id}", response_model=ScheduleOut)
async def delete_schedule(
    schedule_id: int,
    cancelled_by: int | None = Query(None, description="취소한 사용자 ID (teacher_id)"),
    cancel_reason: str | None = Query(None, description="취소 사유"),
    session: AsyncSession = Depends(get_session),
):
    """스케줄을 삭제하는 대신 취소 상태로 변경"""
    obj = await session.get(Schedule, schedule_id)
    if not obj:
        raise HTTPException(404, "Schedule not found")
    
    # 취소 상태로 변경
    from datetime import datetime
    obj.status = "cancelled"
    obj.cancelled_at = datetime.now()
    if cancelled_by is not None:
        obj.cancelled_by = cancelled_by
    if cancel_reason is not None:
        obj.cancel_reason = cancel_reason
    
    await session.commit()
    await session.refresh(obj)
    return _schedule_to_out(obj)
