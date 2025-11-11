from __future__ import annotations

from datetime import datetime, date
from typing import Optional, Literal

from pydantic import BaseModel, ConfigDict

TaxType = Literal["사업소득", "기타소득", "프리랜서", "미신고"]
Provider = Literal["google", "kakao", "naver", "apple"]


class TeacherBase(BaseModel):
    name: str
    phone: str
    provider: Provider
    oauth_id: str
    email: Optional[str] = None
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    tax_type: TaxType = "사업소득"
    hourly_rate_min: Optional[int] = None
    hourly_rate_max: Optional[int] = None
    available_days: Optional[str] = None
    available_time: Optional[str] = None
    vacation_start: Optional[date] = None
    vacation_end: Optional[date] = None
    total_students: Optional[int] = None
    monthly_income: Optional[int] = None
    notes: Optional[str] = None


class TeacherCreate(TeacherBase):
    pass


class TeacherUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    provider: Optional[Provider] = None
    oauth_id: Optional[str] = None
    email: Optional[str] = None
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    tax_type: Optional[TaxType] = None
    hourly_rate_min: Optional[int] = None
    hourly_rate_max: Optional[int] = None
    available_days: Optional[str] = None
    available_time: Optional[str] = None
    vacation_start: Optional[date] = None
    vacation_end: Optional[date] = None
    total_students: Optional[int] = None
    monthly_income: Optional[int] = None
    notes: Optional[str] = None


class TeacherOut(TeacherBase):
    model_config = ConfigDict(from_attributes=True)
    teacher_id: int
    created_at: datetime
    updated_at: datetime


class TeacherListResp(BaseModel):
    total: int
    page: int
    pageSize: int
    items: list[TeacherOut]
