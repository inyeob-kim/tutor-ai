# app/backend/routers/student_router.py
from fastapi import APIRouter, Depends, Query, HTTPException
from fastapi.encoders import jsonable_encoder
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.inspection import inspect
from app.backend.db.database import get_session
from app.backend.db.models import Student, StudentHistory
from app.backend.schemas.student import (
    StudentCreate,
    StudentOut,
    StudentListResp,
    StudentUpdate,
)
from app.backend.schemas.student_history import (
    StudentHistoryOut,
    StudentHistoryChangeType,
)

router = APIRouter(prefix="/students", tags=["students"])


def _student_snapshot(student: Student) -> dict:
    """Serialize a Student ORM object to a JSON-friendly dict."""
    mapper = inspect(student)
    raw = {attr.key: getattr(student, attr.key) for attr in mapper.mapper.column_attrs}
    return jsonable_encoder(raw)


def _snapshot_to_out(snapshot: dict) -> StudentOut:
    filtered = {field: snapshot.get(field) for field in StudentOut.model_fields}
    return StudentOut.model_validate(filtered)


def _diff_snapshots(before: dict | None, after: dict | None) -> dict:
    if not before or not after:
        return {}
    diff = {}
    for key in after.keys():
        if before.get(key) != after.get(key):
            diff[key] = {"before": before.get(key), "after": after.get(key)}
    return diff


def _build_history_entry(
    student_id: int,
    change_type: StudentHistoryChangeType,
    *,
    before: dict | None = None,
    after: dict | None = None,
) -> StudentHistory:
    payload: dict = {}
    if before is not None:
        payload["before"] = before
    if after is not None:
        payload["after"] = after
    diff = _diff_snapshots(before, after)
    if diff:
        payload["diff"] = diff
    return StudentHistory(
        student_id=student_id,
        change_type=change_type.value,
        payload=payload or {"note": "no changes"},
    )


@router.post("", response_model=StudentOut, status_code=201)
async def create_student(payload: StudentCreate, session: AsyncSession = Depends(get_session)):
    data = payload.model_dump(exclude_unset=True)
    # 안전장치: 실제 컬럼만 생성에 사용
    cols = set(Student.__table__.columns.keys())
    safe = {k: v for k, v in data.items() if k in cols}
    
    # 해시 필드는 자동 생성되므로 제외
    safe.pop('name_hash', None)
    safe.pop('phone_hash', None)
    
    student = Student(**safe)
    session.add(student)
    try:
        await session.flush()
        await session.refresh(student)
        after_snapshot = _student_snapshot(student)
        session.add(
            _build_history_entry(
                student.student_id,
                StudentHistoryChangeType.CREATE,
                after=after_snapshot,
            )
        )
        await session.commit()
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create student: {str(e)}")
    return _snapshot_to_out(after_snapshot)

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
        "phone": Student.phone,
        "start_date": Student.start_date,
    }
    order_col = ORDERABLE.get(orderBy, Student.created_at)
    if order.lower() == "desc":
        order_col = order_col.desc()

    base = select(Student)
    cnt = select(func.count()).select_from(Student)

    if q:
        # 암호화된 필드는 직접 검색 불가, 해시 필드로 정확 일치 검색
        # 부분 검색은 모든 레코드를 가져와서 복호화 후 필터링 (비효율적)
        # TODO: 검색 인덱스 테이블 또는 별도 검색 엔진 사용 고려
        # 임시로 해시 기반 정확 일치만 지원
        from app.backend.core.crypto import hmac_sha256_hex
        q_hash = hmac_sha256_hex(q)
        base = base.where(Student.name_hash == q_hash)
        cnt = cnt.where(Student.name_hash == q_hash)

    total = (await session.execute(cnt)).scalar_one()
    rows = (
        await session.execute(
            base.order_by(order_col).offset((page - 1) * pageSize).limit(pageSize)
        )
    ).scalars().all()

    items = [_snapshot_to_out(_student_snapshot(s)) for s in rows]
    return StudentListResp(total=total, page=page, pageSize=pageSize, items=items)

@router.get("/{student_id}", response_model=StudentOut)
async def get_student(student_id: int, session: AsyncSession = Depends(get_session)):
    obj = await session.get(Student, student_id)
    if not obj:
        raise HTTPException(404, "Student not found")
    return _snapshot_to_out(_student_snapshot(obj))

@router.patch("/{student_id}", response_model=StudentOut)
async def update_student(
    student_id: int,
    payload: StudentUpdate,
    session: AsyncSession = Depends(get_session),
):
    obj = await session.get(Student, student_id)
    if not obj:
        raise HTTPException(404, "Student not found")

    before_snapshot = _student_snapshot(obj)
    data = payload.model_dump(exclude_unset=True)
    cols = set(Student.__table__.columns.keys())
    for k, v in data.items():
        if k in cols:
            setattr(obj, k, v)

    try:
        await session.flush()
        await session.refresh(obj)
        after_snapshot = _student_snapshot(obj)
        session.add(
            _build_history_entry(
                student_id,
                StudentHistoryChangeType.UPDATE,
                before=before_snapshot,
                after=after_snapshot,
            )
        )
        await session.commit()
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update student: {str(e)}")
    return _snapshot_to_out(after_snapshot)

@router.delete("/{student_id}", status_code=204)
async def delete_student(student_id: int, session: AsyncSession = Depends(get_session)):
    obj = await session.get(Student, student_id)
    if not obj:
        raise HTTPException(404, "Student not found")
    before_snapshot = _student_snapshot(obj)
    try:
        session.add(
            _build_history_entry(
                student_id,
                StudentHistoryChangeType.DELETE,
                before=before_snapshot,
            )
        )
        await session.delete(obj)
        await session.commit()
    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete student: {str(e)}")
    return None


@router.get("/{student_id}/history", response_model=list[StudentHistoryOut])
async def list_student_history(
    student_id: int,
    session: AsyncSession = Depends(get_session),
):
    student_exists = await session.scalar(select(func.count()).select_from(Student).where(Student.student_id == student_id))
    if not student_exists:
        raise HTTPException(status_code=404, detail="Student not found")

    stmt = (
        select(StudentHistory)
        .where(StudentHistory.student_id == student_id)
        .order_by(StudentHistory.changed_at.desc(), StudentHistory.history_id.desc())
    )
    rows = (await session.execute(stmt)).scalars().all()
    return rows
