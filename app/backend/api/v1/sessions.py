from fastapi import APIRouter, Depends, HTTPException, Query, Path, Body
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone
from ...db.database import get_db
from ...models.session import Session

router = APIRouter(prefix="/sessions", tags=["sessions"])

@router.get("")
async def list_sessions(
    from_: datetime | None = Query(None, alias="from"),
    to_: datetime | None = Query(None, alias="to"),
    student_id: int | None = None,
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Session)
    if from_ and to_:
        stmt = stmt.where(Session.start_at >= from_, Session.start_at < to_)
    if student_id:
        stmt = stmt.where(Session.student_id == student_id)
    stmt = stmt.order_by(Session.start_at)
    rows = (await db.execute(stmt)).scalars().all()
    return [{
        "id": s.id, "course_id": s.course_id, "student_id": s.student_id, "subject": s.subject,
        "start_at": s.start_at, "end_at": s.end_at,
        "location": {"mode": s.location_mode, "place": s.location_place},
        "attendance": {"status": s.attendance_status, "memo": s.attendance_memo, "marked_at": s.attendance_marked_at}
    } for s in rows]

@router.post("/{session_id}:attendance")
async def mark_attendance(
    session_id: int = Path(...),
    body: dict = Body(...),
    db: AsyncSession = Depends(get_db),
):
    s = await db.get(Session, session_id)
    if not s:
        raise HTTPException(404, "session not found")
    s.attendance_status = body.get("status")
    s.attendance_memo = body.get("memo")
    s.attendance_marked_at = datetime.now(timezone.utc)
    await db.commit()
    return {"ok": True}
