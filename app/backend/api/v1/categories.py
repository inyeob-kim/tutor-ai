from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from ...db.database import get_session
from ...db.models import Category
from ...schemas.category import CategoryCreate, CategoryOut, CategoryUpdate

router = APIRouter(prefix="/categories", tags=["categories"])


def _to_out(category: Category) -> CategoryOut:
    return CategoryOut.model_validate(category)


@router.post("", response_model=CategoryOut, status_code=201)
async def create_category(
    payload: CategoryCreate,
    db: AsyncSession = Depends(get_session),
) -> CategoryOut:
    category = Category(**payload.model_dump())
    db.add(category)
    try:
        await db.commit()
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(status_code=400, detail=f"Failed to create category: {exc.orig}") from exc
    await db.refresh(category)
    return _to_out(category)


@router.get("/{category_id}", response_model=CategoryOut)
async def get_category(category_id: int, db: AsyncSession = Depends(get_session)) -> CategoryOut:
    category = await db.get(Category, category_id)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return _to_out(category)


@router.patch("/{category_id}", response_model=CategoryOut)
async def update_category(
    category_id: int,
    payload: CategoryUpdate,
    db: AsyncSession = Depends(get_session),
) -> CategoryOut:
    category = await db.get(Category, category_id)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    data = payload.model_dump(exclude_unset=True)
    if not data:
        return _to_out(category)

    for key, value in data.items():
        setattr(category, key, value)

    try:
        await db.commit()
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(status_code=400, detail=f"Failed to update category: {exc.orig}") from exc
    await db.refresh(category)
    return _to_out(category)


@router.get("/list")
async def list_categories(
    keyword: Optional[str] = Query(None, description="이름 검색"),
    is_active: Optional[bool] = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_session),
):
    stmt = select(Category)
    cnt_stmt = select(func.count()).select_from(Category)

    if keyword:
        like = f"%{keyword}%"
        stmt = stmt.where(Category.name.ilike(like))
        cnt_stmt = cnt_stmt.where(Category.name.ilike(like))
    if is_active is not None:
        stmt = stmt.where(Category.is_active == is_active)
        cnt_stmt = cnt_stmt.where(Category.is_active == is_active)

    stmt = stmt.order_by(Category.sort_order.asc(), Category.name.asc()).offset((page - 1) * size).limit(size)
    rows = (await db.execute(stmt)).scalars().all()
    total = (await db.execute(cnt_stmt)).scalar_one()

    return {
        "total": total,
        "page": page,
        "size": size,
        "items": [_to_out(row) for row in rows],
    }

