from __future__ import annotations
from typing import Optional, Tuple, Dict, Any, List
from datetime import datetime, timezone
from bson import ObjectId
from pymongo.errors import DuplicateKeyError
from motor.motor_asyncio import AsyncIOMotorDatabase
import re

from ..schemas.student import StudentCreate, StudentOut

def normalize_phone_kr(raw: str) -> str:
    s = re.sub(r'\D', '', raw or '')
    if s.startswith('0'):
        s = '82' + s[1:]
    return '+' + s  # 예: +821056789012

def _to_out(doc: dict) -> StudentOut:
    return StudentOut(
        id=str(doc["_id"]),
        name=doc["name"],
        subjects=list(doc.get("subjects", [])),
        tuition=int(doc["tuition"]),
        tuition_unit=doc["tuition_unit"],
        phone=doc["phone"],
        status=doc.get("status", "active"),
        created_at=doc["created_at"],
    )


def _new_student_doc(payload: StudentCreate) -> dict:
    now = datetime.now(timezone.utc)
    phone_norm = normalize_phone_kr(payload.phone)
    return {
        "name": payload.name,
        "subjects": payload.subjects or [],
        "tuition": int(payload.tuition),
        "tuition_unit": payload.tuition_unit,
        "phone": payload.phone,       # 원본 보존
        "phone_norm": phone_norm,     # ✅ 정규화 값
        "status": "active",
        "created_at": now,
        "updated_at": now,
    }


async def create_student(db: AsyncIOMotorDatabase, payload: StudentCreate) -> StudentOut:
    doc = _new_student_doc(payload)
    try:
        res = await db.students.insert_one(doc)
    except DuplicateKeyError:
        raise ValueError("DUPLICATE_PHONE")

    saved = await db.students.find_one({"_id": res.inserted_id})
    return _to_out(saved)


async def get_student_by_phone(db, phone: str):
    phone_norm = normalize_phone_kr(phone)
    doc = await db.students.find_one({"phone_norm": phone_norm})
    return _to_out(doc) if doc else None


async def get_student_by_id(db: AsyncIOMotorDatabase, sid: str) -> Optional[StudentOut]:
    if not ObjectId.is_valid(sid):
        return None
    doc = await db.students.find_one({"_id": ObjectId(sid)})
    if not doc:
        return None
    return _to_out(doc)

# ✅ 목록/검색/정렬/페이지네이션
_SORT_MAP = {
    "created_at": ("created_at", 1),
    "-created_at": ("created_at", -1),
    "name": ("name", 1),
    "-name": ("name", -1),
    "tuition": ("tuition", 1),
    "-tuition": ("tuition", -1),
}

async def list_students(
    db: AsyncIOMotorDatabase,
    *,
    q: Optional[str] = None,               # 키워드(이름/전화)
    status: Optional[str] = None,          # active/inactive
    subject: Optional[str] = None,         # 한 과목으로 필터
    tuition_min: Optional[int] = None,
    tuition_max: Optional[int] = None,
    created_from: Optional[datetime] = None,
    created_to: Optional[datetime] = None,
    sort: str = "-created_at",             # 정렬키 (기본 최신순)
    page: int = 1,
    size: int = 20,
) -> Dict[str, Any]:
    page = max(1, page)
    size = min(max(1, size), 100)

    cond: Dict[str, Any] = {}

    # 상태
    if status in ("active", "inactive"):
        cond["status"] = status

    # 과목
    if subject:
        cond["subjects"] = subject  # 배열에 해당 값 포함

    # 수강료 범위
    if tuition_min is not None or tuition_max is not None:
        rg: Dict[str, Any] = {}
        if tuition_min is not None:
            rg["$gte"] = int(tuition_min)
        if tuition_max is not None:
            rg["$lte"] = int(tuition_max)
        cond["tuition"] = rg

    # 생성일 범위
    if created_from or created_to:
        rg: Dict[str, Any] = {}
        if created_from:
            rg["$gte"] = created_from
        if created_to:
            rg["$lte"] = created_to
        cond["created_at"] = rg

    # 키워드 검색 (이름 부분일치 + 전화)
    if q:
        # 숫자(전화)면 정규화해서 phone_norm 일치 검색 OR 원문 부분검색
        phone_norm = normalize_phone_kr(q) if re.search(r'\d', q) else None
        or_terms: List[Dict[str, Any]] = [
            {"name": {"$regex": re.escape(q), "$options": "i"}}
        ]
        if phone_norm:
            or_terms.append({"phone_norm": phone_norm})
            or_terms.append({"phone": {"$regex": re.escape(q), "$options": "i"}})
        else:
            # 숫자가 전혀 없으면 이름만 검색
            pass
        cond["$or"] = or_terms

    # 정렬
    sort_key, sort_dir = _SORT_MAP.get(sort, ("created_at", -1))
    sort_tuple = [(sort_key, sort_dir)]

    total = await db.students.count_documents(cond)
    cursor = (
        db.students
        .find(cond)
        .sort(sort_tuple)
        .skip((page - 1) * size)
        .limit(size)
    )
    docs = await cursor.to_list(length=size)
    items = [_to_out(d) for d in docs]
    return {"total": total, "page": page, "size": size, "items": items}