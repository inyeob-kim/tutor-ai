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


def _extract_teacher_id(before: dict | None, after: dict | None) -> int | None:
    if after is not None and after.get("teacher_id") is not None:
        return after.get("teacher_id")
    if before is not None and before.get("teacher_id") is not None:
        return before.get("teacher_id")
    return None


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
        teacher_id=_extract_teacher_id(before, after),
        change_type=change_type.value,
        payload=payload or {"note": "no changes"},
    )


@router.post("", response_model=StudentOut, status_code=201)
async def create_student(payload: StudentCreate, session: AsyncSession = Depends(get_session)):
    # 디버깅: 받은 데이터 확인
    print(f"📥 백엔드: 학생 생성 요청 받음")
    print(f"  - payload.teacher_id: {payload.teacher_id}")
    print(f"  - payload.name: {payload.name}")
    print(f"  - payload.phone: {payload.phone}")
    print(f"  - payload.subject_id: {payload.subject_id}")
    
    data = payload.model_dump(exclude_unset=True)
    print(f"  - data (model_dump 후): {data}")
    print(f"  - data.get('teacher_id'): {data.get('teacher_id')}")
    
    # 안전장치: 실제 컬럼만 생성에 사용
    cols = set(Student.__table__.columns.keys())
    safe = {k: v for k, v in data.items() if k in cols}
    print(f"  - safe (컬럼 필터링 후): {safe}")
    print(f"  - safe.get('teacher_id'): {safe.get('teacher_id')}")
    
    # 해시 필드는 자동 생성되므로 제외
    safe.pop('name_hash', None)
    safe.pop('phone_hash', None)
    
    # teacher_id가 None이면 경고 (디버깅용)
    if safe.get('teacher_id') is None:
        print(f"⚠️ 경고: teacher_id가 None입니다!")
    
    student = Student(**safe)
    session.add(student)
    try:
        await session.flush()
        await session.refresh(student)
        print(f"✅ 학생 생성 성공: student_id={student.student_id}, teacher_id={student.teacher_id}")
        after_snapshot = _student_snapshot(student)
        print(f"  - after_snapshot.teacher_id: {after_snapshot.get('teacher_id')}")
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
        print(f"❌ 학생 생성 실패: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create student: {str(e)}")
    return _snapshot_to_out(after_snapshot)

@router.get("", response_model=StudentListResp)
async def list_students(
    q: str | None = Query(None, description="이름 부분검색"),
    teacher_id: int | None = Query(None, description="담당 교사 ID"),
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

    if teacher_id is not None:
        base = base.where(Student.teacher_id == teacher_id)
        cnt = cnt.where(Student.teacher_id == teacher_id)

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
