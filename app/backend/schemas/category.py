from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class CategoryBase(BaseModel):
    name: str = Field(..., max_length=50)
    icon: Optional[str] = Field(None, max_length=100)
    sort_order: int = 0
    is_active: bool = True


class CategoryCreate(CategoryBase):
    pass


class CategoryUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=50)
    icon: Optional[str] = Field(None, max_length=100)
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class CategoryOut(CategoryBase):
    model_config = ConfigDict(from_attributes=True)
    id: int

