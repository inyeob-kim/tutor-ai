# app/backend/routers/student_router.py
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.backend.db.database import get_session
from app.backend.db.models import Student
from app.backend.schemas.student import (
    StudentCreate, StudentOut, StudentListResp, StudentUpdate
)

router = APIRouter(prefix="/students", tags=["students"])

@router.post("", response_model=StudentOut, status_code=201)
async def create_student(payload: StudentCreate, session: AsyncSession = Depends(get_session)):
    data = payload.model_dump(exclude_unset=True)
    # 안전장치: 실제 컬럼만 생성에 사용
    cols = set(Student.__table__.columns.keys())
    safe = {k: v for k, v in data.items() if k in cols}
    student = Student(**safe, user_id=1)  # TODO: 인증 붙으면 실제 사용자 ID
    session.add(student)
    await session.commit()
    await session.refresh(student)
    return student

@router.get("", response_model=StudentListResp)
async def list_students(
    q: str | None = Query(None, description="이름 부분검색"),
    orderBy: str = Query("created_at"),
    order: str = Query("desc"),
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=200),
    session: AsyncSession = Depends(get_session),
):
    ORDERABLE = {
        "created_at": Student.created_at,
        "name": Student.name,
        "grade": Student.grade,
        "email": Student.email,
    }
    order_col = ORDERABLE.get(orderBy, Student.created_at)
    if order.lower() == "desc":
        order_col = order_col.desc()

    base = select(Student)
    cnt = select(func.count()).select_from(Student)

    if q:
        like = f"%{q}%"
        base = base.where(Student.name.ilike(like))
        cnt = cnt.where(Student.name.ilike(like))

    total = (await session.execute(cnt)).scalar_one()
    rows = (await session.execute(
        base.order_by(order_col).offset((page - 1) * pageSize).limit(pageSize)
    )).scalars().all()

    return StudentListResp(total=total, page=page, pageSize=pageSize, items=rows)

@router.get("/{student_id}", response_model=StudentOut)
async def get_student(student_id: int, session: AsyncSession = Depends(get_session)):
    obj = await session.get(Student, student_id)
    if not obj:
        raise HTTPException(404, "Student not found")
    return obj

@router.patch("/{student_id}", response_model=StudentOut)
async def update_student(
    student_id: int,
    payload: StudentUpdate,
    session: AsyncSession = Depends(get_session),
):
    obj = await session.get(Student, student_id)
    if not obj:
        raise HTTPException(404, "Student not found")

    data = payload.model_dump(exclude_unset=True)
    cols = set(Student.__table__.columns.keys())
    for k, v in data.items():
        if k in cols:
            setattr(obj, k, v)

    await session.commit()
    await session.refresh(obj)
    return obj

@router.delete("/{student_id}", status_code=204)
async def delete_student(student_id: int, session: AsyncSession = Depends(get_session)):
    obj = await session.get(Student, student_id)
    if not obj:
        raise HTTPException(404, "Student not found")
    await session.delete(obj)
    await session.commit()
    return None
