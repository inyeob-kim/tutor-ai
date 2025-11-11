from __future__ import annotations

from datetime import time
from pydantic import BaseModel, ConfigDict


class StudentSubjectBase(BaseModel):
    student_id: int
    teacher_id: int
    subject: str
    hourly_rate: int
    lesson_day: str | None = None
    start_time: time | None = None
    end_time: time | None = None


class StudentSubjectCreate(StudentSubjectBase):
    pass


class StudentSubjectUpdate(BaseModel):
    hourly_rate: int | None = None
    lesson_day: str | None = None
    start_time: time | None = None
    end_time: time | None = None


class StudentSubjectOut(StudentSubjectBase):
    model_config = ConfigDict(from_attributes=True)

