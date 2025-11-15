from __future__ import annotations

from datetime import datetime, date
from typing import Optional, Literal

from pydantic import BaseModel, ConfigDict, field_validator

TaxType = Literal["사업소득", "기타소득", "프리랜서", "미신고"]
Provider = Literal["google", "kakao", "naver", "apple"]


class TeacherBase(BaseModel):
    nickname: str
    phone: str
    provider: Provider
    oauth_id: str
    subject_id: Optional[str] = None
    email: Optional[str] = None
    account_name: Optional[str] = None
    bank_code: Optional[str] = None
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
    # 수업 시간 설정 (타임슬롯 제한용)
    lesson_start_hour: Optional[int] = None
    lesson_end_hour: Optional[int] = None
    exclude_weekends: Optional[bool] = None

    @field_validator("tax_type", mode="before")
    @classmethod
    def _empty_tax_type_to_none(cls, value: Optional[str]):
        if value == "" or value is None:
            return None
        return value

    @field_validator("bank_code", mode="before")
    @classmethod
    def _normalize_bank_code(cls, value: Optional[str]):
        if value is None or value == "":
            return None
        value = value.strip().upper()
        if len(value) != 3:
            raise ValueError("bank_code must be a 3-character code")
        return value


class TeacherCreate(TeacherBase):
    pass


class TeacherUpdate(BaseModel):
    nickname: Optional[str] = None
    phone: Optional[str] = None
    subject_id: Optional[str] = None
    email: Optional[str] = None
    account_name: Optional[str] = None
    bank_code: Optional[str] = None
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
    # 수업 시간 설정 (타임슬롯 제한용)
    lesson_start_hour: Optional[int] = None
    lesson_end_hour: Optional[int] = None
    exclude_weekends: Optional[bool] = None

    @field_validator("bank_code", mode="before")
    @classmethod
    def _normalize_bank_code(cls, value: Optional[str]):
        if value is None or value == "":
            return None
        value = value.strip().upper()
        if len(value) != 3:
            raise ValueError("bank_code must be a 3-character code")
        return value


class TeacherOut(TeacherBase):
    model_config = ConfigDict(from_attributes=True)
    teacher_id: int
    tax_type: Optional[TaxType] = None
    created_at: datetime
    updated_at: datetime


class TeacherListResp(BaseModel):
    total: int
    page: int
    pageSize: int
    items: list[TeacherOut]
