from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import date, datetime, timedelta, time as dtime, timezone
from ...db.database import get_db
from ...models.course import Course
from ...models.student import Student
from ...models.session import Session

router = APIRouter(prefix="/courses", tags=["courses"])

@router.post("")
async def create_course(payload: dict, db: AsyncSession = Depends(get_db)):
    student_id = payload.get("student_id")
    if not student_id:
        raise HTTPException(400, "student_id required")
    exists = await db.scalar(select(Student.id).where(Student.id == student_id))
    if not exists:
        raise HTTPException(404, "student not found")

    course = Course(
        student_id=student_id,
        subject=payload.get("subject", "수업"),
        default_duration_min=payload.get("default_duration_min", 60),
        location_mode=payload.get("location", {}).get("mode", "online"),
        location_place=payload.get("location", {}).get("place"),
        rate_type=payload.get("rate", {}).get("type", "hourly"),
        rate_amount=payload.get("rate", {}).get("amount", 0),
        recurrence_kind=(payload.get("recurrence") or {}).get("kind"),
        recurrence_weekday=(payload.get("recurrence") or {}).get("weekday"),
        recurrence_start_time=(payload.get("recurrence") or {}).get("start_time"),
    )
    db.add(course)
    await db.commit()
    await db.refresh(course)
    return {"id": course.id}

@router.post("/{course_id}:generate-sessions")
async def generate_sessions(course_id: int, body: dict = Body(...), db: AsyncSession = Depends(get_db)):
    course = await db.get(Course, course_id)
    if not course or not course.recurrence_kind:
        raise HTTPException(404, "course not found or no recurrence")
    count = int(body.get("count", 8))
    weekday = course.recurrence_weekday or 0
    from datetime import date
    cur = date.today()
    while cur.weekday() != weekday:
        cur = cur + timedelta(days=1)
    duration = timedelta(minutes=course.default_duration_min)
    created = 0
    for i in range(count):
        hh, mm = (course.recurrence_start_time or "19:00").split(":")
        start_at = datetime(cur.year, cur.month, cur.day, int(hh), int(mm), tzinfo=timezone.utc)
        end_at = start_at + duration
        sess = Session(
            course_id=course.id,
            student_id=course.student_id,
            subject=course.subject,
            start_at=start_at,
            end_at=end_at,
            location_mode=course.location_mode,
            location_place=course.location_place,
        )
        db.add(sess)
        created += 1
        cur = cur + timedelta(weeks=1 if course.recurrence_kind=="weekly" else 2)
    await db.commit()
    return {"created": created}
