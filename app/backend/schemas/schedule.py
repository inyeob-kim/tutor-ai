from __future__ import annotations

from datetime import datetime, date, time
from typing import Optional, Literal

from pydantic import BaseModel, ConfigDict

ScheduleType = Literal["lesson", "available", "vacation", "personal"]


class ScheduleBase(BaseModel):
    teacher_id: int
    lesson_date: date
    start_time: time
    end_time: time
    student_id: Optional[int] = None
    schedule_type: ScheduleType
    title: Optional[str] = None
    notes: Optional[str] = None
    color: Optional[str] = "#3788D8"


class ScheduleCreate(ScheduleBase):
    pass


class ScheduleUpdate(BaseModel):
    teacher_id: Optional[int] = None
    lesson_date: Optional[date] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    student_id: Optional[int] = None
    schedule_type: Optional[ScheduleType] = None
    title: Optional[str] = None
    notes: Optional[str] = None
    color: Optional[str] = None


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
