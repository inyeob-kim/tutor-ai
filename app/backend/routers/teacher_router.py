from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.encoders import jsonable_encoder
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.inspection import inspect

from app.backend.db.database import get_session
from app.backend.db.models import Teacher, TeacherHistory
from app.backend.schemas.teacher import (
    TeacherCreate,
    TeacherOut,
    TeacherListResp,
    TeacherUpdate,
)
from app.backend.schemas.teacher_history import (
    TeacherHistoryOut,
    TeacherHistoryChangeType,
)

router = APIRouter(prefix="/teachers", tags=["teachers"])


def _teacher_snapshot(teacher: Teacher) -> dict:
    mapper = inspect(teacher)
    raw = {attr.key: getattr(teacher, attr.key) for attr in mapper.mapper.column_attrs}
    return jsonable_encoder(raw)


def _snapshot_to_out(snapshot: dict) -> TeacherOut:
    filtered = {
        field: value
        for field, value in ((field, snapshot.get(field)) for field in TeacherOut.model_fields)
        if value is not None
    }
    return TeacherOut.model_validate(filtered)


def _diff_snapshots(before: dict | None, after: dict | None) -> dict:
    if not before or not after:
        return {}
    diff: dict = {}
    for key in after.keys():
        if before.get(key) != after.get(key):
            diff[key] = {"before": before.get(key), "after": after.get(key)}
    return diff


def _build_history_entry(
    teacher_id: int,
    change_type: TeacherHistoryChangeType,
    *,
    before: dict | None = None,
    after: dict | None = None,
) -> TeacherHistory:
    payload: dict = {}
    if before is not None:
        payload["before"] = before
    if after is not None:
        payload["after"] = after
    diff = _diff_snapshots(before, after)
    if diff:
        payload["diff"] = diff
    return TeacherHistory(
        teacher_id=teacher_id,
        change_type=change_type.value,
        payload=payload or {"note": "no changes"},
    )


@router.post("", response_model=TeacherOut, status_code=201)
async def create_teacher(payload: TeacherCreate, session: AsyncSession = Depends(get_session)):
    data = payload.model_dump(exclude_unset=True)
    cols = set(Teacher.__table__.columns.keys())
    safe = {k: v for k, v in data.items() if k in cols}
    nickname = safe.get("nickname")
    if nickname:
        exists = await session.scalar(
            select(func.count()).select_from(Teacher).where(Teacher.nickname == nickname)
        )
        if exists:
            raise HTTPException(status_code=409, detail="Nickname already in use")
    teacher = Teacher(**safe)
    session.add(teacher)
    try:
        await session.flush()
        await session.refresh(teacher)
        after_snapshot = _teacher_snapshot(teacher)
        session.add(
            _build_history_entry(
                teacher.teacher_id,
                TeacherHistoryChangeType.CREATE,
                after=after_snapshot,
            )
        )
        await session.commit()
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create teacher: {str(e)}")
    return _snapshot_to_out(after_snapshot)


@router.get("", response_model=TeacherListResp)
async def list_teachers(
    q: str | None = Query(None, description="이름 또는 전화번호 검색"),
    subject_id: str | None = Query(None, description="담당 과목 ID"),
    orderBy: str = Query("created_at"),
    order: str = Query("desc"),
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=200),
    session: AsyncSession = Depends(get_session),
):
    orderable = {
        "created_at": Teacher.created_at,
        "nickname": Teacher.nickname,
        "name": Teacher.nickname,  # backward compatibility alias
        "total_students": Teacher.total_students,
        "monthly_income": Teacher.monthly_income,
    }
    order_col = orderable.get(orderBy, Teacher.created_at)
    if order.lower() == "desc":
        order_col = order_col.desc()

    stmt = select(Teacher)
    count_stmt = select(func.count()).select_from(Teacher)

    if q:
        like = f"%{q}%"
        stmt = stmt.where((Teacher.nickname.ilike(like)) | (Teacher.phone.ilike(like)))
        count_stmt = count_stmt.where((Teacher.nickname.ilike(like)) | (Teacher.phone.ilike(like)))
    if subject_id is not None:
        stmt = stmt.where(Teacher.subject_id == subject_id)
        count_stmt = count_stmt.where(Teacher.subject_id == subject_id)

    total = (await session.execute(count_stmt)).scalar_one()
    rows = (
        await session.execute(
            stmt.order_by(order_col).offset((page - 1) * pageSize).limit(pageSize)
        )
    ).scalars().all()

    items = [_snapshot_to_out(_teacher_snapshot(row)) for row in rows]
    return TeacherListResp(total=total, page=page, pageSize=pageSize, items=items)


@router.get("/by-oauth", response_model=TeacherOut)
async def get_teacher_by_oauth(
    provider: str = Query(..., description="OAuth provider (google, kakao, naver, apple)"),
    oauth_id: str = Query(..., description="OAuth ID (Firebase UID)"),
    session: AsyncSession = Depends(get_session),
):
    """OAuth provider와 oauth_id로 teacher 조회"""
    stmt = select(Teacher).where(
        Teacher.provider == provider,
        Teacher.oauth_id == oauth_id,
    )
    result = await session.execute(stmt)
    teacher = result.scalar_one_or_none()
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return _snapshot_to_out(_teacher_snapshot(teacher))


@router.get("/{teacher_id}", response_model=TeacherOut)
async def get_teacher(teacher_id: int, session: AsyncSession = Depends(get_session)):
    teacher = await session.get(Teacher, teacher_id)
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return _snapshot_to_out(_teacher_snapshot(teacher))


@router.patch("/{teacher_id}", response_model=TeacherOut)
async def update_teacher(
    teacher_id: int,
    payload: TeacherUpdate,
    session: AsyncSession = Depends(get_session),
):
    teacher = await session.get(Teacher, teacher_id)
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")

    before_snapshot = _teacher_snapshot(teacher)
    data = payload.model_dump(exclude_unset=True)
    allowed_fields = {
        "nickname",
        "phone",
        "email",
        "subject_id",
        "account_name",
        "bank_code",
        "account_number",
        "tax_type",
        "hourly_rate_min",
        "hourly_rate_max",
        "available_days",
        "available_time",
        "vacation_start",
        "vacation_end",
        "total_students",
        "monthly_income",
        "notes",
        "lesson_start_hour",
        "lesson_end_hour",
        "exclude_weekends",
    }

    disallowed = [field for field in data.keys() if field not in allowed_fields]
    if disallowed:
        raise HTTPException(
            status_code=400,
            detail=f"Fields cannot be updated: {', '.join(disallowed)}",
        )

    if "nickname" in data:
        new_nickname = data["nickname"]
        if new_nickname != teacher.nickname:
            exists = await session.scalar(
                select(func.count())
                .select_from(Teacher)
                .where(Teacher.nickname == new_nickname, Teacher.teacher_id != teacher_id)
            )
            if exists:
                raise HTTPException(status_code=409, detail="Nickname already in use")

    for key, value in data.items():
        setattr(teacher, key, value)

    try:
        await session.flush()
        await session.refresh(teacher)
        after_snapshot = _teacher_snapshot(teacher)
        session.add(
            _build_history_entry(
                teacher_id,
                TeacherHistoryChangeType.UPDATE,
                before=before_snapshot,
                after=after_snapshot,
            )
        )
        await session.commit()
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update teacher: {str(e)}")
    return _snapshot_to_out(after_snapshot)


@router.delete("/{teacher_id}", status_code=204)
async def delete_teacher(teacher_id: int, session: AsyncSession = Depends(get_session)):
    teacher = await session.get(Teacher, teacher_id)
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    before_snapshot = _teacher_snapshot(teacher)
    try:
        session.add(
            _build_history_entry(
                teacher_id,
                TeacherHistoryChangeType.DELETE,
                before=before_snapshot,
            )
        )
        await session.delete(teacher)
        await session.commit()
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete teacher: {str(e)}")
    return None


@router.get("/{teacher_id}/history", response_model=list[TeacherHistoryOut])
async def list_teacher_history(
    teacher_id: int,
    session: AsyncSession = Depends(get_session),
):
    teacher_exists = await session.scalar(
        select(func.count()).select_from(Teacher).where(Teacher.teacher_id == teacher_id)
    )
    if not teacher_exists:
        raise HTTPException(status_code=404, detail="Teacher not found")

    stmt = (
        select(TeacherHistory)
        .where(TeacherHistory.teacher_id == teacher_id)
        .order_by(TeacherHistory.changed_at.desc(), TeacherHistory.history_id.desc())
    )
    rows = (await session.execute(stmt)).scalars().all()
    return rows
