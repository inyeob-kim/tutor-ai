from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from ...db.database import get_db
from ...models.student import Student

router = APIRouter(prefix="/students", tags=["students"])

@router.get("/list")
async def list_students(
    q: str | None = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Student)
    if q:
        stmt = stmt.where(Student.name.ilike(f"%{q}%"))
    stmt = stmt.order_by(Student.name).limit(size).offset((page-1)*size)
    rows = (await db.execute(stmt)).scalars().all()
    return {"items": [{
        "id": s.id, "name": s.name, "phone": s.phone, "email": s.email, "created_at": s.created_at
    } for s in rows], "page": page, "size": size}
