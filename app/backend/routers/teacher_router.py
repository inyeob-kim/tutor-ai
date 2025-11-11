from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.backend.db.database import get_session
from app.backend.db.models import Teacher
from app.backend.schemas.teacher import (
    TeacherCreate,
    TeacherOut,
    TeacherListResp,
    TeacherUpdate,
)

router = APIRouter(prefix="/teachers", tags=["teachers"])


@router.post("", response_model=TeacherOut, status_code=201)
async def create_teacher(payload: TeacherCreate, session: AsyncSession = Depends(get_session)):
    data = payload.model_dump(exclude_unset=True)
    cols = set(Teacher.__table__.columns.keys())
    safe = {k: v for k, v in data.items() if k in cols}
    teacher = Teacher(**safe)
    session.add(teacher)
    await session.commit()
    await session.refresh(teacher)
    return teacher


@router.get("", response_model=TeacherListResp)
async def list_teachers(
    q: str | None = Query(None, description="이름 또는 전화번호 검색"),
    orderBy: str = Query("created_at"),
    order: str = Query("desc"),
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=200),
    session: AsyncSession = Depends(get_session),
):
    orderable = {
        "created_at": Teacher.created_at,
        "name": Teacher.name,
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
        stmt = stmt.where((Teacher.name.ilike(like)) | (Teacher.phone.ilike(like)))
        count_stmt = count_stmt.where((Teacher.name.ilike(like)) | (Teacher.phone.ilike(like)))

    total = (await session.execute(count_stmt)).scalar_one()
    rows = (
        await session.execute(
            stmt.order_by(order_col).offset((page - 1) * pageSize).limit(pageSize)
        )
    ).scalars().all()

    return TeacherListResp(total=total, page=page, pageSize=pageSize, items=rows)


@router.get("/{teacher_id}", response_model=TeacherOut)
async def get_teacher(teacher_id: int, session: AsyncSession = Depends(get_session)):
    teacher = await session.get(Teacher, teacher_id)
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return teacher


@router.patch("/{teacher_id}", response_model=TeacherOut)
async def update_teacher(
    teacher_id: int,
    payload: TeacherUpdate,
    session: AsyncSession = Depends(get_session),
):
    teacher = await session.get(Teacher, teacher_id)
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")

    data = payload.model_dump(exclude_unset=True)
    cols = set(Teacher.__table__.columns.keys())
    for key, value in data.items():
        if key in cols:
            setattr(teacher, key, value)

    await session.commit()
    await session.refresh(teacher)
    return teacher


@router.delete("/{teacher_id}", status_code=204)
async def delete_teacher(teacher_id: int, session: AsyncSession = Depends(get_session)):
    teacher = await session.get(Teacher, teacher_id)
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")

    await session.delete(teacher)
    await session.commit()
    return None
