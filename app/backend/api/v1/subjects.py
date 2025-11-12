from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from ...db.database import get_session
from ...db.models import Subject
from ...schemas.subject import SubjectCreate, SubjectOut, SubjectUpdate

router = APIRouter(prefix="/subjects", tags=["subjects"])


def _to_out(subject: Subject) -> SubjectOut:
    return SubjectOut.model_validate(subject)


@router.post("", response_model=SubjectOut, status_code=201)
async def create_subject(
    payload: SubjectCreate,
    db: AsyncSession = Depends(get_session),
) -> SubjectOut:
    subject = Subject(**payload.model_dump())
    db.add(subject)
    try:
        await db.commit()
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(status_code=400, detail=f"Failed to create subject: {exc.orig}") from exc
    await db.refresh(subject)
    return _to_out(subject)


@router.get("/{subject_id}", response_model=SubjectOut)
async def get_subject(subject_id: int, db: AsyncSession = Depends(get_session)) -> SubjectOut:
    subject = await db.get(Subject, subject_id)
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")
    return _to_out(subject)


@router.patch("/{subject_id}", response_model=SubjectOut)
async def update_subject(
    subject_id: int,
    payload: SubjectUpdate,
    db: AsyncSession = Depends(get_session),
) -> SubjectOut:
    subject = await db.get(Subject, subject_id)
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")

    data = payload.model_dump(exclude_unset=True)
    if not data:
        return _to_out(subject)

    for key, value in data.items():
        setattr(subject, key, value)

    try:
        await db.commit()
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(status_code=400, detail=f"Failed to update subject: {exc.orig}") from exc
    await db.refresh(subject)
    return _to_out(subject)


@router.get("/list")
async def list_subjects(
    category_id: Optional[int] = Query(None),
    is_active: Optional[bool] = Query(None),
    keyword: Optional[str] = Query(None, description="코드/이름 검색"),
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_session),
):
    stmt = select(Subject)
    cnt_stmt = select(func.count()).select_from(Subject)

    if category_id is not None:
        stmt = stmt.where(Subject.category_id == category_id)
        cnt_stmt = cnt_stmt.where(Subject.category_id == category_id)
    if is_active is not None:
        stmt = stmt.where(Subject.is_active == is_active)
        cnt_stmt = cnt_stmt.where(Subject.is_active == is_active)
    if keyword:
        like = f"%{keyword}%"
        stmt = stmt.where((Subject.name.ilike(like)) | (Subject.code.ilike(like)))
        cnt_stmt = cnt_stmt.where((Subject.name.ilike(like)) | (Subject.code.ilike(like)))

    stmt = stmt.order_by(Subject.name.asc()).offset((page - 1) * size).limit(size)
    rows = (await db.execute(stmt)).scalars().all()
    total = (await db.execute(cnt_stmt)).scalar_one()

    return {
        "total": total,
        "page": page,
        "size": size,
        "items": [_to_out(row) for row in rows],
    }

