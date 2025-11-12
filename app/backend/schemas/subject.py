from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class SubjectBase(BaseModel):
    category_id: int
    code: str = Field(..., max_length=20)
    name: str = Field(..., max_length=50)
    color: str = Field("#3788D8", max_length=7)
    is_active: bool = True


class SubjectCreate(SubjectBase):
    pass


class SubjectUpdate(BaseModel):
    category_id: Optional[int] = None
    code: Optional[str] = Field(None, max_length=20)
    name: Optional[str] = Field(None, max_length=50)
    color: Optional[str] = Field(None, max_length=7)
    is_active: Optional[bool] = None


class SubjectOut(SubjectBase):
    model_config = ConfigDict(from_attributes=True)
    id: int

