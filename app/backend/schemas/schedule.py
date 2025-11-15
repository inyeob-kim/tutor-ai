from __future__ import annotations

from datetime import datetime, date
from typing import Optional, Literal

from pydantic import BaseModel, ConfigDict, Field

ScheduleStatus = Literal["confirmed", "cancelled", "completed", "no_show"]
AttendanceStatus = Literal["present", "late", "absent"]


class ScheduleBase(BaseModel):
    teacher_id: int
    student_id: int
    lesson_date: date
    start_time: str = Field(..., pattern=r"^\d{2}:\d{2}$")
    end_time: str = Field(..., pattern=r"^\d{2}:\d{2}$")
    subject_id: str
    notes: Optional[str] = None
    status: ScheduleStatus = "confirmed"
    attendance_status: Optional[AttendanceStatus] = None
    cancelled_at: Optional[datetime] = None
    cancelled_by: Optional[int] = None
    cancel_reason: Optional[str] = None


class ScheduleCreate(ScheduleBase):
    pass


class ScheduleUpdate(BaseModel):
    lesson_date: Optional[date] = None
    start_time: Optional[str] = Field(None, pattern=r"^\d{2}:\d{2}$")
    end_time: Optional[str] = Field(None, pattern=r"^\d{2}:\d{2}$")
    subject_id: Optional[str] = None
    notes: Optional[str] = None
    status: Optional[ScheduleStatus] = None
    attendance_status: Optional[AttendanceStatus] = None
    cancelled_at: Optional[datetime] = None
    cancelled_by: Optional[int] = None
    cancel_reason: Optional[str] = None


class ScheduleOut(ScheduleBase):
    model_config = ConfigDict(from_attributes=True)
    schedule_id: int
    created_at: datetime
    updated_at: datetime


class ScheduleListResp(BaseModel):
    total: int
    page: int
    pageSize: int
    items: list[ScheduleOut]
